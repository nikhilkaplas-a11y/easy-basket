import { DataSource } from 'typeorm';
import dotenv from 'dotenv';

dotenv.config();

import { User } from '../entities/User';
import { Product } from '../entities/Product';
import { Order } from '../entities/Order';
import { Category } from '../entities/Category';
import { Address } from '../entities/Address';
import { OrderItem } from '../entities/OrderItem';
import { RefreshToken } from '../entities/RefreshToken';

export const AppDataSource = new DataSource({
  type: 'mysql',
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  username: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || 'password',
  database: process.env.DB_NAME || 'easy_basket',
  synchronize: process.env.NODE_ENV !== 'production', // Auto-sync only in development
  logging: process.env.NODE_ENV === 'development',
  entities: [User, Product, Order, Category, Address, OrderItem, RefreshToken],
  subscribers: [],
  migrations: [],
});
