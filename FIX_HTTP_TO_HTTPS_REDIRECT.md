# Fix HTTP to HTTPS Redirect on ALB

## 🔍 Current Issue

- ✅ HTTPS works: `https://api.easybasket.in/api/health` → 200 OK
- ❌ HTTP doesn't redirect: `http://api.easybasket.in/api/health` → 200 OK (should redirect to HTTPS)

**Expected behavior:**
- `http://api.easybasket.in` → Should redirect to `https://api.easybasket.in` (301 redirect)

---

## 🔧 Fix: Configure HTTP Listener to Redirect

### Step 1: Check Current HTTP Listener

**AWS Console:**
1. **EC2** → **Load Balancers** → Select your ALB
2. **Listeners** tab
3. **Check HTTP listener (Port 80):**
   - **If exists:** Check what it's doing
   - **If doesn't exist:** Need to create it

### Step 2: Configure HTTP Listener to Redirect

**AWS Console:**
1. **EC2** → **Load Balancers** → Your ALB
2. **Listeners** tab
3. **Find HTTP listener (Port 80):**
   - **If exists:** Click on it → **Edit**
   - **If doesn't exist:** Click **"Add listener"**

4. **Configure HTTP Listener:**
   - **Protocol:** HTTP
   - **Port:** 80
   - **Default action:** 
     - ❌ **Don't select:** "Forward to" (this forwards to target group)
     - ✅ **Select:** "Redirect to"
   - **Redirect to:**
     - **Protocol:** HTTPS
     - **Port:** 443
     - **Status code:** 301 (Permanent redirect)
   - **Click "Save"**

### Step 3: Verify Redirect Works

**Test redirect:**
```bash
# Test HTTP redirect (should redirect to HTTPS)
curl -I http://api.easybasket.in/api/health

# Expected output:
# HTTP/1.1 301 Moved Permanently
# Location: https://api.easybasket.in/api/health
```

**Or test in browser:**
- Go to `http://api.easybasket.in`
- Should automatically redirect to `https://api.easybasket.in`
- URL bar should show `https://` and padlock icon

---

## 🎯 Current vs. Correct Configuration

### ❌ Wrong Configuration (Current)

**HTTP Listener (Port 80):**
```
Protocol: HTTP
Port: 80
Default action: Forward to Target Group
Target group: easy-basket-backend
```

**Result:** HTTP requests go directly to backend (no redirect)

### ✅ Correct Configuration

**HTTP Listener (Port 80):**
```
Protocol: HTTP
Port: 80
Default action: Redirect to
Protocol: HTTPS
Port: 443
Status code: 301
```

**Result:** HTTP requests redirect to HTTPS

---

## 📋 Step-by-Step Fix (AWS Console)

### Option 1: Edit Existing HTTP Listener

1. **EC2** → **Load Balancers** → Your ALB
2. **Listeners** tab
3. **Click on HTTP listener (Port 80)**
4. **Click "Edit"** (or pencil icon)
5. **Change default action:**
   - **Remove:** "Forward to Target Group"
   - **Add:** "Redirect to"
6. **Configure redirect:**
   - **Protocol:** HTTPS
   - **Port:** 443
   - **Status code:** 301
7. **Click "Save"**

### Option 2: Create New HTTP Listener (If Doesn't Exist)

1. **EC2** → **Load Balancers** → Your ALB
2. **Listeners** tab
3. **Click "Add listener"**
4. **Configure:**
   - **Protocol:** HTTP
   - **Port:** 80
   - **Default action:** Redirect to
   - **Protocol:** HTTPS
   - **Port:** 443
   - **Status code:** 301
5. **Click "Save"**

---

## 🧪 Test the Fix

### Test 1: Command Line

```bash
# Test HTTP redirect
curl -I http://api.easybasket.in/api/health

# Expected:
# HTTP/1.1 301 Moved Permanently
# Location: https://api.easybasket.in/api/health
# ...

# Follow redirect automatically
curl -L http://api.easybasket.in/api/health

# Should return the actual response from HTTPS endpoint
```

### Test 2: Browser

1. Open browser
2. Go to `http://api.easybasket.in`
3. **Should automatically redirect** to `https://api.easybasket.in`
4. URL bar should show `https://` and padlock icon

### Test 3: Check Response Headers

```bash
# Check redirect headers
curl -v http://api.easybasket.in/api/health 2>&1 | grep -i "location\|301\|302"

# Should show:
# < HTTP/1.1 301 Moved Permanently
# < Location: https://api.easybasket.in/api/health
```

---

## 🔧 AWS CLI Commands

### Check Current Listeners

```bash
# Get ALB ARN
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

# List all listeners
aws elbv2 describe-listeners \
  --load-balancer-arn $ALB_ARN \
  --query 'Listeners[*].[Protocol,Port,DefaultActions[0].Type]' \
  --output table
```

### Update HTTP Listener to Redirect

```bash
# Get HTTP listener ARN
HTTP_LISTENER_ARN=$(aws elbv2 describe-listeners \
  --load-balancer-arn $ALB_ARN \
  --query 'Listeners[?Protocol==`HTTP` && Port==`80`].ListenerArn' \
  --output text)

# Update to redirect
aws elbv2 modify-listener \
  --listener-arn $HTTP_LISTENER_ARN \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'
```

### Create HTTP Listener (If Doesn't Exist)

```bash
# Create HTTP listener with redirect
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'
```

---

## 🎯 Why This Matters

### Security Benefits

- ✅ **Forces HTTPS:** All traffic encrypted
- ✅ **Prevents mixed content:** No HTTP requests
- ✅ **SEO friendly:** Search engines prefer HTTPS
- ✅ **User trust:** Padlock icon in browser

### Best Practices

- ✅ **Always redirect HTTP to HTTPS**
- ✅ **Use 301 (Permanent redirect)** for SEO
- ✅ **Redirect all paths** (not just root)

---

## 📋 Verification Checklist

After fixing:

- [ ] HTTP listener (Port 80) exists
- [ ] HTTP listener action is "Redirect to" (not "Forward to")
- [ ] Redirect protocol is HTTPS
- [ ] Redirect port is 443
- [ ] Redirect status code is 301
- [ ] `curl -I http://api.easybasket.in` returns 301
- [ ] Browser redirects HTTP to HTTPS automatically

---

## 🔍 Troubleshooting

### Issue 1: Still Returns 200 After Fix

**Possible causes:**
- Changes not saved
- Browser cache
- DNS cache

**Solution:**
1. **Wait 1-2 minutes** for changes to propagate
2. **Clear browser cache** or use incognito mode
3. **Test with curl:** `curl -I http://api.easybasket.in`
4. **Check listener configuration** again

### Issue 2: Redirect Loop

**Possible causes:**
- HTTPS listener also redirecting
- Wrong redirect configuration

**Solution:**
1. **Check HTTPS listener:** Should forward to Target Group (not redirect)
2. **Verify redirect settings:** Protocol HTTPS, Port 443

### Issue 3: Redirect Not Working

**Possible causes:**
- HTTP listener doesn't exist
- Wrong action configured
- ALB not active

**Solution:**
1. **Check listeners:** HTTP (80) should exist
2. **Verify action:** Should be "Redirect to", not "Forward to"
3. **Check ALB status:** Should be "Active"

---

## ✅ Summary

**Current issue:** HTTP listener forwards to target group instead of redirecting.

**Fix:** Change HTTP listener default action from "Forward to Target Group" to "Redirect to HTTPS (Port 443, Status 301)".

**Result:** All HTTP requests automatically redirect to HTTPS! 🔒

