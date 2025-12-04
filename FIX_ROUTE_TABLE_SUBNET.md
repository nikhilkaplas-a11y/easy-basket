# 🔧 Fix: Check Route Table & Subnet Configuration

Network ACLs are correct. Let's check route table and subnet.

---

## 🔍 Step 1: Get Subnet and Route Table Info

### On EC2:

```bash
echo "=== 1. Subnet ID ==="
SUBNET_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -1)/subnet-id)
echo "$SUBNET_ID"

echo "=== 2. VPC ID ==="
VPC_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -1)/vpc-id)
echo "$VPC_ID"

echo "=== 3. Public IP ==="
curl -s http://169.254.169.254/latest/meta-data/public-ipv4

echo "=== 4. Test from EC2 using public IP ==="
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
timeout 5 curl -v http://$PUBLIC_IP/api/health 2>&1 | head -20
```

**Share the output, especially if the test from EC2 works or times out.**

---

## 🔍 Step 2: Check Route Table in AWS Console

### In AWS Console:

1. **VPC** → **Route Tables**
2. Find the route table associated with your subnet (use Subnet ID from Step 1)
3. **Routes** tab
4. **Check if there's:**
   - `0.0.0.0/0` → Internet Gateway (igw-xxxxx)

**If missing, your instance is in a private subnet and won't be accessible from internet.**

---

## 🔍 Step 3: Check Subnet Configuration

### In AWS Console:

1. **VPC** → **Subnets**
2. Find your subnet (using Subnet ID from Step 1)
3. **Details** tab → Check:
   - **Auto-assign public IPv4 address:** Should be `Yes` (or instance has Elastic IP)
   - **Route table:** Should have internet gateway route

---

## 🔧 Step 4: Verify Instance Has Public IP

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → **Public IPv4 address**

**Should show:** `13.60.76.140`

**If it shows "No public IPv4 address":**
- Instance doesn't have public IP
- Need to either:
  - Assign Elastic IP, OR
  - Enable auto-assign public IP on subnet

---

## 🔧 Step 5: Test Connectivity from EC2

### On EC2:

```bash
# Test if instance can reach itself via public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Testing: http://$PUBLIC_IP/api/health"

# Test with timeout
timeout 10 curl -v http://$PUBLIC_IP/api/health 2>&1

# Also test domain
timeout 10 curl -v http://api.easybasket.in/api/health 2>&1
```

**If these work from EC2 but not from your local machine, it's a routing/network issue.**

---

## 🔍 Step 6: Check Internet Gateway

### In AWS Console:

1. **VPC** → **Internet Gateways**
2. Check if there's an Internet Gateway attached to your VPC
3. If not, you need to create and attach one

---

## 🎯 Most Likely Issues

1. **No Internet Gateway route** → Route table missing `0.0.0.0/0` → Internet Gateway
2. **Instance in private subnet** → No public IP or no internet gateway route
3. **Internet Gateway not attached** → VPC doesn't have internet gateway

---

## 🔧 Step 7: Fix Route Table

### If Route Table Missing Internet Gateway:

1. **VPC** → **Route Tables**
2. Select route table for your subnet
3. **Routes** tab → **Edit routes**
4. **Add route:**
   - **Destination:** `0.0.0.0/0`
   - **Target:** Select Internet Gateway (igw-xxxxx)
5. **Save changes**

---

## 🔧 Step 8: Assign Elastic IP (If No Public IP)

### In AWS Console:

1. **EC2** → **Elastic IPs** → **Allocate Elastic IP address**
2. **Allocate**
3. **Actions** → **Associate Elastic IP address**
4. **Instance:** Select your instance
5. **Associate**

**Then update your DNS A record to point to the new Elastic IP.**

---

## 📋 Complete Checklist

- [ ] Security group allows HTTP (port 80) ✅
- [ ] Network ACLs allow all traffic ✅
- [ ] Route table has internet gateway route
- [ ] Internet Gateway is attached to VPC
- [ ] Instance has public IP (13.60.76.140)
- [ ] Subnet has auto-assign public IP enabled (or Elastic IP assigned)

---

## 🔍 Quick Diagnostic

**Run this on EC2:**

```bash
echo "=== Complete Network Info ==="
echo "Subnet ID: $(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -1)/subnet-id)"
echo "VPC ID: $(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -1)/vpc-id)"
echo "Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
echo ""
echo "=== Test from EC2 ==="
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
timeout 5 curl -s http://$PUBLIC_IP/api/health 2>&1 | head -3 || echo "TIMEOUT from EC2"
```

**Share the output.**

---

**Check the route table in AWS Console - that's most likely the issue! 🔍**

