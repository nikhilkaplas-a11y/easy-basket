import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

/**
 * One row per spreadsheet upload that actually tried to change data.
 *
 * A preview writes nothing, so previews are not recorded here — only applies.
 *
 * Table and column names are declared EXPLICITLY rather than left to TypeORM's
 * defaults. Migration 006 was written in snake_case while its entity used the
 * camelCase defaults, so the two disagreed on nearly every identifier and the
 * feature was dead. Pinning both ends removes that risk. See
 * 008_inventory_batches.sql, which mirrors this exactly.
 */
@Entity({ name: 'inventory_batches' })
export class InventoryBatch {
  @PrimaryGeneratedColumn({ type: 'int' })
  id!: number;

  /** Admin who uploaded the sheet. */
  @Column({ name: 'actorUserId', type: 'int' })
  actorUserId!: number;

  /** 'csv' today; room for 'admin_ui' if the in-app grid is built later. */
  @Column({ name: 'source', type: 'varchar', length: 32, default: 'csv' })
  source!: string;

  /** 'applied' | 'failed' */
  @Column({ name: 'status', type: 'varchar', length: 32 })
  status!: 'applied' | 'failed';

  /** Data rows in the uploaded file, excluding the header. */
  @Column({ name: 'rowCount', type: 'int', default: 0 })
  rowCount!: number;

  /** Individual field changes written — matches the adjustment row count. */
  @Column({ name: 'changedCount', type: 'int', default: 0 })
  changedCount!: number;

  @Column({ name: 'errorCount', type: 'int', default: 0 })
  errorCount!: number;

  @Column({ name: 'note', type: 'varchar', length: 500, nullable: true })
  note!: string | null;

  @Index('idx_inventory_batch_created')
  @CreateDateColumn({ name: 'createdAt', precision: 6 })
  createdAt!: Date;
}
