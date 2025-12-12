# 📱 Role-Based App Routing

## How It Works

The app automatically detects your **user role** from the database and shows the appropriate interface:

### 🔄 Automatic Routing

When you login, the app checks your `role` field in the database:

1. **If `role = 'customer'`** → Shows **Customer App** (Home screen with products)
2. **If `role = 'delivery'`** → Shows **Delivery App** (Delivery dashboard)
3. **If `role = 'admin'`** → Shows **Admin Dashboard** (future feature)

### 📍 Routing Logic

```dart
// In app_router.dart
if (isAuthenticated) {
  final userRole = authProvider.user?.role;
  if (userRole == 'delivery') {
    return '/delivery/dashboard';  // Delivery app
  }
  return '/home';  // Customer app
}
```

## 🧪 Testing Both Apps

### Test Customer App

1. **Check/Set user role to 'customer':**
   ```sql
   SELECT id, phoneNumber, role FROM users;
   UPDATE users SET role = 'customer' WHERE phoneNumber = 'YOUR_PHONE';
   ```

2. **Login** with your phone number
3. **You'll see:** Customer home screen with products, categories, cart

### Test Delivery App

1. **Set user role to 'delivery':**
   ```sql
   UPDATE users SET role = 'delivery' WHERE phoneNumber = 'YOUR_PHONE';
   ```

2. **Assign an order to yourself:**
   ```sql
   UPDATE orders SET deliveryBoyId = YOUR_USER_ID WHERE id = 1;
   ```

3. **Login** with the same phone number
4. **You'll see:** Delivery dashboard with stats and orders

## 🔑 Key Points

- **Same phone number, different roles** = Different apps
- **Role is stored in database** (`users.role` field)
- **Automatic redirect** based on role
- **No manual switching needed** - app detects automatically

## 📊 User Roles

| Role | App Interface | Features |
|------|--------------|----------|
| `customer` | Customer App | Browse products, cart, orders, addresses |
| `delivery` | Delivery App | Dashboard, orders, navigation, status updates |
| `admin` | Admin Dashboard | (Future) Manage products, orders, users |

## 🔄 Switching Between Apps

To switch between customer and delivery app:

1. **Update role in database:**
   ```sql
   -- Switch to delivery
   UPDATE users SET role = 'delivery' WHERE phoneNumber = 'YOUR_PHONE';
   
   -- Switch back to customer
   UPDATE users SET role = 'customer' WHERE phoneNumber = 'YOUR_PHONE';
   ```

2. **Logout and login again** (or restart app)
3. **App will automatically show the correct interface**

## 💡 Pro Tip

You can create **two separate user accounts** with different phone numbers:
- One for customer testing
- One for delivery testing

Or use the same phone number and change the role as needed!

---

**The app automatically detects your role and shows the right interface! 🎯**

