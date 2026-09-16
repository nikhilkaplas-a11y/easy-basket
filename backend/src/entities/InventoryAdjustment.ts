import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

/**
 * One row per individual field changed by a spreadsheet upload.
 *
 * Deliberately has NO foreign key to product or product_variant. The audit must
 * outlive the thing it describes — a dangling id is still evidence of what
 * happened, whereas a cascade-deleted audit row is not.
 *
 * Values are stored as text so one table covers integers, decimals and YES/NO
 * without three sets of nullable typed columns. This is a human-readable log,
 * never a source of computation.
 *
 * Names are explicit on both sides — see InventoryBatch for why.
 */
@Entity({ name: 'inventory_adjustments' })
export class InventoryAdjustment {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Index('idx_inventory_adjustment_batch')
  @Column({ name: 'batchId', type: 'int' })
  batchId!: number;

  @Column({ name: 'productId', type: 'int' })
  productId!: number;

  /**
   * Null when the change was at product level — either a product with no sizes,
   * or the availability flag on a product that has them.
   */
  @Column({ name: 'variantId', type: 'int', nullable: true })
  variantId!: number | null;

  @Column({ name: 'field', type: 'varchar', length: 16 })
  field!: 'stock' | 'price' | 'available';

  @Column({ name: 'beforeValue', type: 'varchar', length: 64, nullable: true })
  beforeValue!: string | null;

  @Column({ name: 'afterValue', type: 'varchar', length: 64, nullable: true })
  afterValue!: string | null;

  @CreateDateColumn({ name: 'createdAt', precision: 6 })
  createdAt!: Date;
}
