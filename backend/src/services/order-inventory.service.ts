import { AppDataSource } from '../config/database';
import { OrderItem } from '../entities/OrderItem';
import { Product } from '../entities/Product';
import { ProductVariant } from '../entities/ProductVariant';
import { ProductController } from '../controllers/product.controller';

/**
 * Mirrors create-order stock deduction: restore variant stock when a line has a variant,
 * otherwise restore base product stock.
 */
export class OrderInventoryService {
  static async restoreReservedStockForItems(items: OrderItem[]): Promise<void> {
    const productRepository = AppDataSource.getRepository(Product);
    const variantRepository = AppDataSource.getRepository(ProductVariant);

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
