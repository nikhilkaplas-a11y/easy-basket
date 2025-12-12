module.exports = {
  apps: [{
    name: 'easy-basket-api',
    script: 'dist/index.js',
    instances: 'max', // Use all CPU cores, or specify number like 2, 4
    exec_mode: 'cluster', // Enable cluster mode for load balancing
    env: {
      NODE_ENV: 'production',
      PORT: 3000
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

