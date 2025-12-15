# Quick Guide: Duplicate Your EC2 Instance

## 🎯 Goal
Create an identical copy of your current EC2 instance for high availability.

---

## Method 1: AWS Console (Easiest - 10 minutes)

### Step 1: Create AMI (5 minutes)

1. **AWS Console** → **EC2** → **Instances**
2. **Select your instance** (the one running backend)
3. **Actions** → **Image and templates** → **Create image**
4. **Fill in:**
   - **Name:** `easy-basket-backend-v1`
   - **Description:** `Backend server backup`
   - **No reboot:** ❌ **Uncheck** (let it reboot)
5. **Create image**
6. **Wait 5-15 minutes** for status to become "Available"

### Step 2: Launch New Instance (2 minutes)

1. **EC2** → **AMIs** → **Select your AMI**
2. **Launch instance from AMI**
3. **Configure:**
   - **Name:** `easy-basket-backend-2`
   - **Instance type:** Same as original
   - **Key pair:** Same key
   - **Network:** Same VPC, different subnet (or same)
   - **Security group:** Same security group
4. **Launch instance**

### Step 3: Get New Instance IP

1. **EC2** → **Instances**
2. **Find your new instance**
3. **Copy Public IP**

### Step 4: Verify New Instance

```bash
# SSH into new instance
ssh -i your-key.pem ec2-user@<new-instance-ip>

# Check services
pm2 status
sudo systemctl status nginx
curl http://localhost:3000/api/health
```

---

## Method 2: Automated Script (Fastest)

**From your Mac (requires AWS CLI):**

```bash
# Make sure AWS CLI is configured
aws configure

# Run the script
cd /Users/nikhil/Projects/easyBucket
./create-duplicate-instance.sh

# Follow the prompts
```

The script will:
- ✅ Find your instance
- ✅ Create AMI automatically
- ✅ Wait for AMI to be ready
- ✅ Launch new instance
- ✅ Give you the IP addresses

---

## Method 3: AWS CLI Commands (Manual)

```bash
# 1. Get your instance ID
aws ec2 describe-instances \
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0]]" \
  --output table

# 2. Create AMI (replace INSTANCE_ID)
AMI_ID=$(aws ec2 create-image \
  --instance-id i-xxxxxxxxxxxxx \
  --name "easy-basket-backend-$(date +%Y%m%d)" \
  --no-reboot \
  --query 'ImageId' \
  --output text)

echo "AMI ID: $AMI_ID"

# 3. Wait for AMI (check every 30 seconds)
aws ec2 wait image-available --image-ids $AMI_ID

# 4. Get instance details
INSTANCE_TYPE=$(aws ec2 describe-instances --instance-ids i-xxx --query "Reservations[*].Instances[*].InstanceType" --output text)
KEY_NAME=$(aws ec2 describe-instances --instance-ids i-xxx --query "Reservations[*].Instances[*].KeyName" --output text)
SG_ID=$(aws ec2 describe-instances --instance-ids i-xxx --query "Reservations[*].Instances[*].SecurityGroups[0].GroupId" --output text)
SUBNET_ID=$(aws ec2 describe-instances --instance-ids i-xxx --query "Reservations[*].Instances[*].SubnetId" --output text)

# 5. Launch new instance
aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=easy-basket-backend-2}]'
```

---

## After Creating Duplicate Instance

### 1. Verify Everything Works

```bash
# SSH into new instance
ssh -i your-key.pem ec2-user@<new-ip>

# Check services
pm2 status          # Should show backend running
sudo systemctl status nginx
curl http://localhost:3000/api/health
```

### 2. Setup Load Balancing

**Option A: Update Nginx on Both Instances**

Get private IPs of both instances, then update Nginx config on each:

```bash
# On Instance 1
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Add instance 2's private IP to upstream

# On Instance 2  
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Add instance 1's private IP to upstream
```

**Option B: Use AWS Application Load Balancer** (Recommended)

See `HIGH_AVAILABILITY_SETUP.md` for ALB setup.

### 3. Test Failover

```bash
# Stop one instance
aws ec2 stop-instances --instance-ids i-xxx

# Verify other instance still handles traffic
curl https://api.easybasket.in/api/health

# Start instance again
aws ec2 start-instances --instance-ids i-xxx
```

---

## Cost Estimate

- **Current:** 1 instance = ~$7-10/month
- **After duplication:** 2 instances = ~$14-20/month
- **ALB (optional):** +$16/month

**Total with ALB:** ~$30-36/month for high availability

---

## Quick Checklist

- [ ] AMI created and available
- [ ] New instance launched
- [ ] Can SSH into new instance
- [ ] PM2 running on new instance
- [ ] Nginx running on new instance
- [ ] API health check works
- [ ] Database connection works (same RDS)
- [ ] Load balancing configured
- [ ] Failover tested

---

## Troubleshooting

### AMI Creation Takes Too Long
- Normal: 5-15 minutes
- Large instances: Up to 30 minutes
- Check AMI status in console

### New Instance Can't Connect to Database
- Check security group allows outbound to RDS (port 3306)
- Check RDS security group allows inbound from new instance
- Verify .env has correct RDS endpoint

### Services Not Running on New Instance
- SSH and check: `pm2 status`, `sudo systemctl status nginx`
- May need to restart: `pm2 restart all`, `sudo systemctl restart nginx`

---

## Next Steps

1. ✅ **Setup load balancing** (see `HIGH_AVAILABILITY_SETUP.md`)
2. ✅ **Configure ALB** (for true high availability)
3. ✅ **Test deployments** (deploy to both instances)
4. ✅ **Setup monitoring** (CloudWatch alarms)

See `DUPLICATE_EC2_INSTANCE.md` for detailed guide.

