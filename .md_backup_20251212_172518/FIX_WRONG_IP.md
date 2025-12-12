# ✅ Fix: Wrong IP Address

Your instance has a different IP: `13.62.13.171` (not `13.60.76.140`)

---

## 🔍 The Issue

- **Instance Public IP:** `13.62.13.171`
- **Elastic IP:** `13.62.13.171`
- **DNS A record:** Probably pointing to `13.60.76.140` (old/wrong IP)

---

## 🔧 Step 1: Update DNS in GoDaddy

### In GoDaddy:

1. **Log in** to GoDaddy
2. **My Products** → **DNS** (or **Manage DNS**)
3. **Find the A record** for `api` (for api.easybasket.in)
4. **Edit the record:**
   - **Name:** `api`
   - **Type:** A
   - **Value:** Change from `13.60.76.140` to `13.62.13.171`
   - **TTL:** 300 (or 3600)
5. **Save**

---

## 🧪 Step 2: Test With Correct IP

### From Your Mac:

```bash
# Test with correct IP
curl -v http://13.62.13.171/api/health 2>&1 | head -20

# Test with domain (after DNS propagates)
curl -v http://api.easybasket.in/api/health 2>&1 | head -20
```

**Should work now with the correct IP!**

---

## 🔧 Step 3: Update Nginx Config (If Needed)

### On EC2:

```bash
# Check current server_name
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name

# Update if needed
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Ensure server_name includes the new IP:**
```nginx
    server_name api.easybasket.in localhost 13.62.13.171 _;
```

**Save and reload:**
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔍 Step 4: Wait for DNS Propagation

After updating DNS in GoDaddy:
- **Wait 15-30 minutes** for DNS to propagate
- Or test immediately with the IP: `13.62.13.171`

---

## ✅ Verification

### From Your Mac:

```bash
# Test with new IP (should work immediately)
curl http://13.62.13.171/api/health

# Test with domain (after DNS propagates)
curl http://api.easybasket.in/api/health
```

**Both should return JSON!**

---

## 📋 Quick Fix Summary

1. **GoDaddy DNS:** Update A record `api` → `13.62.13.171`
2. **Test with IP:** `curl http://13.62.13.171/api/health`
3. **Wait 15-30 min:** For DNS to propagate
4. **Test domain:** `curl http://api.easybasket.in/api/health`

---

**Update DNS in GoDaddy to point to `13.62.13.171` and test! 🚀**

