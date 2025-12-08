# How to Make a Delivery Agent Available

There are **2 methods** to create delivery agents in the system:

## Method 1: Using Admin Dashboard (Recommended)

### Steps:

1. **Have the delivery agent login first:**
   - Delivery agent opens the app
   - Enters their phone number
   - Enters OTP: `1234`
   - This creates them as a user with role `customer` by default

2. **Admin changes their role to "delivery":**
   - Admin logs into Admin Dashboard
   - Go to **"Users"** section
   - Find the user (by phone number)
   - Click on the role badge (shows "CUSTOMER")
   - Select **"Delivery"** from the dropdown
   - User role is now updated to `delivery`

3. **Verify delivery agent is available:**
   - Go to **"Orders"** section in Admin Dashboard
   - Try to accept an order
   - You should now see the delivery agent in the assignment dialog

## Method 2: Direct Database Update (Advanced)

If you need to create a delivery agent directly in the database:

### Using MySQL CLI:

```sql
-- Connect to database
mysql -h easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com -P 3306 -u YOUR_USERNAME -p easy_basket

-- Update existing user to delivery role
UPDATE users SET role = 'delivery', isActive = true WHERE phoneNumber = 'DELIVERY_AGENT_PHONE_NUMBER';

-- Or create new user directly (if they haven't logged in yet)
INSERT INTO users (phoneNumber, role, isActive, createdAt, updatedAt) 
VALUES ('DELIVERY_AGENT_PHONE_NUMBER', 'delivery', true, NOW(), NOW());
```

### Example:

```sql
-- Make user with phone number 9876543210 a delivery agent
UPDATE users SET role = 'delivery', isActive = true WHERE phoneNumber = '9876543210';
```

## Requirements for Delivery Agent:

1. **User must exist** in the `users` table
2. **Role must be** `'delivery'` (not `'customer'` or `'admin'`)
3. **isActive must be** `true` (default is `true`)
4. **Phone number must be unique** (already enforced by database)

## Verification:

After creating a delivery agent, verify they are available:

1. **In Admin Dashboard:**
   - Go to Orders → Accept an order
   - You should see the delivery agent in the assignment dialog

2. **In Database:**
   ```sql
   SELECT id, phoneNumber, name, role, isActive 
   FROM users 
   WHERE role = 'delivery' AND isActive = true;
   ```

3. **Delivery Agent can login:**
   - Delivery agent opens app
   - Logs in with their phone number + OTP `1234`
   - Should see Delivery Dashboard (not Customer Home)

## Troubleshooting:

**Problem:** "No delivery agents available" when accepting orders

**Solutions:**
1. Check if user exists: `SELECT * FROM users WHERE phoneNumber = 'PHONE_NUMBER';`
2. Check if role is correct: `SELECT role FROM users WHERE phoneNumber = 'PHONE_NUMBER';`
3. Check if isActive is true: `SELECT isActive FROM users WHERE phoneNumber = 'PHONE_NUMBER';`
4. Update if needed: `UPDATE users SET role = 'delivery', isActive = true WHERE phoneNumber = 'PHONE_NUMBER';`

## Quick Setup Script:

```sql
-- Make multiple users delivery agents at once
UPDATE users 
SET role = 'delivery', isActive = true 
WHERE phoneNumber IN ('9876543210', '9876543211', '9876543212');
```

---

**Note:** The easiest method is **Method 1** - have the delivery agent login first, then admin changes their role in the Users section.

