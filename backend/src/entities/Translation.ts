import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from "typeorm";

@Entity("translations")
export class Translation {
  @PrimaryGeneratedColumn()
  id!: number;

  @Index({ unique: true })
  @Column()
  key!: string;

  @Column()
  en!: string;

  @Column({ nullable: true })
  hi!: string;

  @Column({ nullable: true })
  pa!: string;

  @Column({
    default: "product",
  })
  type!: string;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}