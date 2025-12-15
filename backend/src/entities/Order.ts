import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
} from 'typeorm';
import { User } from './User';
import { Address } from './Address';
import { OrderItem } from './OrderItem';

@Entity({ name: 'orders' })
export class Order {
  @PrimaryGeneratedColumn()
  id!: number;

  @ManyToOne(() => User, (user) => user.orders)
  user!: User;

  @ManyToOne(() => Address)
  deliveryAddress!: Address;

  @ManyToOne(() => User, { nullable: true })
  deliveryBoy!: User; // Assigned delivery person

  @OneToMany(() => OrderItem, (orderItem) => orderItem.order, { cascade: true })
  items!: OrderItem[];

  @Column('decimal', { precision: 10, scale: 2 })
  totalAmount!: number;

  @Column({ default: 'pending' }) // pending, accepted, preparing, out_for_delivery, delivered, cancelled
  status!: string;

  @Column({ nullable: true })
  paymentMethod!: string; // UPI, cash, etc.

  @Column({ nullable: true })
  paymentId!: string; // Razorpay/Cashfree payment ID

  @Column({ default: false })
  isPaid!: boolean;

  @Column({ nullable: true })
  notes!: string;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
