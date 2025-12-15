#!/bin/bash

# Script to create a duplicate EC2 instance from current instance
# Run this from your local machine (requires AWS CLI configured)

set -e

echo "🚀 Creating Duplicate EC2 Instance"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Step 1: Get current instance ID
echo -e "${YELLOW}📋 Step 1: Finding your current instance...${NC}"

# Option 1: If you know the instance name/tag
read -p "Enter your instance name or tag (or press Enter to list all): " INSTANCE_NAME

if [ -z "$INSTANCE_NAME" ]; then
    echo "Available instances:"
    aws ec2 describe-instances \
        --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],State.Name,PublicIpAddress]" \
        --output table
    echo ""
    read -p "Enter Instance ID: " INSTANCE_ID
else
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text | head -1)
    
    if [ -z "$INSTANCE_ID" ]; then
        echo -e "${RED}❌ Instance not found${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Found instance: $INSTANCE_ID${NC}"

# Get instance details
INSTANCE_TYPE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].InstanceType" --output text)
KEY_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].KeyName" --output text)
SECURITY_GROUP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].SecurityGroups[0].GroupId" --output text)
SUBNET_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].SubnetId" --output text)
VPC_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].VpcId" --output text)

echo ""
echo "Instance Details:"
echo "  Type: $INSTANCE_TYPE"
echo "  Key: $KEY_NAME"
echo "  Security Group: $SECURITY_GROUP"
echo "  Subnet: $SUBNET_ID"
echo "  VPC: $VPC_ID"
echo ""

# Step 2: Create AMI
echo -e "${YELLOW}📸 Step 2: Creating AMI from instance...${NC}"
AMI_NAME="easy-basket-backend-$(date +%Y%m%d-%H%M%S)"

AMI_ID=$(aws ec2 create-image \
    --instance-id $INSTANCE_ID \
    --name "$AMI_NAME" \
    --description "Backend server AMI created on $(date)" \
    --no-reboot \
    --query 'ImageId' \
    --output text)

echo -e "${GREEN}✅ AMI creation started: $AMI_ID${NC}"
echo -e "${YELLOW}⏳ Waiting for AMI to be available (this may take 5-15 minutes)...${NC}"

# Wait for AMI to be available
while true; do
    STATE=$(aws ec2 describe-images --image-ids $AMI_ID \
        --query "Images[*].State" --output text)
    
    if [ "$STATE" == "available" ]; then
        echo -e "${GREEN}✅ AMI is ready!${NC}"
        break
    elif [ "$STATE" == "failed" ]; then
        echo -e "${RED}❌ AMI creation failed${NC}"
        exit 1
    else
        echo -e "${YELLOW}   Status: $STATE (waiting...){NC}"
        sleep 30
    fi
done

# Step 3: Launch new instance
echo ""
echo -e "${YELLOW}🚀 Step 3: Launching new instance from AMI...${NC}"

read -p "Enter name for new instance (default: easy-basket-backend-2): " NEW_INSTANCE_NAME
NEW_INSTANCE_NAME=${NEW_INSTANCE_NAME:-easy-basket-backend-2}

NEW_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP \
    --subnet-id $SUBNET_ID \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NEW_INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo -e "${GREEN}✅ New instance launched: $NEW_INSTANCE_ID${NC}"
echo -e "${YELLOW}⏳ Waiting for instance to be running...${NC}"

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids $NEW_INSTANCE_ID

# Get public IP
sleep 10
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $NEW_INSTANCE_ID \
    --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $NEW_INSTANCE_ID \
    --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)

echo ""
echo -e "${GREEN}✅ Instance is running!${NC}"
echo ""
echo "New Instance Details:"
echo "  Instance ID: $NEW_INSTANCE_ID"
echo "  Public IP: $PUBLIC_IP"
echo "  Private IP: $PRIVATE_IP"
echo "  Name: $NEW_INSTANCE_NAME"
echo ""

# Step 4: Instructions
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo "1. SSH into new instance:"
echo "   ssh -i your-key.pem ec2-user@$PUBLIC_IP"
echo ""
echo "2. Verify services are running:"
echo "   pm2 status"
echo "   sudo systemctl status nginx"
echo "   curl http://localhost:3000/api/health"
echo ""
echo "3. Update Nginx config for load balancing (see DUPLICATE_EC2_INSTANCE.md)"
echo ""
echo "4. Setup Application Load Balancer (optional, see HIGH_AVAILABILITY_SETUP.md)"
echo ""

echo -e "${GREEN}✅ Done!${NC}"

