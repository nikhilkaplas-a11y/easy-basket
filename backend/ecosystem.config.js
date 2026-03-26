const path = require('path');
// Load .env file from the same directory as this config file
require('dotenv').config({ path: path.join(__dirname, '.env') });

module.exports = {
  apps: [{
    name: 'easy-basket-api',
    script: 'dist/index.js',
    instances: 'max', // Use all CPU cores, or specify number like 2, 4
    exec_mode: 'cluster', // Enable cluster mode for load balancing
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      // Load AWS S3 credentials from .env file
      AWS_ACCESS_KEY_ID: process.env.AWS_ACCESS_KEY_ID,
      AWS_SECRET_ACCESS_KEY: process.env.AWS_SECRET_ACCESS_KEY,
      AWS_S3_BUCKET_NAME: process.env.AWS_S3_BUCKET_NAME,
      AWS_REGION: process.env.AWS_REGION || 'ap-south-1', // Mumbai, India - better for Indian users
      // Load other env vars from .env
      DB_HOST: process.env.DB_HOST,
      DB_PORT: process.env.DB_PORT,
      DB_USER: process.env.DB_USER,
      DB_PASS: process.env.DB_PASS,
      DB_NAME: process.env.DB_NAME,
      JWT_SECRET: process.env.JWT_SECRET,
      RAZORPAY_KEY_ID: process.env.RAZORPAY_KEY_ID,
      RAZORPAY_KEY_SECRET: process.env.RAZORPAY_KEY_SECRET,
      FIREBASE_SERVICE_ACCOUNT: process.env.FIREBASE_SERVICE_ACCOUNT,
      TWILIO_ACCOUNT_SID: process.env.TWILIO_ACCOUNT_SID,
      TWILIO_AUTH_TOKEN: process.env.TWILIO_AUTH_TOKEN,
      TWILIO_VERIFY_SERVICE_SID: process.env.TWILIO_VERIFY_SERVICE_SID,
      REDIS_URL: process.env.REDIS_URL,
      REDIS_HOST: process.env.REDIS_HOST,
      REDIS_PORT: process.env.REDIS_PORT,
      REDIS_USERNAME: process.env.REDIS_USERNAME,
      REDIS_PASSWORD: process.env.REDIS_PASSWORD,
      REDIS_TLS: process.env.REDIS_TLS,
    },
    // Auto-restart settings
    autorestart: true,
    watch: false,
    max_memory_restart: '1G', // Restart if memory exceeds 1GB
    
    // Logging
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true, // Merge logs from all instances
    
    // Zero-downtime reload settings
    kill_timeout: 5000, // Wait 5 seconds before force kill
    wait_ready: true, // Wait for app to be ready
    listen_timeout: 10000, // Wait 10 seconds for app to start listening
    
    // Graceful shutdown
    shutdown_with_message: true,
    
    // Instance management
    min_uptime: '10s', // Minimum uptime before considering stable
    max_restarts: 10, // Max restarts in 1 minute
    restart_delay: 4000, // Delay between restarts
  }]
};

