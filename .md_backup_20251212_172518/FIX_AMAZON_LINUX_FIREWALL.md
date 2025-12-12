# 🔧 Fix: Amazon Linux 2023 - No Firewalld

Amazon Linux 2023 doesn't use firewalld by default. Let's check other causes.

---

## 🔍 Step 1: Check iptables

### On EC2:

```bash
# Check iptables rules
sudo iptables -L -n -v

# Check specifically for port 80
sudo iptables -L -n -v | grep 80

# Check INPUT chain
sudo iptables -L INPUT -n -v
```

**If there are restrictive rules, we need to allow HTTP.**

---

## 🔍 Step 2: Allow HTTP in iptables (If Needed)

```bash
# Allow HTTP traffic
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT

# Verify rule was added
sudo iptables -L INPUT -n -v | grep 80

# Test
curl http://13.60.76.140/api/health
```

**Note:** On Amazon Linux 2023, iptables rules might not persist after reboot. If this fixes it, we'll make it persistent.

---

## 🔍 Step 3: Check Network ACLs in AWS

### In AWS Console:

1. **VPC** → **Network ACLs**
2. Find the NACL associated with your subnet
3. **Inbound rules** tab
4. Check if there's a rule allowing port 80

**Network ACLs are stateless, so you need both inbound AND outbound rules.**

**Check:**
- **Inbound:** Allow TCP port 80 from 0.0.0.0/0
- **Outbound:** Allow TCP ephemeral ports (1024-65535) to 0.0.0.0/0

---

## 🔍 Step 4: Verify Route Table

### In AWS Console:

1. **VPC** → **Route Tables**
2. Find the route table for your subnet
3. **Routes** tab
4. Should have: `0.0.0.0/0` → Internet Gateway

**If missing, your instance is in a private subnet and won't be accessible from internet.**

---

## 🔍 Step 5: Complete Diagnostic

**Run this on EC2:**

```bash
echo "=== 1. Public IP ==="
curl -s http://169.254.169.254/latest/meta-data/public-ipv4

echo "=== 2. iptables rules ==="
sudo iptables -L INPUT -n -v | head -10

echo "=== 3. Nginx listening ==="
sudo netstat -tuln | grep :80

echo "=== 4. Test locally ==="
curl -s http://localhost/api/health | head -1

echo "=== 5. Test via public IP from EC2 ==="
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
curl -v http://$PUBLIC_IP/api/health 2>&1 | head -15

echo "=== 6. Check if port 80 is accessible ==="
sudo ss -tlnp | grep :80
```

**Share the complete output.**

---

## 🔧 Step 6: Quick Fixes

### Fix 1: Allow HTTP in iptables

```bash
# Add rule
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT

# Verify
sudo iptables -L INPUT -n -v | grep 80

# Test
curl http://13.60.76.140/api/health
```

### Fix 2: Make iptables Rule Persistent (If Fix 1 Works)

```bash
# Save current rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Or on Amazon Linux 2023, might need:
sudo service iptables save 2>/dev/null || sudo iptables-save > /etc/iptables/rules.v4
```

### Fix 3: Check Network ACLs

**In AWS Console:**
1. **VPC** → **Network ACLs**
2. Find your subnet's NACL
3. **Inbound rules:**
   - Rule #100: Allow TCP port 80 from 0.0.0.0/0
4. **Outbound rules:**
   - Rule #100: Allow TCP ephemeral ports (1024-65535) to 0.0.0.0/0

---

## 🔍 Step 7: Test from EC2 Itself

```bash
# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Public IP: $PUBLIC_IP"

# Test from EC2 using public IP
curl -v http://$PUBLIC_IP/api/health

# Test using domain
curl -v http://api.easybasket.in/api/health
```

**If these work from EC2 but not from your local machine, it's definitely a network/firewall issue.**

---

## 🎯 Most Likely Causes

1. **iptables blocking** → Allow HTTP: `sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT`
2. **Network ACL blocking** → Check VPC Network ACLs in AWS Console
3. **Private subnet** → Instance needs to be in public subnet with internet gateway
4. **Route table missing internet gateway** → Add route in VPC

---

## 📋 Complete Fix Sequence

```bash
# 1. Allow HTTP in iptables
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT

# 2. Verify
sudo iptables -L INPUT -n -v | grep 80

# 3. Test
curl http://13.60.76.140/api/health

# 4. If works, make persistent
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

---

## 🔍 Check Network ACLs (AWS Console)

1. **VPC** → **Network ACLs**
2. Find NACL for your subnet
3. **Inbound rules:**
   - Should allow TCP port 80 from 0.0.0.0/0
4. **Outbound rules:**
   - Should allow TCP ephemeral ports to 0.0.0.0/0

**If there's a DENY rule with higher priority, it will block traffic.**

---

**Run Step 5 diagnostic and try Fix 1 (iptables). Share the results! 🔍**

