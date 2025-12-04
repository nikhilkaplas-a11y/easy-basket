# 🔧 Test From Your Local Machine

The timeout from EC2 to its own public IP is expected in some AWS configurations. Test from your local machine instead.

---

## 🔍 Step 1: Test From Your Local Machine

### From Your Mac:

```bash
# Test with IP
echo "=== Test with IP ==="
curl -v http://13.60.76.140/api/health 2>&1 | head -20

# Test with domain
echo ""
echo "=== Test with domain ==="
curl -v http://api.easybasket.in/api/health 2>&1 | head -20
```

**This is the real test - if this works, your domain is working!**

---

## 🔍 Step 2: Check Port Connectivity

### From Your Mac:

```bash
# Check if port 80 is open
nc -zv 13.60.76.140 80

# Or with timeout
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/13.60.76.140/80' && echo "Port 80 is open" || echo "Port 80 is closed/filtered"
```

**If port 80 is closed, there's still a firewall/security issue.**

---

## 🔍 Step 3: Verify Everything is Correct

### On EC2:

```bash
echo "=== 1. Backend status ==="
pm2 status | grep easy-basket-api

echo ""
echo "=== 2. Backend test ==="
curl -s http://localhost:3000/api/health | head -1

echo ""
echo "=== 3. Nginx test ==="
curl -s http://localhost/api/health | head -1

echo ""
echo "=== 4. Nginx server_name ==="
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name

echo ""
echo "=== 5. Nginx listening ==="
sudo netstat -tuln | grep :80

echo ""
echo "=== 6. Nginx status ==="
sudo systemctl status nginx | head -5
```

**All should show working/online.**

---

## 🔍 Step 4: Monitor Nginx Logs While Testing

### On EC2 (Terminal 1):

```bash
# Monitor access logs
sudo tail -f /var/log/nginx/easy-basket-access.log
```

### From Your Mac (Terminal 2):

```bash
# Try accessing
curl http://api.easybasket.in/api/health
```

**Check if the request appears in the access log on EC2. If it does, Nginx is receiving the request but not responding correctly.**

---

## 🎯 Expected Results

### From Your Local Machine:

```bash
curl http://13.60.76.140/api/health
# Should return: {"status":"ok","message":"Easy Basket Backend is running",...}

curl http://api.easybasket.in/api/health
# Should return: {"status":"ok","message":"Easy Basket Backend is running",...}
```

---

## 🔍 If Still Timing Out From Local Machine

### Check Security Group One More Time:

1. **EC2** → **Instances** → Select your instance
2. **Security** tab → **Security groups** → Click security group
3. **Inbound rules** tab
4. **Verify:**
   - **Type:** HTTP
   - **Port:** 80
   - **Source:** `0.0.0.0/0`
   - **Status:** Active (green checkmark)

**Make sure the rule is actually active and not disabled.**

---

## 🔍 Alternative: Test With Browser

1. Open browser
2. Go to: `http://api.easybasket.in/api/health`
3. Should see JSON response

**If browser shows timeout/connection refused, there's still a network issue.**

---

## 📋 Complete Verification Checklist

- [ ] Backend running (`pm2 status`)
- [ ] Backend responds locally (`curl http://localhost:3000/api/health`)
- [ ] Nginx responds locally (`curl http://localhost/api/health`)
- [ ] Nginx server_name includes domain
- [ ] Nginx listening on 0.0.0.0:80
- [ ] Security group allows HTTP from 0.0.0.0/0
- [ ] Network ACLs allow all traffic
- [ ] Route table has internet gateway
- [ ] **Test from local machine works** ← This is the real test!

---

**Test from your local machine (Mac) - that's the real test! 🔍**

