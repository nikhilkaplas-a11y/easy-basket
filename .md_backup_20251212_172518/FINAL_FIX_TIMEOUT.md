# 🔧 Final Fix: Timeout From Local Machine

Everything looks correct but still timing out. Let's do a final comprehensive check.

---

## 🔍 Step 1: Double-Check Security Group

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Security** tab → **Security groups** → Click the security group name
3. **Inbound rules** tab
4. **Verify EXACTLY:**
   - **Type:** HTTP
   - **Protocol:** TCP
   - **Port range:** 80
   - **Source:** `0.0.0.0/0` (not `::/0` or anything else)
   - **Status:** Should show a green checkmark (Active)

**If rule exists but status shows inactive, delete and recreate it.**

### Delete and Recreate Rule:

1. **Edit inbound rules**
2. **Delete** the HTTP rule
3. **Save changes**
4. **Edit inbound rules** again
5. **Add rule:**
   - Type: HTTP
   - Port: 80
   - Source: 0.0.0.0/0
6. **Save changes**
7. **Wait 30 seconds** for propagation

---

## 🔍 Step 2: Check Instance Source/Destination Check

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Networking** tab → **Actions** → **Change source/destination check**
3. **Should be:** Unchecked (disabled)
4. **If checked, uncheck it and save**

**This allows the instance to receive traffic not destined for its own IP.**

---

## 🔍 Step 3: Verify Instance is in Public Subnet

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → **Subnet ID** → Click it
3. **Subnet details** → Check:
   - **Auto-assign public IPv4 address:** Should be `Yes`
   - **Route table:** Should have internet gateway route

**If auto-assign is `No`, enable it:**
1. **VPC** → **Subnets** → Select your subnet
2. **Actions** → **Edit subnet settings**
3. **Enable auto-assign public IPv4 address**
4. **Save**

---

## 🔍 Step 4: Test Port Connectivity

### From Your Mac:

```bash
# Test if port 80 is reachable
nc -zv -w 5 13.60.76.140 80

# Or
telnet 13.60.76.140 80
```

**If connection refused or timeout, port 80 is blocked.**

---

## 🔧 Step 5: Complete Security Group Reset

### In AWS Console:

1. **EC2** → **Security Groups** → Select your security group
2. **Inbound rules** tab → **Edit inbound rules**
3. **Delete ALL rules** (temporarily)
4. **Add these rules:**
   - **SSH (22)** from `0.0.0.0/0` (for access)
   - **HTTP (80)** from `0.0.0.0/0`
   - **HTTPS (443)** from `0.0.0.0/0` (optional)
5. **Save changes**
6. **Wait 30 seconds**

---

## 🔍 Step 6: Check for Multiple Security Groups

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Security** tab → **Security groups**
3. **Check if instance has MULTIPLE security groups**

**If multiple groups:**
- Check ALL of them have HTTP (80) rule
- Or remove unnecessary groups

---

## 🔍 Step 7: Verify Nginx Config One More Time

### On EC2:

```bash
# Check complete config
sudo cat /etc/nginx/conf.d/easy-basket.conf

# Should show:
# server {
#     listen 80 default_server;
#     server_name api.easybasket.in localhost 13.60.76.140 _;
#     ...
# }

# Test config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx | head -10
```

---

## 🔍 Step 8: Check if Instance Has Elastic IP

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Details** tab → **Elastic IPs**

**If instance has Elastic IP but public IP shows different:**
- The Elastic IP might not be associated
- Or there's a mismatch

---

## 🔧 Step 9: Nuclear Option - Recreate Security Group Rule

### In AWS Console:

1. **EC2** → **Security Groups** → Select your security group
2. **Inbound rules** → **Edit inbound rules**
3. **Delete HTTP rule completely**
4. **Save**
5. **Wait 10 seconds**
6. **Edit inbound rules** again
7. **Add rule:**
   - **Type:** Custom TCP
   - **Protocol:** TCP
   - **Port range:** 80
   - **Source:** Custom → `0.0.0.0/0`
   - **Description:** `Allow HTTP from anywhere`
8. **Save changes**
9. **Wait 30 seconds**

---

## 🔍 Step 10: Test From Different Location

### Try from different network:

1. Use your phone's mobile data (not WiFi)
2. Or use online tools:
   - https://www.yougetsignal.com/tools/open-ports/
   - Enter: `13.60.76.140` and port `80`

**If it works from different network, it's your local network/firewall blocking.**

---

## 📋 Complete Final Checklist

- [ ] Security group HTTP rule is ACTIVE (green checkmark)
- [ ] Security group source is exactly `0.0.0.0/0`
- [ ] Source/destination check is DISABLED
- [ ] Instance is in public subnet
- [ ] Auto-assign public IP is enabled
- [ ] Route table has internet gateway
- [ ] Network ACLs allow all traffic
- [ ] Nginx is running and listening on 0.0.0.0:80
- [ ] Backend is running
- [ ] Tested from different network (to rule out local firewall)

---

## 🎯 Most Likely Final Issues

1. **Security group rule not actually active** → Delete and recreate
2. **Source/destination check enabled** → Disable it
3. **Instance in private subnet** → Move to public subnet
4. **Local network firewall** → Test from different network

---

**Try Step 1 (double-check security group) and Step 2 (disable source/destination check) first! 🔧**

