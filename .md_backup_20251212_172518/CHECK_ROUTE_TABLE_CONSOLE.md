# ✅ Check Route Table in AWS Console

Since metadata service isn't working, check directly in AWS Console.

---

## 🔍 Step 1: Check Route Table (AWS Console)

### Method 1: Via Instance

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → Find **Subnet ID** (e.g., `subnet-xxxxx`)
3. Click on the **Subnet ID** link
4. **Subnet details** → **Route table** tab
5. Click on the **Route table** name
6. **Routes** tab
7. **Check if there's:**
   - `0.0.0.0/0` → Internet Gateway (igw-xxxxx)

**If missing, that's the problem!**

---

## 🔧 Step 2: Fix Route Table

### If Internet Gateway Route is Missing:

1. **VPC** → **Route Tables**
2. Select the route table for your subnet
3. **Routes** tab → **Edit routes**
4. **Add route:**
   - **Destination:** `0.0.0.0/0`
   - **Target:** Select Internet Gateway (should show as `igw-xxxxx`)
5. **Save changes**

**If no Internet Gateway appears in the dropdown:**
- You need to create/attach an Internet Gateway first

---

## 🔍 Step 3: Check Internet Gateway

### In AWS Console:

1. **VPC** → **Internet Gateways**
2. **Check if there's an Internet Gateway**
3. **State** should be **Attached**
4. **VPC** column should show your VPC

**If no Internet Gateway or not attached:**
- Create one and attach it to your VPC

---

## 🔍 Step 4: Verify Instance Configuration

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → Check:
   - **Public IPv4 address:** Should show `13.60.76.140`
   - **Subnet ID:** Note this value
   - **VPC ID:** Note this value

**If "No public IPv4 address":**
- Instance might be in private subnet
- Or auto-assign public IP is disabled

---

## 🔧 Step 5: Complete Fix Sequence

### If Route Table Missing Internet Gateway:

1. **VPC** → **Internet Gateways**
   - If none exists: **Create internet gateway** → **Create**
   - **Actions** → **Attach to VPC** → Select your VPC → **Attach**

2. **VPC** → **Route Tables**
   - Select route table for your subnet
   - **Routes** → **Edit routes** → **Add route**
   - Destination: `0.0.0.0/0`
   - Target: Internet Gateway (igw-xxxxx)
   - **Save changes**

3. **Wait 30 seconds** for changes to propagate

4. **Test:**
   ```bash
   curl http://13.60.76.140/api/health
   curl http://api.easybasket.in/api/health
   ```

---

## 📋 Quick Checklist

- [ ] Internet Gateway exists and is attached to VPC
- [ ] Route table has `0.0.0.0/0` → Internet Gateway
- [ ] Instance has public IP (`13.60.76.140`)
- [ ] Security group allows HTTP (port 80) ✅ (Already done)
- [ ] Network ACLs allow all traffic ✅ (Already done)

---

## 🎯 Most Likely Issue

**Route table missing internet gateway route.**

**Fix:**
1. VPC → Route Tables
2. Find your subnet's route table
3. Add route: `0.0.0.0/0` → Internet Gateway

---

## 🔍 Alternative: Check via AWS CLI (If Installed)

```bash
# Get instance ID
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Get subnet ID
SUBNET_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SubnetId' --output text)

# Get route table for subnet
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$SUBNET_ID" --query 'RouteTables[0].RouteTableId' --output text)

# Check routes
aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE_ID --query 'RouteTables[0].Routes'
```

---

**Check the route table in AWS Console - that's the easiest way! 🔍**

