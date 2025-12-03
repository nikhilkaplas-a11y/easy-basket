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
echo -e "${GREEN}🔨 Building TypeScript...${NC}"
npm run build

# Check if build was successful
if [ ! -d "dist" ]; then
    echo -e "${RED}Build failed! dist directory not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build successful${NC}"

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

