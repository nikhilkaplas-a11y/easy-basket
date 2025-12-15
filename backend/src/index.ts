import 'reflect-metadata';

import { AppDataSource } from './config/database';
import addressRoutes from './routes/address.routes';
import adminRoutes from './routes/admin.routes';
import authRoutes from './routes/auth.routes';
import categoryRoutes from './routes/category.routes';
import cors from 'cors';
import deliveryRoutes from './routes/delivery.routes';
import dotenv from 'dotenv';
import express from 'express';
import orderRoutes from './routes/order.routes';
import paymentRoutes from './routes/payment.routes';
import productRoutes from './routes/product.routes';
import serviceAreaRoutes from './routes/serviceArea.routes';
import uploadRoutes from './routes/upload.routes';
import variantRoutes from './routes/variant.routes';

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
app.use('/api/admin', uploadRoutes);
app.use('/api', variantRoutes);

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
  .catch((error: any) => {
    console.error('❌ Database connection error:', error.message || error);
    
    // Check for specific index drop error
    if (error.code === 'ER_DROP_INDEX_FK' || error.errno === 1553) {
      console.error('');
      console.error('⚠️  TypeORM tried to drop an index required by a foreign key constraint.');
      console.error('💡 This is usually safe to ignore if the database schema is already correct.');
      console.error('💡 Solutions:');
      console.error('   1. The explicit @Index decorator in Category entity should prevent this');
      console.error('   2. If it persists, temporarily set synchronize: false in database.ts');
      console.error('   3. Or manually verify the database schema is correct');
      console.error('');
    }
    
    console.error('⚠️  Server will still start, but database operations will fail');
    // Start server anyway (for health checks)
    app.listen(PORT, () => {
      console.log(`⚠️  Server is running on port ${PORT} (without database)`);
    });
  });
