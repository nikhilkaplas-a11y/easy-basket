# 🔍 Get Subnet Information

Alternative ways to get subnet and network information.

---

## 🔍 Method 1: Get Subnet ID

### On EC2:

```bash
# Method 1: Direct metadata call
curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/

# Then use the MAC address
MAC=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -1)
echo "MAC: $MAC"
curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/subnet-id
```

### Or simpler:

```bash
# Get all network info
curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | while read mac; do
  echo "MAC: $mac"
  echo "Subnet ID: $(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$mac/subnet-id)"
  echo "VPC ID: $(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$mac/vpc-id)"
done
```

---

## 🔍 Method 2: Use AWS CLI (If Installed)

```bash
# Get instance ID
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "Instance ID: $INSTANCE_ID"

# Get subnet ID
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SubnetId' --output text
```

---

## 🔍 Method 3: From AWS Console

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → **Subnet ID** (click on it)
3. **Subnet details** → Note the **Route table** and **Network ACL**

---

## 🔍 Complete Network Diagnostic

**Run this on EC2:**

```bash
echo "=== Network Information ==="
echo ""
echo "Instance ID:"
curl -s http://169.254.169.254/latest/meta-data/instance-id
echo ""
echo ""
echo "Public IP:"
curl -s http://169.254.169.254/latest/meta-data/public-ipv4
echo ""
echo ""
echo "Private IP:"
curl -s http://169.254.169.254/latest/meta-data/local-ipv4
echo ""
echo ""
echo "MAC Addresses:"
curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/
echo ""
echo ""
echo "Network Info (first interface):"
MAC=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -1 | tr -d '/')
if [ ! -z "$MAC" ]; then
  echo "MAC: $MAC"
  echo "Subnet ID: $(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/subnet-id 2>/dev/null || echo 'Not available')"
  echo "VPC ID: $(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/vpc-id 2>/dev/null || echo 'Not available')"
else
  echo "Could not get MAC address"
fi
echo ""
echo ""
echo "=== Test Connectivity ==="
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Testing: http://$PUBLIC_IP/api/health"
timeout 5 curl -s http://$PUBLIC_IP/api/health 2>&1 | head -3 || echo "TIMEOUT"
```

**Share the complete output.**

---

## 🔍 Alternative: Check Route Table Directly in AWS Console

Since getting subnet ID from metadata is having issues:

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → **Subnet ID** (it's shown there)
3. Click on the **Subnet ID** link
4. **Subnet details** → Note the **Route table** name
5. **VPC** → **Route Tables** → Find that route table
6. **Routes** tab → Check if `0.0.0.0/0` → Internet Gateway exists

---

## 🎯 Quick Check in AWS Console

**Easiest way:**

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → Look for:
   - **Subnet ID:** (click it to see subnet details)
   - **Public IPv4 address:** Should show `13.60.76.140`
3. Click **Subnet ID** → **Route table** tab
4. Click the **Route table** link
5. **Routes** tab → Check for `0.0.0.0/0` → Internet Gateway

**If missing, add it!**

---

**Run the diagnostic script above or check directly in AWS Console! 🔍**

