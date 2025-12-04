# 🔧 Test With Known IP

Public IP metadata isn't working. Let's test with the known IP directly.

---

## 🔍 Step 1: Test With Known IP

### On EC2:

```bash
# Test with known public IP
echo "Testing with known IP: 13.60.76.140"
timeout 10 curl -v http://13.60.76.140/api/health 2>&1 | head -20

# Test domain
echo ""
echo "Testing domain:"
timeout 10 curl -v http://api.easybasket.in/api/health 2>&1 | head -20
```

**This will tell us if:**
- It works from EC2 → Issue is external network/firewall
- It times out from EC2 → Issue is Nginx/backend

---

## 🔍 Step 2: Verify Nginx server_name

### On EC2:

```bash
# Check current config
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

## 🔍 Step 3: Check Nginx is Listening Correctly

### On EC2:

```bash
# Check what Nginx is listening on
sudo netstat -tuln | grep :80

# Should show: 0.0.0.0:80 (listening on all interfaces)

# Check Nginx status
sudo systemctl status nginx | head -10
```

---

## 🔍 Step 4: Test All Endpoints

### On EC2:

```bash
echo "=== 1. Backend direct ==="
curl -s http://localhost:3000/api/health | head -1

echo ""
echo "=== 2. Nginx localhost ==="
curl -s http://localhost/api/health | head -1

echo ""
echo "=== 3. Nginx via IP (from EC2) ==="
timeout 5 curl -s http://13.60.76.140/api/health 2>&1 | head -3

echo ""
echo "=== 4. Nginx via domain (from EC2) ==="
timeout 5 curl -s http://api.easybasket.in/api/health 2>&1 | head -3
```

**Share complete output.**

---

## 🔍 Step 5: Monitor Nginx Logs

### On EC2:

```bash
# Clear and monitor access logs
sudo truncate -s 0 /var/log/nginx/easy-basket-access.log
sudo tail -f /var/log/nginx/easy-basket-access.log
```

**In another terminal, try accessing:**
```bash
curl http://13.60.76.140/api/health
```

**Check if request appears in logs. If not, traffic isn't reaching Nginx.**

---

## 🔍 Step 6: Check Error Logs

### On EC2:

```bash
# Check recent errors
sudo tail -20 /var/log/nginx/easy-basket-error.log

# Check main error log
sudo tail -20 /var/log/nginx/error.log
```

---

## 🎯 Most Likely Issues

1. **Nginx server_name doesn't include IP/domain** → Update config
2. **Nginx not listening on all interfaces** → Check netstat
3. **Some other network layer blocking** → Check all layers

---

## 📋 Complete Test Sequence

**Run this on EC2:**

```bash
echo "=== Complete Test ==="
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
echo "4. Nginx listening:"
sudo netstat -tuln | grep :80
echo ""
echo "5. Test via IP from EC2:"
timeout 5 curl -s http://13.60.76.140/api/health 2>&1 | head -3
echo ""
echo "6. Test via domain from EC2:"
timeout 5 curl -s http://api.easybasket.in/api/health 2>&1 | head -3
```

**Share the complete output.**

---

**Test with the known IP (13.60.76.140) and share the results! 🔍**

