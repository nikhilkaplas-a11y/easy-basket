import 'reflect-metadata';

import { AppDataSource } from './config/database';
import { RequestTimingMiddleware } from './middleware/requestTiming.middleware';
import { S3Service } from './services/s3.service';
import { OrderAutoCancelService } from './services/order-auto-cancel.service';
import { RedisService } from './services/redis.service';
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
import campaignRoutes from './routes/campaign.routes';

// Load environment variables FIRST before importing any modules that use them
dotenv.config();

// Re-initialize S3Service after dotenv.config() to ensure env vars are loaded
// (S3Service.initialize() is called on module load, but env vars might not be ready)
S3Service.initialize();

const app = express();
const PORT = process.env.PORT || 3000;

// CORS configuration - allow all origins for development
app.use(
  cors({
    origin: true, // Allow all origins
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);
app.use(express.json());
app.use(RequestTimingMiddleware.handle);

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
app.use('/api/campaigns', campaignRoutes);

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
  .then(async () => {
    console.log('✅ Database connected successfully');
    console.log(`📊 Database: ${process.env.DB_NAME || 'easy_basket'}`);
    console.log(`🌐 Host: ${process.env.DB_HOST || 'localhost'}`);

    try {
      await RedisService.pingRequired();
      console.log('✅ Redis connected (required)');
    } catch (redisErr) {
      console.error('❌ Redis is required but unavailable:', (redisErr as Error).message);
      console.error(
        '💡 Set REDIS_URL or REDIS_HOST, REDIS_PORT, REDIS_PASSWORD (optional: REDIS_USERNAME, REDIS_TLS).'
      );
      await AppDataSource.destroy().catch(() => undefined);
      process.exit(1);
    }

    // Check S3 initialization status with detailed debugging
    console.log('');
    console.log('🔍 Checking AWS S3 configuration...');
    console.log(`   AWS_ACCESS_KEY_ID: ${process.env.AWS_ACCESS_KEY_ID ? '✅ Set' : '❌ Missing'}`);
    console.log(
      `   AWS_SECRET_ACCESS_KEY: ${process.env.AWS_SECRET_ACCESS_KEY ? '✅ Set' : '❌ Missing'}`
    );
    console.log(
      `   AWS_S3_BUCKET_NAME: ${process.env.AWS_S3_BUCKET_NAME ? `✅ Set (${process.env.AWS_S3_BUCKET_NAME})` : '❌ Missing'}`
    );
    console.log(
      `   AWS_REGION: ${process.env.AWS_REGION || 'ap-south-1 (Mumbai, India - default)'}`
    );

    if (
      process.env.AWS_ACCESS_KEY_ID &&
      process.env.AWS_SECRET_ACCESS_KEY &&
      process.env.AWS_S3_BUCKET_NAME
    ) {
      console.log('✅ AWS S3 credentials configured');
      console.log(`📦 S3 Bucket: ${process.env.AWS_S3_BUCKET_NAME}`);
      console.log(`🌍 S3 Region: ${process.env.AWS_REGION || 'ap-south-1 (Mumbai, India)'}`);
    } else {
      console.log('');
      console.log('⚠️  AWS S3 not configured - Image upload will be disabled');
      console.log('');
      console.log('💡 Troubleshooting:');
      console.log('   1. Check if .env file exists in backend directory');
      console.log('   2. Verify .env file contains all required variables');
      console.log('   3. If using PM2, check ecosystem.config.js for env vars');
      console.log('   4. Restart PM2 after updating .env: pm2 restart all');
      console.log('');
      console.log('📝 Required variables:');
      console.log('   AWS_ACCESS_KEY_ID=your_access_key_id');
      console.log('   AWS_SECRET_ACCESS_KEY=your_secret_access_key');
      console.log('   AWS_S3_BUCKET_NAME=your-bucket-name');
      console.log('   AWS_REGION=ap-south-1 (Mumbai, India - optional, default)');
    }
    console.log('');

    // Auto-cancel: pending orders past ORDER_AUTO_CANCEL_MINUTES (default 30)
    OrderAutoCancelService.start();

    app.listen(PORT, () => {
      console.log(`🚀 Server is running on port ${PORT}`);
    });
  })
  .catch((error: any) => {
    console.error('❌ Database connection error:', error.message || error);

    // Helpful hints for ETIMEDOUT (can't reach DB host)
    if (error.code === 'ETIMEDOUT' || error.message?.includes('ETIMEDOUT')) {
      console.error('');
      console.error('💡 ETIMEDOUT = Cannot reach the database host. Check:');
      console.error('   1. DB_HOST in .env – use localhost if MySQL is on this machine');
      console.error('   2. MySQL is running: mysql is running, or brew services start mysql');
      console.error('   3. If remote DB: firewall, security group, or VPN blocking port 3306');
      console.error('   4. DB_PORT (default 3306) matches your MySQL port');
      console.error(
        `   Current: host=${process.env.DB_HOST || 'localhost'} port=${process.env.DB_PORT || '3306'}`
      );
      console.error('');
    }

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
