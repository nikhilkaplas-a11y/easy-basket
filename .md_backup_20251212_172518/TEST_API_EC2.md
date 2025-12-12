# 🧪 Test API on EC2 - Curl Commands

Complete guide for testing your backend API on EC2.

---

## 🔍 Test from EC2 (Local)

### Basic Tests

```bash
# Test root endpoint
curl http://localhost:3000

# Test health endpoint
curl http://localhost:3000/api/health

# Test with pretty JSON output
curl http://localhost:3000/api/health | python3 -m json.tool

# Or use jq (if installed)
curl http://localhost:3000/api/health | jq
```

### Test API Endpoints

```bash
# Test categories
curl http://localhost:3000/api/categories

# Test products
curl http://localhost:3000/api/products

# Test products with pretty output
curl http://localhost:3000/api/products | python3 -m json.tool

# Test with limit
curl "http://localhost:3000/api/products?limit=5"
```

### Test Authentication

```bash
# Send OTP
curl -X POST http://localhost:3000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}'

# Verify OTP (use token from response)
curl -X POST http://localhost:3000/api/auth/verify \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210", "otp": "1234"}'
```

---

## 🌐 Test from Outside EC2

### Get Your EC2 Public IP

```bash
# On EC2, get public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4

# Or check in AWS Console: EC2 → Instances → Your instance
```

### Test from Your Local Machine

```bash
# Replace YOUR_PUBLIC_IP with actual IP
curl http://YOUR_PUBLIC_IP:3000/api/health

# Example:
curl http://54.123.45.67:3000/api/health
```

**⚠️ Important:** Make sure security group allows port 3000 from your IP!

---

## 🔧 Install jq for Better Output (Optional)

```bash
# On EC2
sudo yum install -y jq

# Then use:
curl http://localhost:3000/api/health | jq
```

---

## 📋 Quick Test Commands

### Check if Server is Running

```bash
# Simple test
curl http://localhost:3000

# Should return: "Easy Basket Backend is running"
```

### Check Health Endpoint

```bash
curl http://localhost:3000/api/health

# Should return JSON:
# {
#   "status": "ok",
#   "message": "Easy Basket Backend is running",
#   "timestamp": "2025-12-03T..."
# }
```

### Check Database Connection

```bash
# Test categories (requires database)
curl http://localhost:3000/api/categories

# If database connected: Returns categories
# If not: May show error
```

---

## 🐛 Troubleshooting

### Error: "Connection refused"

**Cause:** Server not running or wrong port

**Fix:**
```bash
# Check if PM2 is running
pm2 status

# Check if port 3000 is in use
sudo lsof -i :3000

# Restart if needed
pm2 restart easy-basket-api
```

### Error: "Could not resolve host"

**Cause:** Wrong URL or server not accessible

**Fix:**
- Use `localhost` for local tests
- Use public IP for external tests
- Check security group allows port 3000

### No Response

**Cause:** Server crashed or not started

**Fix:**
```bash
# Check PM2 logs
pm2 logs easy-basket-api --lines 50

# Restart if needed
pm2 restart easy-basket-api
```

---

## ✅ Success Indicators

### Server Running:
```bash
$ curl http://localhost:3000
Easy Basket Backend is running
```

### Health Check:
```bash
$ curl http://localhost:3000/api/health
{"status":"ok","message":"Easy Basket Backend is running","timestamp":"2025-12-03T..."}
```

### Database Connected:
```bash
$ curl http://localhost:3000/api/categories
{"categories":[...],"pagination":{...}}
```

---

## 📋 Complete Test Sequence

```bash
# 1. Check server
curl http://localhost:3000

# 2. Check health
curl http://localhost:3000/api/health

# 3. Check categories
curl http://localhost:3000/api/categories | python3 -m json.tool

# 4. Check products
curl http://localhost:3000/api/products | python3 -m json.tool

# 5. Test authentication
curl -X POST http://localhost:3000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}'
```

---

## 🎯 Quick Reference

| Command | Description |
|---------|-------------|
| `curl http://localhost:3000` | Test root endpoint |
| `curl http://localhost:3000/api/health` | Test health endpoint |
| `curl http://localhost:3000/api/categories` | Test categories |
| `curl http://localhost:3000/api/products` | Test products |
| `curl http://YOUR_IP:3000/api/health` | Test from outside |

---

**Test your API now! 🚀**

