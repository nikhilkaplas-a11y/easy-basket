#!/bin/bash

# Initial EC2 Setup Script for Easy Basket
# Run this ONCE when you first connect to a fresh EC2 instance

set -e

echo "🔧 Setting up EC2 instance for Easy Basket..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo -e "${GREEN}Detected OS: $OS${NC}"

# Update system
echo -e "${GREEN}📦 Updating system packages...${NC}"
if [ "$OS" == "amzn" ] || [ "$OS" == "rhel" ]; then
    sudo yum update -y
elif [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    sudo apt update && sudo apt upgrade -y
fi

# Install Node.js 18.x
echo -e "${GREEN}📦 Installing Node.js 18.x...${NC}"
if [ "$OS" == "amzn" ] || [ "$OS" == "rhel" ]; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
elif [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Install Git
echo -e "${GREEN}📦 Installing Git...${NC}"
if [ "$OS" == "amzn" ] || [ "$OS" == "rhel" ]; then
    sudo yum install -y git
elif [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    sudo apt install -y git
fi

# Install PM2
echo -e "${GREEN}📦 Installing PM2...${NC}"
sudo npm install -g pm2

# Install Nginx (optional, for reverse proxy)
echo -e "${YELLOW}Do you want to install Nginx? (y/n)${NC}"
read -r install_nginx
if [ "$install_nginx" == "y" ] || [ "$install_nginx" == "Y" ]; then
    if [ "$OS" == "amzn" ] || [ "$OS" == "rhel" ]; then
        sudo yum install -y nginx
    elif [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        sudo apt install -y nginx
    fi
    sudo systemctl enable nginx
    echo -e "${GREEN}✓ Nginx installed${NC}"
fi

# Install MySQL Client (optional)
echo -e "${YELLOW}Do you want to install MySQL client? (y/n)${NC}"
read -r install_mysql
if [ "$install_mysql" == "y" ] || [ "$install_mysql" == "Y" ]; then
    if [ "$OS" == "amzn" ] || [ "$OS" == "rhel" ]; then
        sudo yum install -y mysql
    elif [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        sudo apt install -y mysql-client
    fi
    echo -e "${GREEN}✓ MySQL client installed${NC}"
fi

# Verify installations
echo -e "${GREEN}✅ Installation Summary:${NC}"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "PM2: $(pm2 --version)"
echo "Git: $(git --version)"

echo -e "${GREEN}✅ EC2 setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Clone or upload your backend code"
echo "2. Configure .env file"
echo "3. Run deploy.sh script"

