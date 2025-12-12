#!/bin/bash

# Script to update Nginx config with load balancing
# Run this on your EC2 server

set -e

echo "🔧 Updating Nginx configuration for load balancing..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Find Nginx config file
CONFIG_FILE=""
if [ -f "/etc/nginx/conf.d/easy-basket.conf" ]; then
    CONFIG_FILE="/etc/nginx/conf.d/easy-basket.conf"
elif [ -f "/etc/nginx/sites-available/easy-basket" ]; then
    CONFIG_FILE="/etc/nginx/sites-available/easy-basket"
else
    echo -e "${RED}❌ Could not find Nginx config file${NC}"
    echo "Please specify the path to your Nginx config file:"
    read -p "Config file path: " CONFIG_FILE
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ File not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found config file: $CONFIG_FILE${NC}"

# Backup
BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}📦 Creating backup: $BACKUP_FILE${NC}"
sudo cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✅ Backup created${NC}"

# Create new config
echo -e "${YELLOW}📝 Creating new configuration...${NC}"
sudo tee "$CONFIG_FILE" > /dev/null << 'NGINXCONF'
# Nginx Configuration with Load Balancing for PM2 Cluster Mode
# Updated for production with SSL/HTTPS support

# Upstream backend servers - PM2 cluster mode
upstream backend_servers {
    # PM2 cluster mode - all instances share port 3000
    # Nginx automatically load balances between them
    least_conn; # Use least connections algorithm (better than round-robin)
    
    server 127.0.0.1:3000 max_fails=3 fail_timeout=30s;
    
    # If you add more physical servers later, add them here:
    # server <another-ec2-ip>:3000 max_fails=3 fail_timeout=30s;
    
    # Keep connections alive for better performance
    keepalive 32;
}

# HTTPS Server (Primary)
server {
    listen 443 ssl http2;
    server_name api.easybasket.in localhost 13.60.76.140 _;

    # SSL Certificates (managed by Certbot)
    ssl_certificate /etc/letsencrypt/live/api.easybasket.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.easybasket.in/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Logging
    access_log /var/log/nginx/easy-basket-access.log;
    error_log /var/log/nginx/easy-basket-error.log;

    # Increase buffer sizes for better performance
    client_max_body_size 10M;
    client_body_buffer_size 128k;

    # Proxy settings with load balancing
    location / {
        proxy_pass http://backend_servers;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Connection reuse
        proxy_set_header Connection "";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Health check and failover
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_next_upstream_tries 3;
        proxy_next_upstream_timeout 10s;
        
        # Cache bypass
        proxy_cache_bypass $http_upgrade;
    }

    # Health check endpoint
    location /api/health {
        proxy_pass http://backend_servers/api/health;
        access_log off;
    }
}

# HTTP Server - Redirect to HTTPS
server {
    listen 80;
    server_name api.easybasket.in localhost 13.60.76.140 _;

    # Redirect all HTTP to HTTPS
    if ($host = api.easybasket.in) {
        return 301 https://$host$request_uri;
    }

    # For other server names, also redirect to HTTPS
    return 301 https://api.easybasket.in$request_uri;
}
NGINXCONF

echo -e "${GREEN}✅ Configuration updated${NC}"

# Test configuration
echo -e "${YELLOW}🔍 Testing Nginx configuration...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuration is valid!${NC}"
    
    # Ask to reload
    echo ""
    read -p "Reload Nginx now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl reload nginx
        echo -e "${GREEN}✅ Nginx reloaded successfully!${NC}"
    else
        echo -e "${YELLOW}⚠️  Nginx not reloaded. Run manually: sudo systemctl reload nginx${NC}"
    fi
else
    echo -e "${RED}❌ Configuration test failed!${NC}"
    echo -e "${YELLOW}⚠️  Restoring backup...${NC}"
    sudo cp "$BACKUP_FILE" "$CONFIG_FILE"
    echo -e "${GREEN}✅ Backup restored${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Done!${NC}"
echo ""
echo "Next steps:"
echo "1. Setup PM2 cluster mode: cd ~/easy-basket/backend && pm2 start ecosystem.config.js"
echo "2. Test API: curl https://api.easybasket.in/api/health"
echo "3. Check PM2: pm2 status"

