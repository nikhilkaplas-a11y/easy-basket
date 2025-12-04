# ✅ Final Connectivity Test

Route table is correct! Let's test connectivity from EC2 itself.

---

## 🔍 Step 1: Test from EC2 Using Public IP

### On EC2:

```bash
# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Public IP: $PUBLIC_IP"

# Test from EC2 using public IP
echo "Testing from EC2:"
timeout 10 curl -v http://$PUBLIC_IP/api/health 2>&1 | head -20

# Test domain from EC2
echo "Testing domain from EC2:"
timeout 10 curl -v http://api.easybasket.in/api/health 2>&1 | head -20
```

**Share the output. This will tell us if:**
- It works from EC2 → Issue is external network
- It times out from EC2 → Issue is Nginx/backend config

---

## 🔍 Step 2: Verify Nginx server_name

### On EC2:

```bash
# Check current server_name
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name

# Should show: server_name api.easybasket.in localhost 13.60.76.140 _;
```

**If it only shows `server_name _;`, update it:**

```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Change to:**
```nginx
    server_name api.easybasket.in localhost 13.60.76.140 _;
```

**Save and reload:**
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔍 Step 3: Check Nginx Access Logs

### On EC2:

```bash
# Monitor access logs in real-time
sudo tail -f /var/log/nginx/easy-basket-access.log

# In another terminal, try accessing from your local machine:
# curl http://api.easybasket.in/api/health

# Check if request appears in logs
```

**If no request appears in logs, traffic isn't reaching Nginx.**

---

## 🔍 Step 4: Test All Endpoints

### On EC2:

```bash
echo "=== 1. Backend direct ==="
curl -s http://localhost:3000/api/health | head -1

echo "=== 2. Nginx localhost ==="
curl -s http://localhost/api/health | head -1

echo "=== 3. Nginx via public IP (from EC2) ==="
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
timeout 5 curl -s http://$PUBLIC_IP/api/health 2>&1 | head -3

echo "=== 4. Nginx via domain (from EC2) ==="
timeout 5 curl -s http://api.easybasket.in/api/health 2>&1 | head -3
```

**Share complete output.**

---

## 🔍 Step 5: Check if Port 80 is Actually Open

### From Your Local Machine:

```bash
# Test if port 80 is reachable
nc -zv 13.60.76.140 80

# Or with timeout
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/13.60.76.140/80' && echo "Port 80 is open" || echo "Port 80 is closed/filtered"
```

**If port 80 is closed, there's still a firewall/security issue.**

---

## 🔍 Step 6: Verify Security Group One More Time

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Security** tab → **Security groups** → Click security group
3. **Inbound rules** tab
4. **Verify:**
   - Type: HTTP
   - Port: 80
   - Source: 0.0.0.0/0
   - Status: Active

**Double-check the rule is actually active and not disabled.**

---

## 🎯 Most Likely Remaining Issues

1. **Nginx server_name doesn't include domain** → Update config
2. **Security group rule not active** → Check status
3. **Some other firewall/security layer** → Check all layers

---

## 📋 Complete Test Sequence

**Run this on EC2:**

```bash
echo "=== Complete Connectivity Test ==="
echo ""
echo "1. Backend:"
curl -s http://localhost:3000/api/health | head -1
echo ""
echo "2. Nginx localhost:"
curl -s http://localhost/api/health | head -1
echo ""
echo "3. Nginx server_name:"
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name
echo ""
echo "4. Public IP:"
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "$PUBLIC_IP"
echo ""
echo "5. Test from EC2 via public IP:"
timeout 5 curl -s http://$PUBLIC_IP/api/health 2>&1 | head -3
echo ""
echo "6. Test from EC2 via domain:"
timeout 5 curl -s http://api.easybasket.in/api/health 2>&1 | head -3
```

**Share the complete output.**

---

**Run Step 1 test first - that will tell us if it's an external connectivity issue or Nginx config! 🔍**

