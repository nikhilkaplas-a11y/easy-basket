# 🔧 Fix: Amazon Linux 2023 - nftables & Network ACLs

Amazon Linux 2023 uses nftables, not iptables. Also check Network ACLs.

---

## 🔍 Step 1: Check nftables

### On EC2:

```bash
# Check if nftables is installed
which nft

# List current rules
sudo nft list ruleset

# Check INPUT chain
sudo nft list chain inet filter INPUT 2>/dev/null || echo "No custom INPUT chain"
```

---

## 🔍 Step 2: Allow HTTP in nftables (If Needed)

```bash
# Add HTTP rule
sudo nft add rule inet filter INPUT tcp dport 80 accept

# Verify
sudo nft list chain inet filter INPUT

# Test
curl http://13.60.76.140/api/health
```

**Note:** On Amazon Linux 2023, nftables might not be blocking by default. The issue is likely Network ACLs.

---

## 🔍 Step 3: Check Network ACLs (Most Likely Issue!)

### In AWS Console:

1. **VPC** → **Network ACLs**
2. Find the NACL associated with your subnet
3. **Inbound rules** tab
4. Check if there's a rule allowing port 80

**Network ACLs are stateless firewall rules at the subnet level.**

**You need BOTH:**
- **Inbound rule:** Allow TCP port 80 from 0.0.0.0/0
- **Outbound rule:** Allow TCP ephemeral ports (1024-65535) to 0.0.0.0/0

**If there's a DENY rule with higher priority (lower rule number), it will block traffic.**

---

## 🔧 Step 4: Fix Network ACLs

### In AWS Console:

1. **VPC** → **Network ACLs**
2. Select the NACL for your subnet
3. **Inbound rules** tab → **Edit inbound rules**
4. **Add rule:**
   - **Rule #:** 100
   - **Type:** Custom TCP
   - **Protocol:** TCP
   - **Port range:** 80
   - **Source:** 0.0.0.0/0
   - **Allow/Deny:** Allow
5. **Save changes**

6. **Outbound rules** tab → **Edit outbound rules**
7. **Add rule (if not exists):**
   - **Rule #:** 100
   - **Type:** Custom TCP
   - **Protocol:** TCP
   - **Port range:** 1024-65535 (ephemeral ports)
   - **Destination:** 0.0.0.0/0
   - **Allow/Deny:** Allow
8. **Save changes**

---

## 🔍 Step 5: Verify Subnet Route Table

### In AWS Console:

1. **VPC** → **Route Tables**
2. Find the route table for your subnet
3. **Routes** tab
4. Should have: `0.0.0.0/0` → Internet Gateway

**If missing, your instance is in a private subnet.**

---

## 🔍 Step 6: Complete Diagnostic

**Run this on EC2:**

```bash
echo "=== 1. Public IP ==="
curl -s http://169.254.169.254/latest/meta-data/public-ipv4

echo "=== 2. Subnet ID ==="
curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -1)/subnet-id

echo "=== 3. nftables ==="
sudo nft list ruleset 2>/dev/null | head -20 || echo "nftables not configured"

echo "=== 4. Nginx listening ==="
sudo netstat -tuln | grep :80

echo "=== 5. Test locally ==="
curl -s http://localhost/api/health | head -1

echo "=== 6. Test via public IP from EC2 ==="
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
timeout 5 curl -v http://$PUBLIC_IP/api/health 2>&1 | head -15 || echo "TIMEOUT"
```

**Share the complete output, especially Subnet ID.**

---

## 🎯 Most Likely Issue: Network ACLs

**Network ACLs are the most common cause when:**
- Security group is correct ✅
- No local firewall (no firewalld/iptables) ✅
- Still timing out ❌

**Network ACLs work at the subnet level and can block traffic even if security groups allow it.**

---

## 🔧 Step 7: Quick Fix - Network ACLs

### In AWS Console:

1. **VPC** → **Network ACLs**
2. Find NACL for your subnet (check Subnet ID from diagnostic)
3. **Inbound rules:**
   - Rule #100: Allow TCP 80 from 0.0.0.0/0
4. **Outbound rules:**
   - Rule #100: Allow TCP 1024-65535 to 0.0.0.0/0

**Default Network ACLs usually allow all traffic, but custom NACLs might block.**

---

## 📋 Complete Fix Checklist

- [ ] Security group allows HTTP (port 80) ✅ (Already done)
- [ ] Network ACL inbound allows TCP 80 from 0.0.0.0/0
- [ ] Network ACL outbound allows TCP ephemeral ports to 0.0.0.0/0
- [ ] Route table has internet gateway route
- [ ] Instance is in public subnet
- [ ] Instance has public IP

---

## 🔍 How to Find Your Network ACL

### From EC2:

```bash
# Get subnet ID
SUBNET_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -1)/subnet-id)

echo "Subnet ID: $SUBNET_ID"
```

**Then in AWS Console:**
1. **VPC** → **Subnets**
2. Find subnet with this ID
3. **Network ACL** column shows the NACL
4. Click on it to view/edit rules

---

## ✅ Expected Result

After fixing Network ACLs:

```bash
# From your local machine
curl http://13.60.76.140/api/health
# Should return JSON

curl http://api.easybasket.in/api/health
# Should return JSON
```

---

**Check Network ACLs in AWS Console - that's most likely the issue! 🔍**

