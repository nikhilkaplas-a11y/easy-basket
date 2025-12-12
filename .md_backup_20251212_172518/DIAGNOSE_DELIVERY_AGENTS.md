# Diagnose "No Delivery Agent Available" Issue

## Quick Check: Verify Delivery Agents in Database

### Step 1: Connect to Database

```bash
mysql -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com -P 3306 -u YOUR_USERNAME -p easy_basket
```

### Step 2: Check Delivery Agents

```sql
-- Check all users with delivery role
SELECT id, phoneNumber, name, role, isActive, createdAt 
FROM users 
WHERE role = 'delivery';

-- Check only active delivery agents (what the API looks for)
SELECT id, phoneNumber, name, role, isActive 
FROM users 
WHERE role = 'delivery' AND isActive = true;
```

### Step 3: Fix Common Issues

**Issue 1: Role is not 'delivery'**
```sql
-- Fix: Update role to 'delivery'
UPDATE users 
SET role = 'delivery' 
WHERE phoneNumber = 'DELIVERY_AGENT_PHONE_NUMBER';
```

**Issue 2: isActive is false or NULL**
```sql
-- Fix: Set isActive to true
UPDATE users 
SET isActive = true 
WHERE role = 'delivery' AND phoneNumber = 'DELIVERY_AGENT_PHONE_NUMBER';
```

**Issue 3: Fix multiple delivery agents at once**
```sql
-- Make all delivery role users active
UPDATE users 
SET isActive = true 
WHERE role = 'delivery';
```

### Step 4: Test API Endpoint

After fixing, test the API endpoint:

```bash
# Replace YOUR_ADMIN_TOKEN with actual admin JWT token
curl -X GET "https://api.easybasket.in/api/admin/delivery-agents" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

Expected response:
```json
[
  {
    "id": 1,
    "name": "Delivery Agent Name",
    "phoneNumber": "9876543210",
    "email": "agent@example.com"
  }
]
```

## Common Issues and Solutions

### Issue: "No delivery agents available" but agents exist in database

**Possible Causes:**
1. `isActive` is `false` or `NULL` → Set to `true`
2. `role` is not exactly `'delivery'` → Check for typos, case sensitivity
3. API endpoint not working → Check backend logs
4. Authentication token issue → Check if admin token is valid

**Solution:**
```sql
-- Verify and fix all delivery agents
UPDATE users 
SET role = 'delivery', isActive = true 
WHERE phoneNumber IN ('9876543210', '9876543211', '9876543212');
```

### Issue: API returns empty array

**Check backend logs:**
- Look for console.log messages showing delivery agent count
- Check for any errors in the API response

**Verify query:**
```sql
-- This is what the backend queries
SELECT id, name, phoneNumber, email 
FROM users 
WHERE role = 'delivery' AND isActive = true 
ORDER BY name ASC;
```

## Quick Fix Script

Run this SQL to ensure all delivery agents are properly configured:

```sql
-- Make all delivery role users active and verify
UPDATE users 
SET isActive = true 
WHERE role = 'delivery';

-- Verify the fix
SELECT id, phoneNumber, name, role, isActive 
FROM users 
WHERE role = 'delivery' AND isActive = true;
```

## Frontend Debugging

If database looks correct, check frontend:

1. **Open browser console** (F12)
2. **Look for errors** when clicking "Accept Order"
3. **Check Network tab** for `/admin/delivery-agents` API call
4. **Verify response** - should return array of delivery agents

## Backend Debugging

Check backend logs for:
- `✅ Found X active delivery agents`
- `⚠️ No active delivery agents found`
- Any error messages

The backend now logs detailed information about delivery agents when the API is called.

