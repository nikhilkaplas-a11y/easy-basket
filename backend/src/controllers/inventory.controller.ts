import { Response } from 'express';

import { AppDataSource } from '../config/database';
import { AuthRequest } from '../middleware/auth.middleware';
import { InventoryAdjustment } from '../entities/InventoryAdjustment';
import { InventoryBatch } from '../entities/InventoryBatch';
import { Product } from '../entities/Product';
import { ProductVariant } from '../entities/ProductVariant';
import { InventorySheetService, PlannedRow } from '../services/inventory-sheet.service';
import { ProductController } from './product.controller';
import { UTF8_BOM, toCsv } from '../utils/csv.util';

/**
 * Bulk inventory editing via spreadsheet.
 *
 * The admin panel updates one product per request, which does not scale past a
 * handful of edits. This lets the owner download the whole catalogue, edit it in
 * Excel on a laptop, and upload it back.
 *
 * ---------------------------------------------------------------------------
 * Sheet shape: ONE ROW PER SELLABLE UNIT, plus a parent row per product
 * ---------------------------------------------------------------------------
 * Stock and price live in two different places in this schema. A product with
 * no variants sells from `product.stock` / `product.price`; a product WITH
 * variants sells from each `product_variant.stock` / `.price`, and its own
 * product-level stock is never consulted by order creation.
 *
 * So the sheet emits:
 *
 *   row_type=product, no variants  -> stock, price and available all editable
 *   row_type=product, has variants -> ONLY available editable; stock and price
 *                                     are blank, because nothing sells at that
 *                                     level and showing a number there would
 *                                     invite someone to edit a value that has
 *                                     no effect
 *   row_type=size                  -> stock, price and available all editable
 *
 * The parent row still matters for a variant product: `product.isAvailable`
 * hides the whole product, which turning off every size individually does not
 * quite achieve.
 *
 * ---------------------------------------------------------------------------
 * The `was_*` columns
 * ---------------------------------------------------------------------------
 * Every editable column has a `was_*` twin recording what the system held at
 * download time. They exist for two different reasons:
 *
 *   was_stock  — REQUIRED for correctness. Customers buy while the sheet is
 *                open, so stock must be applied as a DIFFERENCE
 *                (new − was), never as an absolute. Download says 50, eight are
 *                sold, the owner types 60 meaning "+10": the correct result is
 *                52, not 60. Writing 60 would silently erase eight real sales
 *                and oversell.
 *
 *   was_price
 *   was_available — used to detect a value that changed in the system AFTER the
 *                download. Without them, a sheet edited on Wednesday from a
 *                Monday download silently reverts anything changed in between.
 *                Those rows get flagged in the preview rather than applied.
 *
 * They are marked do-not-edit. A tampered `was_stock` produces a wrong delta,
 * so the preview also sanity-checks the resulting value before anything is
 * written.
 */
export class InventoryController {
  /**
   * GET /api/admin/inventory/export
   *
   * Streams the whole catalogue as CSV. Deliberately includes UNAVAILABLE
   * products — they are exactly what the owner needs in order to switch
   * something back on.
   */
  static async exportSheet(_req: AuthRequest, res: Response): Promise<void> {
    try {
      const products = await AppDataSource.getRepository(Product).find({
        relations: ['category', 'variants'],
        order: { name: 'ASC' },
      });

      const rows: unknown[][] = [
        [
          'row_type',
          'product_id',
          'variant_id',
          'product_name',
          'size',
          'category',
          // --- edit these ---
          'stock',
          'price',
          'available',
          // --- do not edit: the system's values at download time ---
          'was_stock',
          'was_price',
          'was_available',
        ],
      ];

      for (const product of products) {
        const variants = (product.variants ?? []).slice().sort((a, b) => {
          if (a.displayOrder !== b.displayOrder) return a.displayOrder - b.displayOrder;
          return Number(a.quantity) - Number(b.quantity);
        });

        const sellsAtProductLevel = variants.length === 0;
        const productAvailable = product.isAvailable ? 'YES' : 'NO';

        // Parent row. For a variant product this carries availability only.
        const productStock = sellsAtProductLevel ? product.stock : '';
        const productPrice = sellsAtProductLevel ? formatMoney(product.price) : '';

        rows.push([
          'product',
          product.id,
          '',
          product.name,
          '',
          product.category?.name ?? '',
          productStock,
          productPrice,
          productAvailable,
          productStock,
          productPrice,
          productAvailable,
        ]);

        for (const variant of variants) {
          const variantAvailable = variant.isAvailable ? 'YES' : 'NO';
          const variantPrice = formatMoney(variant.price);

          rows.push([
            'size',
            product.id,
            variant.id,
            product.name,
            variant.label,
            product.category?.name ?? '',
            variant.stock,
            variantPrice,
            variantAvailable,
            variant.stock,
            variantPrice,
            variantAvailable,
          ]);
        }
      }

      const filename = `easybasket-inventory-${new Date().toISOString().slice(0, 10)}.csv`;

      // UTF8_BOM is not decoration. Excel writes UTF-8 with a byte-order mark
      // and refuses to read it back without one — Devanagari and Gurmukhi
      // product names arrive as mojibake otherwise. csv.util strips it on read
      // and expects it on write.
      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      res.send(UTF8_BOM + toCsv(rows));
    } catch (error) {
      console.error('[inventory] exportSheet error', error);
      res.status(500).json({ message: 'Could not generate the inventory sheet' });
    }
  }

  /**
   * POST /api/admin/inventory/preview
   *
   * Reads the uploaded sheet and reports what WOULD change. Writes nothing.
   *
   * This step is the safety net. A single bad paste in Excel — a sorted column,
   * a find-and-replace gone wide — could otherwise rewrite the whole catalogue
   * in one request with no way to see it coming.
   */
  static async previewSheet(req: AuthRequest, res: Response): Promise<void> {
    try {
      const csvText = readUploadedCsv(req);
      if (csvText === null) {
        res.status(400).json({ message: 'No file received. Upload the CSV you edited.' });
        return;
      }

      const plan = await InventorySheetService.plan(csvText);
      res.json(summarise(plan));
    } catch (error) {
      // A structurally unusable file (wrong header, empty) throws; bad DATA does
      // not — it comes back as per-row problems so the admin sees everything at
      // once instead of one error per upload.
      const message =
        error instanceof Error ? error.message : 'Could not read that file.';
      console.warn('[inventory] previewSheet rejected a file:', message);
      res.status(400).json({ message });
    }
  }

  /**
   * POST /api/admin/inventory/apply
   *
   * Applies the sheet. Re-runs the same planner against FRESH data rather than
   * trusting anything the preview computed — the preview may be minutes old, and
   * stock in particular will have moved.
   *
   * Everything lands in one transaction: either the whole sheet applies or none
   * of it does. Safe at a few hundred products. Near 10,000 this wants splitting
   * into chunks, because the row locks it holds are the same ones order creation
   * needs — that is what the batch record exists to make easy later.
   */
  static async applySheet(req: AuthRequest, res: Response): Promise<void> {
    const actorUserId = req.user?.id;
    if (!actorUserId) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    let plan;
    try {
      const csvText = readUploadedCsv(req);
      if (csvText === null) {
        res.status(400).json({ message: 'No file received. Upload the CSV you edited.' });
        return;
      }
      plan = await InventorySheetService.plan(csvText);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Could not read that file.';
      res.status(400).json({ message });
      return;
    }

    // Rows with errors are skipped, not fatal — one bad row should not block 300
    // good ones. The admin already saw them in the preview.
    if (plan.rows.length === 0) {
      res.json({
        applied: false,
        message:
          plan.errorCount > 0
            ? 'Nothing was applied — every row had a problem.'
            : 'Nothing to apply — no values changed.',
        ...summarise(plan),
      });
      return;
    }

    try {
      const batchId = await AppDataSource.transaction(async (manager) => {
        const batch = await manager.getRepository(InventoryBatch).save(
          manager.getRepository(InventoryBatch).create({
            actorUserId,
            source: 'csv',
            status: 'applied',
            rowCount: plan.totalRows,
            changedCount: plan.rows.reduce((n, r) => n + r.changes.length, 0),
            errorCount: plan.errorCount,
            note: null,
          })
        );

        const adjustments: InventoryAdjustment[] = [];

        for (const row of plan.rows) {
          await applyRow(manager, row, batch.id, adjustments);
        }

        if (adjustments.length > 0) {
          await manager.getRepository(InventoryAdjustment).save(adjustments);
        }

        return batch.id;
      });

      // Once per upload, not per row. These are genuine catalogue writes, so the
      // cached product lists really are stale now.
      await ProductController.invalidateProductListCache();

      res.json({
        applied: true,
        batchId,
        message: 'Sheet applied.',
        ...summarise(plan),
      });
    } catch (error) {
      console.error('[inventory] applySheet failed', error);
      // The transaction rolled back, so nothing changed. Record the attempt.
      await AppDataSource.getRepository(InventoryBatch)
        .save(
          AppDataSource.getRepository(InventoryBatch).create({
            actorUserId,
            source: 'csv',
            status: 'failed',
            rowCount: plan.totalRows,
            changedCount: 0,
            errorCount: plan.errorCount,
            note: (error instanceof Error ? error.message : String(error)).slice(0, 500),
          })
        )
        .catch(() => undefined);

      res.status(500).json({
        message: 'Could not apply the sheet. Nothing was changed — please try again.',
      });
    }
  }
}

/**
 * Accepts the CSV either as a multipart file (what a browser file input sends)
 * or as a raw text body — the same two shapes the missing-translations bulk
 * endpoint already handles.
 */
function readUploadedCsv(req: AuthRequest): string | null {
  if (req.file?.buffer) return req.file.buffer.toString('utf8');
  if (typeof req.body === 'string' && req.body.trim() !== '') return req.body;
  return null;
}

/** Shape the planner's output for the admin screen. */
function summarise(plan: Awaited<ReturnType<typeof InventorySheetService.plan>>) {
  const counts = { stock: 0, price: 0, available: 0 };
  for (const row of plan.rows) {
    for (const change of row.changes) counts[change.field]++;
  }

  return {
    totalRows: plan.totalRows,
    unchangedRows: plan.unchangedRows,
    changedRows: plan.rows.length,
    changes: counts,
    errorCount: plan.errorCount,
    // Capped: a 10,000-row sheet with a systematic mistake would otherwise try
    // to return 10,000 problems and a matching preview list.
    problems: plan.problems.slice(0, 200),
    problemsTruncated: plan.problems.length > 200,
    preview: plan.rows.slice(0, 200).map((row) => ({
      lineNumber: row.lineNumber,
      label: row.label,
      changes: row.changes.map((c) => ({
        field: c.field,
        from: c.before,
        to: c.after,
      })),
    })),
    previewTruncated: plan.rows.length > 200,
  };
}

/**
 * Write one row's changes.
 *
 * Stock uses a conditional increment rather than a plain SET — the same shape
 * order creation uses. Between planning and writing, a customer may have bought
 * the last unit; `stock + delta >= 0` makes the database refuse rather than let
 * stock go negative.
 */
async function applyRow(
  manager: import('typeorm').EntityManager,
  row: PlannedRow,
  batchId: number,
  adjustments: InventoryAdjustment[]
): Promise<void> {
  const target = row.variantId ? ProductVariant : Product;
  const targetId = row.variantId ?? row.productId;
  const repo = manager.getRepository(target as typeof Product);

  for (const change of row.changes) {
    if (change.field === 'stock') {
      const delta = change.delta ?? 0;
      const result = await manager
        .createQueryBuilder()
        .update(target)
        .set({ stock: () => `stock + (${delta})` })
        .where('id = :id AND stock + (:delta) >= 0', { id: targetId, delta })
        .execute();

      if (result.affected !== 1) {
        throw new Error(
          `Stock for "${row.label}" changed while the sheet was being applied. Nothing was saved — please re-download and try again.`
        );
      }
    } else if (change.field === 'price') {
      await repo.update({ id: targetId }, { price: Number(change.after) } as never);
    } else {
      await repo.update({ id: targetId }, { isAvailable: change.after === 'YES' } as never);
    }

    adjustments.push(
      manager.getRepository(InventoryAdjustment).create({
        batchId,
        productId: row.productId,
        variantId: row.variantId,
        field: change.field,
        beforeValue: change.before,
        afterValue: change.after,
      })
    );
  }
}

/**
 * MySQL returns DECIMAL columns as strings through the driver, so a price may
 * arrive as either. Fixed to two places so Excel does not render 58 as 58.00000
 * or, worse, reformat it as a date.
 */
function formatMoney(value: number | string): string {
  const n = typeof value === 'string' ? parseFloat(value) : value;
  return Number.isFinite(n) ? n.toFixed(2) : '';
}
