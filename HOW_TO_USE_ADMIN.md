# 📖 How to Use Admin Dashboard

## 🚀 Quick Start

### Step 1: Set User as Admin

**Option A: Using MySQL Command Line**
```bash
mysql -u root -p easy_basket
```

Then run:
```sql
UPDATE users SET role = 'admin' WHERE phoneNumber = 'YOUR_PHONE_NUMBER';
```

**Option B: Using SQL Query**
```sql
-- Check current users
SELECT id, phoneNumber, role FROM users;

-- Set specific user to admin
UPDATE users SET role = 'admin' WHERE phoneNumber = '9876543210';

-- Verify the change
SELECT phoneNumber, role FROM users WHERE phoneNumber = '9876543210';
```

### Step 2: Login

1. **Open the app** (Flutter app running)
2. **Enter your phone number** (the one you set as admin)
3. **Enter OTP:** `1234`
4. **You'll be automatically redirected** to Admin Dashboard! 🎉

---

## 📱 Admin Dashboard Features

### 1. Dashboard Overview

**What you'll see:**
- **Total Orders** - All orders count
- **Pending Orders** - Orders waiting for action
- **Today's Orders** - Orders placed today
- **Total Users** - All registered users
- **Total Products** - Available products
- **Low Stock** - Products with stock < 10
- **Today's Revenue** - Money earned today

**Quick Actions:**
- Tap "Orders" → Manage all orders
- Tap "Users" → Manage all users
- Tap "Products" → View products
- Tap "Categories" → View categories

---

### 2. Manage Orders

**Access:** Tap "Orders" button or go to `/admin/orders`

**Features:**
- **Filter Orders** by status:
  - All
  - Pending
  - Accepted
  - Out for Delivery
  - Delivered

- **View Order Details:**
  - Tap any order card to expand
  - See customer info
  - See delivery address
  - See order items
  - See order total

- **Update Order Status:**
  - **Pending** → Tap "Accept" → Order becomes Accepted
  - **Accepted** → Tap "Preparing" → Order is being prepared
  - **Preparing** → Tap "Out for Delivery" → Ready for delivery
  - **Out for Delivery** → Tap "Delivered" → Order complete
  - **Any status** → Tap "Cancel" → Cancel order

**Workflow:**
```
Pending → Accept → Preparing → Out for Delivery → Delivered
```

---

### 3. Manage Users

**Access:** Tap "Users" button or go to `/admin/users`

**Features:**
- **Filter Users** by role:
  - All Users
  - Customers
  - Delivery Boys
  - Admins

- **View User Info:**
  - Name
  - Phone Number
  - Email
  - Current Role

- **Change User Role:**
  - Tap the role badge (top right of user card)
  - Select new role:
    - **Customer** - Regular app user
    - **Delivery** - Delivery boy (sees delivery dashboard)
    - **Admin** - Admin access

**Use Cases:**
- Promote customer to delivery boy
- Make someone an admin
- Change delivery boy back to customer

---

## 🎯 Common Tasks

### Task 1: Accept a New Order

1. Go to **Admin Dashboard**
2. Tap **"Orders"**
3. Filter by **"Pending"**
4. Find the order
5. Tap to expand
6. Tap **"Accept"** button
7. Order status changes to "Accepted"

### Task 2: Assign Order to Delivery Boy

1. Go to **Orders** → Find order
2. Update status to **"Out for Delivery"**
3. (Backend automatically assigns if deliveryBoyId provided)
4. Delivery boy gets notification

### Task 3: Change User Role

1. Go to **Admin Dashboard**
2. Tap **"Users"**
3. Filter by role if needed
4. Find the user
5. Tap the **role badge** (top right)
6. Select new role
7. User role updated!

### Task 4: View Business Stats

1. Go to **Admin Dashboard**
2. View all stats cards:
   - Total orders
   - Pending orders
   - Today's revenue
   - User count
   - Product count
   - Low stock alerts

---

## 🔄 Switching Between Roles

### Test Different Interfaces

**To test Customer App:**
```sql
UPDATE users SET role = 'customer' WHERE phoneNumber = 'YOUR_PHONE';
```
Then logout and login → See customer home screen

**To test Delivery App:**
```sql
UPDATE users SET role = 'delivery' WHERE phoneNumber = 'YOUR_PHONE';
```
Then logout and login → See delivery dashboard

**To test Admin App:**
```sql
UPDATE users SET role = 'admin' WHERE phoneNumber = 'YOUR_PHONE';
```
Then logout and login → See admin dashboard

---

## 📊 Dashboard Stats Explained

### Orders Stats
- **Total Orders** - All orders ever placed
- **Pending Orders** - Orders waiting for admin action
- **Today's Orders** - Orders placed today

### Users Stats
- **Total Users** - All active registered users

### Products Stats
- **Total Products** - All available products
- **Low Stock** - Products with stock < 10 (need restocking)

### Revenue Stats
- **Today's Revenue** - Money from delivered orders today

---

## 🛠️ Tips & Tricks

1. **Refresh Data:**
   - Pull down to refresh on any screen
   - Or tap refresh icon in app bar

2. **Filter Orders:**
   - Use status chips at top
   - Filter by: All, Pending, Accepted, Out for Delivery, Delivered

3. **Filter Users:**
   - Use role chips at top
   - Filter by: All, Customers, Delivery, Admins

4. **View Order Details:**
   - Tap any order card to expand
   - See full customer info and address
   - See all order items

5. **Quick Status Updates:**
   - Buttons appear based on current status
   - One tap to update status
   - Customer gets notified automatically

---

## ⚠️ Important Notes

- **Only admins** can access admin routes
- **Role is checked** on every route
- **Logout and login** after changing role in database
- **OTP for testing:** Always use `1234`

---

## 🧪 Testing Checklist

- [ ] Set user role to 'admin' in database
- [ ] Login with admin phone number
- [ ] Verify redirect to admin dashboard
- [ ] Check dashboard stats load
- [ ] View orders list
- [ ] Update order status
- [ ] View users list
- [ ] Change user role
- [ ] Test filters

---

**You're all set! Start managing your grocery delivery business! 🎉**

