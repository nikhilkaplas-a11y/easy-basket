import { EntityManager } from 'typeorm';
import { AppDataSource } from '../config/database';
import { OrderItem } from '../entities/OrderItem';
import { Product } from '../entities/Product';
import { ProductVariant } from '../entities/ProductVariant';
import { ProductController } from '../controllers/product.controller';

/**
 * Mirrors create-order stock deduction: restore variant stock when a line has a variant,
 * otherwise restore base product stock.
 *
 * Pass `manager` to enlist the stock writes in a caller's transaction (e.g. the payment
 * state machine) so the restore commits atomically with the order/payment transition.
 */
export class OrderInventoryService {
  static async restoreReservedStockForItems(
    items: OrderItem[],
    manager?: EntityManager
  ): Promise<void> {
    const db = manager ?? AppDataSource.manager;
    const productRepository = db.getRepository(Product);
    const variantRepository = db.getRepository(ProductVariant);

    for (const line of items) {
      if (line.variant?.id != null) {
        const variant = await variantRepository.findOneBy({ id: line.variant.id });
        if (variant) {
          variant.stock += Number(line.quantity);
          await variantRepository.save(variant);
        }
      } else {
        const product = await productRepository.findOneBy({ id: line.product.id });
        if (product) {
          product.stock += Number(line.quantity);
          await productRepository.save(product);
        }
      }
    }

    await ProductController.invalidateProductListCache();
  }
}
