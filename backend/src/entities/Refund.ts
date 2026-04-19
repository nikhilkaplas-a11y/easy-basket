import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Payment } from './Payment';

export type RefundStatus = 'pending' | 'processed' | 'failed';

@Entity({ name: 'refunds' })
@Index('uniq_payment_idem', ['paymentId', 'idempotencyKey'], { unique: true })
export class Refund {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @ManyToOne(() => Payment)
  @JoinColumn({ name: 'payment_id' })
  payment!: Payment;

  @Column({ name: 'payment_id', type: 'bigint', unsigned: true })
  paymentId!: string;

  @Column({ name: 'user_id', type: 'int' })
  userId!: number;

  @Index('uniq_rzp_refund', { unique: true })
  @Column({ name: 'razorpay_refund_id', type: 'varchar', length: 64, nullable: true })
  razorpayRefundId!: string | null;

  @Column({ name: 'amount_paise', type: 'bigint', unsigned: true })
  amountPaise!: string;

  @Column({ type: 'enum', enum: ['pending', 'processed', 'failed'], default: 'pending' })
  status!: RefundStatus;

  @Column({ type: 'varchar', length: 255, nullable: true })
  reason!: string | null;

  @Column({ name: 'idempotency_key', type: 'char', length: 64 })
  idempotencyKey!: string;

  @CreateDateColumn({ name: 'created_at', precision: 3 })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', precision: 3 })
  updatedAt!: Date;
}
