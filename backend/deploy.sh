#!/bin/bash

# Easy Basket Backend Deployment Script for AWS EC2
# Run this script on your EC2 instance after initial setup

set -e

echo "🚀 Starting Easy Basket Backend Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Please do not run as root${NC}"
   exit 1
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js is not installed. Please install Node.js first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Node.js version: $(node --version)${NC}"

# Check PM2
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}PM2 not found. Installing PM2...${NC}"
    sudo npm install -g pm2
fi

echo -e "${GREEN}✓ PM2 version: $(pm2 --version)${NC}"

# Navigate to backend directory
if [ ! -d "backend" ]; then
    echo -e "${RED}Backend directory not found. Please run this script from the project root.${NC}"
    exit 1
fi

cd backend

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠ .env file not found. Creating from .env.example...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${YELLOW}Please edit .env file with your production values!${NC}"
        echo -e "${YELLOW}Press Enter to continue after editing .env...${NC}"
        read
    else
        echo -e "${RED}.env.example not found. Please create .env manually.${NC}"
        exit 1
    fi
fi

# Install dependencies
echo -e "${GREEN}📦 Installing dependencies...${NC}"
npm install

# Build TypeScript
#
# The old dist is removed first. `[ -d dist ]` alone was not a build check: a dist
# left over from an earlier release satisfies it even when the build silently failed
# or never ran, and PM2 then happily serves months-old code. That is not theoretical
# — the checked-in dist predated the entire payments-v2 stack.
echo -e "${GREEN}🧹 Removing previous build...${NC}"
rm -rf dist

echo -e "${GREEN}🔨 Building TypeScript...${NC}"
npm run build

# Assert the build actually produced the current payment stack, not just *a* dist.
REQUIRED_ARTIFACTS=(
    "dist/index.js"
    "dist/services/payments-v2.service.js"
    "dist/services/payments-reconciler.service.js"
    "dist/services/leader-election.service.js"
    "dist/config/razorpay-env.js"
    "dist/services/queue/payment-reconcile.worker.js"
    "dist/services/queue/refund-retry.worker.js"
)
for artifact in "${REQUIRED_ARTIFACTS[@]}"; do
    if [ ! -f "$artifact" ]; then
        echo -e "${RED}Build incomplete! Missing $artifact${NC}"
        echo -e "${RED}Refusing to deploy — this would ship a payment system without it.${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✓ Build successful (payment stack verified)${NC}"

# Stop existing PM2 process if running
if pm2 list | grep -q "easy-basket-api"; then
    echo -e "${YELLOW}Stopping existing application...${NC}"
    pm2 stop easy-basket-api || true
    pm2 delete easy-basket-api || true
fi

# Start application with PM2
echo -e "${GREEN}🚀 Starting application with PM2...${NC}"
pm2 start dist/index.js --name easy-basket-api

# Save PM2 configuration
pm2 save

# Setup PM2 startup script
echo -e "${GREEN}⚙️  Setting up PM2 startup script...${NC}"
STARTUP_CMD=$(pm2 startup | grep -o 'sudo.*')
if [ ! -z "$STARTUP_CMD" ]; then
    echo -e "${YELLOW}Run this command to enable PM2 on boot:${NC}"
    echo -e "${YELLOW}$STARTUP_CMD${NC}"
fi

# Show status
echo -e "${GREEN}📊 Application Status:${NC}"
pm2 status

# Show logs
echo -e "${GREEN}📋 Recent logs:${NC}"
pm2 logs easy-basket-api --lines 20 --nostream

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${GREEN}Your application should be running on http://localhost:3000${NC}"
echo -e "${YELLOW}To view logs: pm2 logs easy-basket-api${NC}"
echo -e "${YELLOW}To restart: pm2 restart easy-basket-api${NC}"
echo -e "${YELLOW}To stop: pm2 stop easy-basket-api${NC}"

