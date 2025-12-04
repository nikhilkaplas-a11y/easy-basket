# 🔧 Fix: Security Group Blocking Port 80

The timeout means your security group is blocking external access to port 80.

---

## 🔍 Step 1: Check Current Security Group

### In AWS Console:

1. **EC2** → **Instances** → Select your instance (`i-xxxxx`)
2. **Security** tab → Click on the **Security group** name (e.g., `launch-wizard-1`)
3. **Inbound rules** tab

**Check if you have:**
- **Type:** HTTP
- **Port:** 80
- **Source:** `0.0.0.0/0`

**If missing or different, we need to add/fix it.**

---

## 🔧 Step 2: Add HTTP Rule to Security Group

### Option A: Via AWS Console (Recommended)

1. **EC2** → **Security Groups** → Select your security group
2. **Inbound rules** tab → **Edit inbound rules**
3. **Add rule:**
   - **Type:** HTTP
   - **Protocol:** TCP
   - **Port range:** 80
   - **Source:** `0.0.0.0/0` (or `Custom` → `0.0.0.0/0`)
   - **Description:** `Allow HTTP from anywhere` (optional)
4. **Save rules**

### Option B: Via AWS CLI (If you have it installed)

```bash
# Get your security group ID
SG_ID=$(aws ec2 describe-instances --instance-ids $(curl -s http://169.254.169.254/latest/meta-data/instance-id) --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)

# Add HTTP rule
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
```

---

## 🔍 Step 3: Verify Security Group

### In AWS Console:

After adding the rule, check:

1. **Security Groups** → Your security group → **Inbound rules**
2. **Should see:**
   ```
   Type      Protocol  Port range  Source        Description
   HTTP      TCP       80          0.0.0.0/0    Allow HTTP from anywhere
   HTTPS     TCP       443         0.0.0.0/0    (if you have it)
   SSH       TCP       22          0.0.0.0/0    (if you have it)
   ```

---

## 🧪 Step 4: Test After Fix

### From Your Local Machine:

```bash
# Test IP directly
curl http://13.60.76.140/api/health

# Test domain
curl http://api.easybasket.in/api/health
```

**Should return JSON now!**

---

## 🔍 Step 5: Check Network ACLs (If Still Not Working)

If security group is correct but still timing out:

1. **VPC** → **Network ACLs**
2. Find the NACL for your subnet
3. **Inbound rules** should allow:
   - **Rule #:** 100
   - **Type:** HTTP (80)
   - **Protocol:** TCP
   - **Port range:** 80
   - **Source:** 0.0.0.0/0
   - **Allow/Deny:** Allow

**Usually NACLs are permissive by default, but check if you have custom rules.**

---

## 🔍 Step 6: Check Route Table

1. **VPC** → **Route Tables**
2. Find the route table for your subnet
3. **Routes** should have:
   - `0.0.0.0/0` → Internet Gateway (for public subnet)
   - Or NAT Gateway (for private subnet)

**If your instance is in a private subnet, it won't be accessible from the internet.**

---

## 📋 Complete Checklist

- [ ] Security group has HTTP (port 80) inbound rule
- [ ] Source is `0.0.0.0/0` (allows from anywhere)
- [ ] Instance is in a public subnet (has public IP)
- [ ] Route table has internet gateway route
- [ ] Network ACL allows HTTP (usually default allows all)

---

## 🎯 Quick Fix Steps

1. **AWS Console** → **EC2** → **Security Groups**
2. **Select your security group**
3. **Inbound rules** → **Edit inbound rules**
4. **Add rule:**
   - Type: **HTTP**
   - Port: **80**
   - Source: **0.0.0.0/0**
5. **Save rules**
6. **Wait 10-30 seconds** (for rule to propagate)
7. **Test:** `curl http://13.60.76.140/api/health`

---

## 🔍 Verify Instance Has Public IP

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → Check **Public IPv4 address**
3. **Should show:** `13.60.76.140` (your IP)

**If it shows "No public IPv4 address":**
- Your instance is in a private subnet
- Need to either:
  - Move to public subnet, OR
  - Assign Elastic IP, OR
  - Use NAT Gateway

---

## ✅ Expected Result

After fixing security group:

```bash
# From your local machine
curl http://13.60.76.140/api/health
# Should return: {"status":"ok",...}

curl http://api.easybasket.in/api/health
# Should return: {"status":"ok",...}
```

---

**Add the HTTP rule to your security group and test again! 🔧**

