# 🔐 JWT Authentication & Authorization Explained

Complete explanation of the authentication and authorization system implemented in Easy Basket.

---

## 📋 Overview

The app uses **JWT (JSON Web Tokens)** for stateless authentication. Here's how it works:

1. **User logs in** with phone number + OTP
2. **Backend generates JWT token** containing user info
3. **Client stores token** and sends it with every request
4. **Backend validates token** on protected routes
5. **Role-based access control** restricts certain actions

---

## 🔄 Authentication Flow

### Step 1: Login Request

**Endpoint:** `POST /api/auth/login`

```typescript
// User sends phone number
{
  "phoneNumber": "9876543210"
}

// Backend responds
{
  "message": "OTP sent successfully. Use 1234 for testing."
}
```

**What happens:**
- Backend receives phone number
- Currently uses hardcoded OTP: `1234` (for testing)
- No actual SMS sent (OTP provider removed)

---

### Step 2: OTP Verification & Token Generation

**Endpoint:** `POST /api/auth/verify`

```typescript
// User sends phone number + OTP
{
  "phoneNumber": "9876543210",
  "otp": "1234",
  "fcmToken": "optional-firebase-token"
}

// Backend responds with JWT token
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "phoneNumber": "9876543210",
    "name": null,
    "email": null,
    "role": "customer"
  }
}
```

**What happens in `AuthController.verify`:**

```typescript
// 1. Verify OTP (currently accepts "1234" for all users)
if (otp !== '1234') {
  return error;
}

// 2. Find or create user in database
let user = await userRepository.findOneBy({ phoneNumber });
if (!user) {
  user = userRepository.create({ phoneNumber });
  await userRepository.save(user);
}

// 3. Generate JWT token
const token = jwt.sign(
  {
    userId: user.id,
    phoneNumber: user.phoneNumber,
    role: user.role  // 'customer', 'admin', or 'delivery'
  },
  process.env.JWT_SECRET || 'your-secret-key',
  { expiresIn: '30d' }  // Token valid for 30 days
);

// 4. Return token + user info
res.json({ token, user });
```

**JWT Token Structure:**
```
Header: { "alg": "HS256", "typ": "JWT" }
Payload: {
  "userId": 1,
  "phoneNumber": "9876543210",
  "role": "customer",
  "iat": 1234567890,  // Issued at
  "exp": 1237248000   // Expires in 30 days
}
Signature: HMACSHA256(base64UrlEncode(header) + "." + base64UrlEncode(payload), secret)
```

---

### Step 3: Client Stores Token

**Flutter App (`AuthProvider`):**

```dart
// After successful login
await prefs.setString('auth_token', token);
await prefs.setString('user_data', jsonEncode(user));

// Token is now stored in SharedPreferences
```

---

### Step 4: Sending Token with Requests

**Every protected API request includes token:**

```dart
// Flutter API Service
final response = await http.get(
  Uri.parse('$apiBaseUrl/orders'),
  headers: {
    'Authorization': 'Bearer $token',  // Token in header
    'Content-Type': 'application/json',
  },
);
```

**HTTP Header Format:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🛡️ Authorization Middleware

### Authentication Middleware (`authenticate`)

**File:** `backend/src/middleware/auth.middleware.ts`

```typescript
export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // 1. Extract token from Authorization header
    const token = req.headers.authorization?.split(' ')[1];
    // "Bearer TOKEN" → "TOKEN"

    if (!token) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    // 2. Verify token signature and expiration
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET || 'your-secret-key'
    ) as { userId: number };

    // 3. Fetch user from database
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOneBy({ id: decoded.userId });

    // 4. Check if user exists and is active
    if (!user || !user.isActive) {
      res.status(401).json({ message: 'Invalid or inactive user' });
      return;
    }

    // 5. Attach user to request object
    req.user = user;
    next();  // Continue to next middleware/controller
  } catch (error) {
    res.status(401).json({ message: 'Invalid token' });
  }
};
```

**What it does:**
1. ✅ Extracts token from `Authorization: Bearer TOKEN` header
2. ✅ Verifies token signature (not tampered)
3. ✅ Checks token expiration
4. ✅ Fetches user from database
5. ✅ Validates user is active
6. ✅ Attaches user to `req.user` for use in controllers

**If token is invalid:**
- Returns `401 Unauthorized`
- Request stops here (doesn't reach controller)

---

### Authorization Middleware (`authorize`)

**File:** `backend/src/middleware/auth.middleware.ts`

```typescript
export const authorize = (...roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    // 1. Check if user is authenticated (req.user exists)
    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    // 2. Check if user's role is in allowed roles
    if (!roles.includes(req.user.role)) {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    next();  // User has required role, continue
  };
};
```

**Usage Example:**
```typescript
// Only admin can create products
router.post('/products', 
  authenticate,           // First: verify token
  authorize('admin'),     // Then: check role
  ProductController.createProduct
);
```

**What it does:**
1. ✅ Checks `req.user` exists (must be authenticated first)
2. ✅ Checks if user's role matches allowed roles
3. ✅ Returns `403 Forbidden` if role doesn't match

**Role Types:**
- `'customer'` - Regular users
- `'admin'` - Admin dashboard access
- `'delivery'` - Delivery boy access

---

## 🔒 Protected Routes

### Route Protection Levels

#### 1. **Public Routes** (No authentication)
```typescript
// Anyone can access
router.post('/auth/login', AuthController.login);
router.post('/auth/verify', AuthController.verify);
router.get('/products', ProductController.getAllProducts);
router.get('/categories', CategoryController.getAllCategories);
```

#### 2. **Authenticated Routes** (Any logged-in user)
```typescript
// Must have valid JWT token
router.use(authenticate);  // All routes below require auth

router.post('/orders', OrderController.createOrder);
router.get('/orders', OrderController.getUserOrders);
router.put('/auth/profile', AuthController.updateProfile);
router.get('/addresses', AddressController.getAddresses);
```

#### 3. **Role-Based Routes** (Specific roles only)
```typescript
// Admin only
router.post('/products', 
  authenticate, 
  authorize('admin'), 
  ProductController.createProduct
);

router.put('/products/:id', 
  authenticate, 
  authorize('admin'), 
  ProductController.updateProduct
);

// Admin routes (all require admin role)
router.use(authenticate);  // First authenticate
router.use(authorize('admin'));  // Then check admin role
router.get('/dashboard', AdminController.getDashboardStats);
router.get('/orders', AdminController.getAllOrders);
```

---

## 📁 File Structure

```
backend/src/
├── controllers/
│   └── auth.controller.ts      # Login, verify, updateProfile
├── middleware/
│   └── auth.middleware.ts       # authenticate, authorize
└── routes/
    ├── auth.routes.ts           # Public: login, verify | Protected: profile
    ├── order.routes.ts          # Protected: all routes require auth
    ├── address.routes.ts        # Protected: all routes require auth
    ├── product.routes.ts       # Public: GET | Protected+Admin: POST/PUT/DELETE
    ├── category.routes.ts      # Public: GET | Protected+Admin: POST/PUT/DELETE
    ├── admin.routes.ts         # Protected+Admin: all routes
    └── delivery.routes.ts      # Protected+Delivery: all routes
```

---

## 🔑 Key Components

### 1. JWT Token Generation

**Location:** `backend/src/controllers/auth.controller.ts:58-62`

```typescript
const token = jwt.sign(
  {
    userId: user.id,           // User ID from database
    phoneNumber: user.phoneNumber,
    role: user.role             // 'customer', 'admin', 'delivery'
  },
  process.env.JWT_SECRET || 'your-secret-key',  // Secret key (keep secure!)
  { expiresIn: '30d' }         // Token expires in 30 days
);
```

**Token Payload Contains:**
- `userId` - To fetch user from database
- `phoneNumber` - User identifier
- `role` - For authorization checks
- `iat` - Issued at timestamp (auto-added)
- `exp` - Expiration timestamp (auto-added)

---

### 2. Token Verification

**Location:** `backend/src/middleware/auth.middleware.ts:23-25`

```typescript
const decoded = jwt.verify(
  token,
  process.env.JWT_SECRET || 'your-secret-key'
) as { userId: number };
```

**What `jwt.verify` does:**
- ✅ Verifies signature (token not tampered)
- ✅ Checks expiration (`exp` claim)
- ✅ Returns decoded payload if valid
- ❌ Throws error if invalid/expired

---

### 3. User Attachment to Request

**Location:** `backend/src/middleware/auth.middleware.ts:35`

```typescript
req.user = user;  // Attach full user object to request
```

**After authentication, controllers can access:**
```typescript
// In any controller
const userId = req.user?.id;
const userRole = req.user?.role;
const phoneNumber = req.user?.phoneNumber;
```

---

### 4. Role-Based Access Control

**Example: Admin Product Creation**

```typescript
// Route definition
router.post('/products', 
  authenticate,           // Step 1: Verify token
  authorize('admin'),     // Step 2: Check role = 'admin'
  ProductController.createProduct
);

// In controller
static async createProduct(req: AuthRequest, res: Response) {
  // req.user is guaranteed to exist and be admin
  const adminId = req.user.id;
  // ... create product
}
```

**Flow:**
1. Request arrives with `Authorization: Bearer TOKEN`
2. `authenticate` middleware:
   - Verifies token
   - Fetches user
   - Sets `req.user`
3. `authorize('admin')` middleware:
   - Checks `req.user.role === 'admin'`
   - Allows if match, rejects if not
4. Controller receives request with `req.user` attached

---

## 🔐 Security Features

### 1. **Token Expiration**
- Tokens expire after 30 days
- User must re-login after expiration
- Prevents indefinite access

### 2. **Secret Key**
- JWT signed with secret key
- Stored in `process.env.JWT_SECRET`
- Never commit to git!

### 3. **User Validation**
- Token verified → User fetched from database
- Checks `user.isActive` flag
- Inactive users cannot access

### 4. **Role-Based Access**
- Different roles have different permissions
- Admin-only routes protected
- Delivery-only routes protected

### 5. **Stateless Authentication**
- No server-side session storage
- Token contains all needed info
- Scalable (works across multiple servers)

---

## 📱 Frontend Integration

### Flutter App (`AuthProvider`)

**Storing Token:**
```dart
// After login
await prefs.setString('auth_token', token);
```

**Sending Token:**
```dart
// In API service
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

**Checking Authentication:**
```dart
bool get isAuthenticated => _token != null && _user != null;
```

**Logout:**
```dart
void logout() {
  _token = null;
  _user = null;
  prefs.remove('auth_token');
  prefs.remove('user_data');
}
```

---

## 🧪 Testing Authentication

### 1. **Login Flow**
```bash
# Step 1: Request OTP
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}'

# Step 2: Verify OTP
curl -X POST http://localhost:3000/api/auth/verify \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210", "otp": "1234"}'

# Response:
# {
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "user": { ... }
# }
```

### 2. **Protected Route**
```bash
# Without token (will fail)
curl http://localhost:3000/api/orders
# Response: { "message": "Authentication required" }

# With token (will succeed)
curl http://localhost:3000/api/orders \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
# Response: [ ... orders ... ]
```

### 3. **Admin Route**
```bash
# As customer (will fail)
curl -X POST http://localhost:3000/api/products \
  -H "Authorization: Bearer CUSTOMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Product"}'
# Response: { "message": "Access denied" }

# As admin (will succeed)
curl -X POST http://localhost:3000/api/products \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Product"}'
# Response: { "product": { ... } }
```

---

## 🔧 Configuration

### Environment Variables

**File:** `backend/.env`

```env
JWT_SECRET=your-super-secret-key-change-this-in-production
```

**Important:**
- Use strong, random secret in production
- Never commit to git
- Different secret per environment (dev/staging/prod)

---

## 📊 Request Flow Diagram

```
┌─────────┐
│ Client  │
└────┬────┘
     │ 1. POST /api/auth/login { phoneNumber }
     ▼
┌─────────────────┐
│ AuthController  │
│ .login()        │
└────┬────────────┘
     │ 2. Return "OTP sent"
     ▼
┌─────────┐
│ Client  │
└────┬────┘
     │ 3. POST /api/auth/verify { phoneNumber, otp }
     ▼
┌─────────────────┐
│ AuthController  │
│ .verify()       │
│ - Verify OTP    │
│ - Find/Create   │
│   User          │
│ - Generate JWT  │
└────┬────────────┘
     │ 4. Return { token, user }
     ▼
┌─────────┐
│ Client  │
│ Stores  │
│ Token   │
└────┬────┘
     │ 5. GET /api/orders
     │    Header: Authorization: Bearer TOKEN
     ▼
┌─────────────────┐
│ authenticate    │
│ Middleware      │
│ - Extract token │
│ - Verify JWT    │
│ - Fetch user    │
│ - Set req.user  │
└────┬────────────┘
     │ 6. req.user attached
     ▼
┌─────────────────┐
│ authorize       │
│ Middleware      │
│ (if needed)     │
│ - Check role    │
└────┬────────────┘
     │ 7. Role verified
     ▼
┌─────────────────┐
│ OrderController │
│ .getUserOrders()│
│ - Use req.user  │
└────┬────────────┘
     │ 8. Return orders
     ▼
┌─────────┐
│ Client  │
└─────────┘
```

---

## ✅ Summary

**Authentication:**
- ✅ Phone number + OTP login
- ✅ JWT token generation (30-day expiry)
- ✅ Token stored in client (SharedPreferences)
- ✅ Token sent in `Authorization: Bearer TOKEN` header

**Authorization:**
- ✅ `authenticate` middleware verifies token
- ✅ `authorize` middleware checks role
- ✅ Role-based access control (customer/admin/delivery)
- ✅ Protected routes require valid token

**Security:**
- ✅ Token expiration (30 days)
- ✅ Secret key signing
- ✅ User validation (active check)
- ✅ Stateless (no server sessions)

---

**This system ensures secure, scalable authentication and authorization for Easy Basket! 🔐**

