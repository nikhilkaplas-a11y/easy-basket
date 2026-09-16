import { In } from 'typeorm';

import { AppDataSource } from '../config/database';
import { Product } from '../entities/Product';
import { ProductVariant } from '../entities/ProductVariant';
import { parseCsv } from '../utils/csv.util';

/**
 * Reads an uploaded inventory sheet and works out what it would change.
 *
 * Deliberately shared by BOTH the preview and the apply endpoints, and it writes
 * nothing itself. If preview and apply each had their own parsing, they would
 * eventually disagree — and the one place that must never happen is between
 * "here is what will change" and what actually changes. Apply re-runs this
 * against fresh data rather than trusting anything the preview computed.
 */

export const SHEET_COLUMNS = [
  'row_type',
  'product_id',
  'variant_id',
  'product_name',
  'size',
  'category',
  'stock',
  'price',
  'available',
  'was_stock',
  'was_price',
  'was_available',
] as const;

/** A single field this row wants to change. */
export interface PlannedChange {
  field: 'stock' | 'price' | 'available';
  before: string;
  after: string;
  /** Stock only: how much to add (may be negative). See the delta note below. */
  delta?: number;
}

export interface PlannedRow {
  /** 1-based row number as it appears in Excel, header included. */
  lineNumber: number;
  productId: number;
  variantId: number | null;
  label: string;
  changes: PlannedChange[];
}

export interface RowProblem {
  lineNumber: number;
  label: string;
  message: string;
  /** Warnings are applied anyway; errors are skipped. */
  severity: 'error' | 'warning';
}

export interface SheetPlan {
  totalRows: number;
  unchangedRows: number;
  rows: PlannedRow[];
  problems: RowProblem[];
  /** Problems with severity 'error' — those rows are skipped, not applied. */
  errorCount: number;
}

/** Stock changes beyond this are almost certainly a typo, not a delivery. */
const IMPLAUSIBLE_STOCK_DELTA = 5000;

/** Sanity ceiling on price, to catch a misplaced decimal or a stray digit. */
const MAX_PRICE = 1_000_000;

export class InventorySheetService {
  /**
   * Parse the uploaded CSV and diff it against current database state.
   *
   * Never throws for bad DATA — everything wrong with a row becomes a problem
   * entry so the admin sees all of it at once instead of fixing one error per
   * upload. Only a structurally unusable file (bad header) throws.
   */
  static async plan(csvText: string): Promise<SheetPlan> {
    const table = parseCsv(csvText).filter(
      (row) => row.length > 0 && row.some((cell) => cell.trim() !== '')
    );

    if (table.length === 0) {
      throw new Error('The file is empty.');
    }

    const header = table[0].map((h) => h.trim().toLowerCase());
    const missing = SHEET_COLUMNS.filter((c) => !header.includes(c));
    if (missing.length > 0) {
      throw new Error(
        `This does not look like an inventory sheet — missing column(s): ${missing.join(', ')}. ` +
          'Download a fresh sheet and edit that.'
      );
    }
    const at = (row: string[], column: (typeof SHEET_COLUMNS)[number]): string =>
      (row[header.indexOf(column)] ?? '').trim();

    const dataRows = table.slice(1);

    // Load every referenced product and variant up front. One query each rather
    // than per row — a 400-row sheet would otherwise be 800 round-trips.
    const productIds = new Set<number>();
    const variantIds = new Set<number>();
    for (const row of dataRows) {
      const p = Number(at(row, 'product_id'));
      if (Number.isInteger(p) && p > 0) productIds.add(p);
      const v = Number(at(row, 'variant_id'));
      if (Number.isInteger(v) && v > 0) variantIds.add(v);
    }

    const products = productIds.size
      ? await AppDataSource.getRepository(Product).findBy({ id: In([...productIds]) })
      : [];
    const variants = variantIds.size
      ? await AppDataSource.getRepository(ProductVariant).find({
          where: { id: In([...variantIds]) },
          relations: ['product'],
        })
      : [];

    const productById = new Map(products.map((p) => [p.id, p]));
    const variantById = new Map(variants.map((v) => [v.id, v]));

    const rows: PlannedRow[] = [];
    const problems: RowProblem[] = [];
    let unchangedRows = 0;

    dataRows.forEach((row, index) => {
      // +2: one for the header, one because spreadsheets count from 1. This is
      // the number the admin sees in Excel's left margin.
      const lineNumber = index + 2;
      const rowType = at(row, 'row_type').toLowerCase();
      const label =
        [at(row, 'product_name'), at(row, 'size')].filter(Boolean).join(' — ') ||
        `row ${lineNumber}`;

      const fail = (message: string) =>
        problems.push({ lineNumber, label, message, severity: 'error' });
      const warn = (message: string) =>
        problems.push({ lineNumber, label, message, severity: 'warning' });

      if (rowType !== 'product' && rowType !== 'size') {
        fail(`Unknown row_type "${at(row, 'row_type')}". Expected "product" or "size".`);
        return;
      }

      const productId = Number(at(row, 'product_id'));
      if (!Number.isInteger(productId) || productId <= 0) {
        // No id means "new product". Not supported yet, and silently ignoring
        // the row would look like the upload had worked.
        fail('Missing product_id. Adding new products from the sheet is not supported yet.');
        return;
      }

      const product = productById.get(productId);
      if (!product) {
        fail(`No product with id ${productId}. Do not add rows by hand.`);
        return;
      }

      const changes: PlannedChange[] = [];

      if (rowType === 'size') {
        const variantId = Number(at(row, 'variant_id'));
        if (!Number.isInteger(variantId) || variantId <= 0) {
          fail('A "size" row needs a variant_id.');
          return;
        }
        const variant = variantById.get(variantId);
        if (!variant) {
          fail(`No size with id ${variantId}.`);
          return;
        }
        if (variant.product?.id !== productId) {
          fail(`Size ${variantId} does not belong to product ${productId}.`);
          return;
        }

        collectStock(row, at, variant.stock, changes, fail, warn);
        collectPrice(row, at, variant.price, changes, fail, warn);
        collectAvailable(row, at, variant.isAvailable, changes, fail, warn);

        if (changes.length === 0) unchangedRows++;
        else rows.push({ lineNumber, productId, variantId, label, changes });
        return;
      }

      // row_type === 'product'
      const sellsAtProductLevel = !hasVariants(product);

      if (sellsAtProductLevel) {
        collectStock(row, at, product.stock, changes, fail, warn);
        collectPrice(row, at, product.price, changes, fail, warn);
      } else {
        // Stock and price on a parent row have no effect — order creation reads
        // them from the size. Say so rather than pretending to apply them.
        if (at(row, 'stock') !== '' || at(row, 'price') !== '') {
          warn(
            'This product sells by size, so stock and price on this row are ignored. ' +
              'Edit the "size" rows below it instead.'
          );
        }
      }

      collectAvailable(row, at, product.isAvailable, changes, fail, warn);

      if (changes.length === 0) unchangedRows++;
      else rows.push({ lineNumber, productId, variantId: null, label, changes });
    });

    return {
      totalRows: dataRows.length,
      unchangedRows,
      rows,
      problems,
      errorCount: problems.filter((p) => p.severity === 'error').length,
    };
  }
}

function hasVariants(product: Product): boolean {
  // product.hasVariants is a flag an admin can set independently of whether any
  // variant rows exist, so trust the relation when it is loaded and fall back to
  // the flag otherwise.
  if (Array.isArray(product.variants)) return product.variants.length > 0;
  return !!product.hasVariants;
}

type Getter = (row: string[], column: (typeof SHEET_COLUMNS)[number]) => string;

/**
 * Stock is applied as a DIFFERENCE, never as an absolute.
 *
 * Customers buy while the sheet is open. If the download said 50, eight sell,
 * and the admin types 60 meaning "+10", writing 60 would erase those eight real
 * sales and oversell. Applying (60 − 50) = +10 to the live value gives 52.
 *
 * `was_stock` is therefore load-bearing, which is also why a tampered one is
 * caught here rather than trusted.
 */
function collectStock(
  row: string[],
  at: Getter,
  current: number,
  changes: PlannedChange[],
  fail: (m: string) => void,
  warn: (m: string) => void
): void {
  const raw = at(row, 'stock');
  const wasRaw = at(row, 'was_stock');
  if (raw === '' && wasRaw === '') return;

  const next = Number(raw);
  const was = Number(wasRaw);

  if (!Number.isInteger(next) || next < 0) {
    fail(`Stock must be a whole number of 0 or more (got "${raw}").`);
    return;
  }
  if (!Number.isInteger(was) || was < 0) {
    fail('The was_stock column has been edited or cleared. Download a fresh sheet.');
    return;
  }

  const delta = next - was;
  if (delta === 0) return;

  if (Math.abs(delta) > IMPLAUSIBLE_STOCK_DELTA) {
    fail(`Stock change of ${delta} looks like a typo. Nothing applied for this row.`);
    return;
  }

  const projected = current + delta;
  if (projected < 0) {
    fail(
      `This would take stock to ${projected}. ${current} left in the system now — ` +
        'someone may have bought some since you downloaded the sheet.'
    );
    return;
  }

  if (was !== current) {
    // Not an error: the difference is still correct. But the admin should know
    // the final number will not be the one they typed.
    warn(
      `Stock moved from ${was} to ${current} since you downloaded (sales). ` +
        `Applying your change of ${delta >= 0 ? '+' : ''}${delta} gives ${projected}, not ${next}.`
    );
  }

  changes.push({ field: 'stock', before: String(current), after: String(projected), delta });
}

/**
 * Price is applied EXACTLY as typed — no difference arithmetic. Nothing else in
 * the system changes prices concurrently, so there is nothing to merge with.
 *
 * `was_price` is still checked, to catch a stale sheet reverting a change made
 * in the app after the download.
 */
function collectPrice(
  row: string[],
  at: Getter,
  currentRaw: number | string,
  changes: PlannedChange[],
  fail: (m: string) => void,
  warn: (m: string) => void
): void {
  const raw = at(row, 'price');
  if (raw === '') return;

  const next = Number(raw);
  if (!Number.isFinite(next) || next <= 0) {
    fail(`Price must be a number greater than 0 (got "${raw}").`);
    return;
  }
  if (next > MAX_PRICE) {
    fail(`Price of ${next} looks like a typo. Nothing applied for this row.`);
    return;
  }

  const current = round2(Number(currentRaw));
  const rounded = round2(next);
  if (rounded === current) return;

  const was = round2(Number(at(row, 'was_price')));
  if (Number.isFinite(was) && was !== current) {
    warn(
      `Price changed to ${current.toFixed(2)} in the app after you downloaded ` +
        `(your sheet says it was ${was.toFixed(2)}). Applying ${rounded.toFixed(2)} will overwrite that.`
    );
  }

  changes.push({ field: 'price', before: current.toFixed(2), after: rounded.toFixed(2) });
}

function collectAvailable(
  row: string[],
  at: Getter,
  current: boolean,
  changes: PlannedChange[],
  fail: (m: string) => void,
  warn: (m: string) => void
): void {
  const raw = at(row, 'available');
  if (raw === '') return;

  const next = parseYesNo(raw);
  if (next === null) {
    fail(`Available must be YES or NO (got "${raw}").`);
    return;
  }
  if (next === current) return;

  const was = parseYesNo(at(row, 'was_available'));
  if (was !== null && was !== current) {
    warn('Availability changed in the app after you downloaded. Your sheet will overwrite it.');
  }

  changes.push({
    field: 'available',
    before: current ? 'YES' : 'NO',
    after: next ? 'YES' : 'NO',
  });
}

/** Excel helpfully turns some of these into TRUE/FALSE or 1/0, so accept all. */
function parseYesNo(raw: string): boolean | null {
  const v = raw.trim().toLowerCase();
  if (['yes', 'y', 'true', '1'].includes(v)) return true;
  if (['no', 'n', 'false', '0'].includes(v)) return false;
  return null;
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}
