import 'reflect-metadata';
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { AppDataSource } from './config/database';

import authRoutes from './routes/auth.routes';
import productRoutes from './routes/product.routes';
import orderRoutes from './routes/order.routes';
import categoryRoutes from './routes/category.routes';
import addressRoutes from './routes/address.routes';
import adminRoutes from './routes/admin.routes';
import deliveryRoutes from './routes/delivery.routes';
import paymentRoutes from './routes/payment.routes';
import serviceAreaRoutes from './routes/serviceArea.routes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// CORS configuration - allow all origins for development
app.use(cors({
  origin: true, // Allow all origins
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/addresses', addressRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/delivery', deliveryRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/service-area', serviceAreaRoutes);

app.get('/', (req, res) => {
  res.send('Easy Basket Backend is running');
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Easy Basket Backend is running',
    timestamp: new Date().toISOString(),
  });
});

AppDataSource.initialize()
  .then(() => {
    console.log('✅ Database connected successfully');
    console.log(`📊 Database: ${process.env.DB_NAME || 'easy_basket'}`);
    console.log(`🌐 Host: ${process.env.DB_HOST || 'localhost'}`);
    app.listen(PORT, () => {
      console.log(`🚀 Server is running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error('❌ Database connection error:', error);
    console.error('⚠️  Server will still start, but database operations will fail');
    // Start server anyway (for health checks)
    app.listen(PORT, () => {
      console.log(`⚠️  Server is running on port ${PORT} (without database)`);
    });
  });
