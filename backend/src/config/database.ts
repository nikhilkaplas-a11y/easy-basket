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
import { ServiceArea } from '../entities/ServiceArea';
import { ProductVariant } from '../entities/ProductVariant';

export const AppDataSource = new DataSource({
  type: 'mysql',
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  username: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || 'password',
  database: process.env.DB_NAME || 'easy_basket',
  synchronize: false, // Disabled to prevent index drop errors with foreign keys. Schema is already correct.
  logging: process.env.NODE_ENV === 'development',
  entities: [User, Product, Order, Category, Address, OrderItem, RefreshToken, ServiceArea, ProductVariant],
  subscribers: [],
  migrations: [],
  extra: {
    connectionLimit: 10,
    connectTimeout: 10000, // 10 seconds connection timeout
  },
});
