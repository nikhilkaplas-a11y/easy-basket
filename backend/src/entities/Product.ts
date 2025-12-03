import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
} from 'typeorm';
import { Category } from './Category';

@Entity()
export class Product {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  name!: string;

  @Column('text', { nullable: true })
  description!: string;

  @Column('decimal', { precision: 10, scale: 2 })
  price!: number;

  @Column({ nullable: true })
  imageUrl!: string;

  @ManyToOne(() => Category, (category) => category.products)
  category!: Category;

  @Column({ default: 0 })
  stock!: number; // Inventory quantity

  @Column({ default: true })
  isAvailable!: boolean;

  @Column({ nullable: true })
  unit!: string; // kg, piece, pack, etc.

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
