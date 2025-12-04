#!/bin/bash

# Complete Nginx Setup Script for Easy Basket
# Run this on your EC2 instance

set -e

echo "🌐 Setting up Nginx for Easy Basket..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Install Nginx
echo -e "${GREEN}📦 Step 1: Installing Nginx...${NC}"
if command -v yum &> /dev/null; then
    sudo yum install -y nginx
elif command -v apt &> /dev/null; then
    sudo apt update
    sudo apt install -y nginx
else
    echo "❌ Package manager not found. Please install Nginx manually."
    exit 1
fi

# Step 2: Start and Enable Nginx
echo -e "${GREEN}🚀 Step 2: Starting Nginx...${NC}"
sudo systemctl start nginx
sudo systemctl enable nginx

# Step 3: Create Configuration
echo -e "${GREEN}⚙️  Step 3: Creating Nginx configuration...${NC}"
sudo tee /etc/nginx/conf.d/easy-basket.conf > /dev/null << 'NGINXCONF'
server {
    listen 80;
    server_name _;  # Accepts all server names

    # Logging
    access_log /var/log/nginx/easy-basket-access.log;
    error_log /var/log/nginx/easy-basket-error.log;

    # Proxy settings
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Cache bypass
        proxy_cache_bypass $http_upgrade;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3000/api/health;
        access_log off;
    }
}
NGINXCONF

# Step 4: Test Configuration
echo -e "${GREEN}🔍 Step 4: Testing Nginx configuration...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuration is valid!${NC}"
else
    echo -e "${YELLOW}❌ Configuration has errors. Please check.${NC}"
    exit 1
fi

# Step 5: Reload Nginx
echo -e "${GREEN}🔄 Step 5: Reloading Nginx...${NC}"
sudo systemctl reload nginx

# Step 6: Check Status
echo -e "${GREEN}📊 Step 6: Checking Nginx status...${NC}"
sudo systemctl status nginx --no-pager | head -10

# Step 7: Test
echo -e "${GREEN}🧪 Step 7: Testing Nginx...${NC}"
sleep 2

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "YOUR_EC2_IP")

echo ""
echo -e "${GREEN}✅ Nginx setup complete!${NC}"
echo ""
echo "📋 Next Steps:"
echo "1. Update Security Group:"
echo "   - Add HTTP (port 80) inbound rule"
echo "   - Source: 0.0.0.0/0 (or your IP)"
echo ""
echo "2. Test from EC2:"
echo "   curl http://localhost/api/health"
echo ""
echo "3. Test from outside:"
echo "   curl http://${PUBLIC_IP}/api/health"
echo ""
echo "4. Check logs:"
echo "   sudo tail -f /var/log/nginx/easy-basket-access.log"
echo ""

