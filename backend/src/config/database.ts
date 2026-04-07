import { Address } from '../entities/Address';
import { Campaign } from '../entities/Campaign';
import { Category } from '../entities/Category';
import { DataSource } from 'typeorm';
import { Order } from '../entities/Order';
import { OrderItem } from '../entities/OrderItem';
import { Product } from '../entities/Product';
import { ProductVariant } from '../entities/ProductVariant';
import { RefreshToken } from '../entities/RefreshToken';
import { ServiceArea } from '../entities/ServiceArea';
import { User } from '../entities/User';
import dotenv from 'dotenv';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'mysql',
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  username: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || 'password',
  database: process.env.DB_NAME || 'easy_basket',
  synchronize: false, // Disabled to prevent index drop errors with foreign keys. Schema is already correct.
  logging: process.env.NODE_ENV === 'development',
  entities: [
    User,
    Product,
    Order,
    Category,
    Address,
    OrderItem,
    RefreshToken,
    ServiceArea,
    ProductVariant,
    Campaign,
  ],
  subscribers: [],
  migrations: [],
  extra: {
    connectionLimit: 10,
    connectTimeout: 10000, // 10 seconds connection timeout
  },
});
