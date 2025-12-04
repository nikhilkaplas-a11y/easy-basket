# 🔧 Fix: Timeout Even With Security Group Rule

Security group is correct, but still timing out. Let's check other causes.

---

## 🔍 Step 1: Check Instance Firewall

### On EC2:

```bash
# Check if firewalld is running
sudo systemctl status firewalld

# If active, check rules
sudo firewall-cmd --list-all

# Allow HTTP if needed
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

### Check iptables:

```bash
# Check iptables rules
sudo iptables -L -n -v | grep 80

# If blocking, allow HTTP
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
sudo service iptables save 2>/dev/null || sudo iptables-save > /etc/iptables/rules.v4
```

---

## 🔍 Step 2: Check Network ACLs

### In AWS Console:

1. **VPC** → **Network ACLs**
2. Find the NACL associated with your subnet
3. **Inbound rules** tab
4. Check if there's a rule allowing:
   - **Rule #:** 100 (or any number)
   - **Type:** HTTP (80)
   - **Protocol:** TCP
   - **Port range:** 80
   - **Source:** 0.0.0.0/0
   - **Allow/Deny:** Allow

**If there's a DENY rule for port 80, remove it or add an ALLOW rule with lower number (higher priority).**

---

## 🔍 Step 3: Check Route Table

### In AWS Console:

1. **VPC** → **Route Tables**
2. Find the route table for your subnet
3. **Routes** tab
4. Check if there's:
   - `0.0.0.0/0` → Internet Gateway (for public subnet)
   - Or NAT Gateway (for private subnet)

**If missing internet gateway route, your instance can't receive external traffic.**

---

## 🔍 Step 4: Verify Instance is in Public Subnet

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → Check:
   - **Subnet ID** → Click it
   - **Subnet details** → Check **Route table**
   - **Route table** → Check if it has Internet Gateway route

**If instance is in private subnet:**
- It won't be accessible from internet
- Need to either:
  - Move to public subnet, OR
  - Use NAT Gateway, OR
  - Assign Elastic IP

---

## 🔍 Step 5: Check Instance Has Public IP

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → **Public IPv4 address**

**Should show:** `13.60.76.140`

**If it shows "No public IPv4 address":**
- Instance doesn't have public IP
- Need to assign Elastic IP or enable auto-assign public IP

---

## 🔍 Step 6: Test from EC2 Itself

### On EC2:

```bash
# Test using public IP from EC2
curl http://13.60.76.140/api/health

# Test using domain from EC2
curl http://api.easybasket.in/api/health

# Check what IP the instance sees
curl http://169.254.169.254/latest/meta-data/public-ipv4
```

**If these work from EC2 but not from your local machine, it's a network/routing issue.**

---

## 🔍 Step 7: Check Nginx is Actually Responding

### On EC2:

```bash
# Check Nginx is listening on all interfaces
sudo netstat -tuln | grep :80

# Should show: 0.0.0.0:80 (not 127.0.0.1:80)

# Test with verbose curl
curl -v http://localhost/api/health

# Check Nginx access logs
sudo tail -f /var/log/nginx/easy-basket-access.log

# In another terminal, try accessing from outside
# You should see the request in the log
```

---

## 🔧 Step 8: Complete Diagnostic

**Run this on EC2:**

```bash
echo "=== 1. Public IP ==="
curl -s http://169.254.169.254/latest/meta-data/public-ipv4

echo "=== 2. Firewall status ==="
sudo systemctl status firewalld | head -3

echo "=== 3. Nginx listening ==="
sudo netstat -tuln | grep :80

echo "=== 4. Test locally ==="
curl -s http://localhost/api/health | head -1

echo "=== 5. Test via public IP from EC2 ==="
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
curl -s http://$PUBLIC_IP/api/health | head -1

echo "=== 6. Check iptables ==="
sudo iptables -L -n -v | grep 80 || echo "No iptables rules for port 80"
```

**Share the complete output.**

---

## 🔧 Step 9: Quick Fixes to Try

### Fix 1: Disable Firewall (Temporary Test)

```bash
# Stop firewalld
sudo systemctl stop firewalld

# Test
curl http://13.60.76.140/api/health

# If works, re-enable and add rule
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

### Fix 2: Check and Fix iptables

```bash
# List rules
sudo iptables -L -n -v

# Allow HTTP
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT

# Test
curl http://13.60.76.140/api/health
```

### Fix 3: Verify Subnet is Public

```bash
# Get subnet ID
SUBNET_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -1)/subnet-id)

echo "Subnet ID: $SUBNET_ID"
```

**Then check in AWS Console if this subnet has internet gateway route.**

---

## 🎯 Most Likely Issues

1. **Instance firewall (firewalld/iptables)** → Allow HTTP
2. **Network ACL blocking** → Check VPC Network ACLs
3. **Private subnet** → Instance needs to be in public subnet
4. **No public IP** → Assign Elastic IP or enable auto-assign

---

## 📋 Complete Fix Sequence

```bash
# 1. Check firewall
sudo systemctl status firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

# 2. Check iptables
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT

# 3. Verify Nginx listening
sudo netstat -tuln | grep :80

# 4. Test
curl http://13.60.76.140/api/health
```

---

**Run Step 8 diagnostic and share the output, then we'll fix it! 🔍**

