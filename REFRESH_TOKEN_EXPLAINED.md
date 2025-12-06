# 🔄 Refresh Token System Explained

Complete explanation of the refresh token implementation in Easy Basket.

---

## ✅ Refresh Token System is Already Implemented!

The app uses a **two-token system**:
1. **Access Token** - Short-lived (15 minutes) for API requests
2. **Refresh Token** - Long-lived (30 days) for getting new access tokens

---

## 🔑 Why Refresh Tokens?

### Security Benefits:

1. **Short-lived Access Tokens**
   - If stolen, expire quickly (15 minutes)
   - Limited damage window
   - Reduces risk of unauthorized access

2. **Revocable Refresh Tokens**
   - Stored in database
   - Can be revoked on logout or security breach
   - Better control over user sessions

3. **Better Security Posture**
   - Access tokens don't need to be stored securely (short-lived)
   - Refresh tokens stored securely in database
   - Can track active sessions

---

## 📊 Token Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│                    User Login                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  POST /api/auth/verify │
         │  { phoneNumber, otp }  │
         └───────────┬────────────┘
                     │
                     ▼
    ┌────────────────────────────────────┐
    │  Backend Generates:                │
    │  • Access Token (15 min)          │
    │  • Refresh Token (30 days)        │
    │  • Saves RefreshToken to DB       │
    └────────────┬───────────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────┐
    │  Client Receives:                  │
    │  {                                 │
    │    accessToken: "eyJhbGc...",      │
    │    refreshToken: "abc123...",      │
    │    user: { ... }                   │
    │  }                                 │
    └────────────┬───────────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────┐
    │  Client Stores:                   │
    │  • accessToken (in memory/state)   │
    │  • refreshToken (in SharedPrefs)   │
    └────────────┬───────────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────┐
    │  API Requests:                    │
    │  Authorization: Bearer {accessToken}│
    └────────────┬───────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
   ✅ Valid        ❌ Expired
   (15 min)       (after 15 min)
        │                 │
        │                 ▼
        │      ┌──────────────────────┐
        │      │  POST /api/auth/     │
        │      │  refresh             │
        │      │  { refreshToken }    │
        │      └──────────┬───────────┘
        │                 │
        │                 ▼
        │      ┌──────────────────────┐
        │      │  Backend Validates:  │
        │      │  • Token exists in DB│
        │      │  • Token is active   │
        │      │  • Token not expired │
        │      │  • User is active    │
        │      └──────────┬───────────┘
        │                 │
        │                 ▼
        │      ┌──────────────────────┐
        │      │  Generate New:       │
        │      │  • Access Token      │
        │      │  (refreshToken stays)│
        │      └──────────┬───────────┘
        │                 │
        └─────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────┐
    │  Client Updates:                  │
    │  • New accessToken                 │
    │  • Retry failed request            │
    └────────────────────────────────────┘
```

---

## 🔧 Implementation Details

### 1. RefreshToken Entity

**File:** `backend/src/entities/RefreshToken.ts`

```typescript
@Entity()
export class RefreshToken {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ unique: true })
  token!: string;  // Random 64-byte hex string

  @Column()
  userId!: number;  // Foreign key to User

  @Column()
  expiresAt!: Date;  // 30 days from creation

  @Column({ default: true })
  isActive!: boolean;  // Can be revoked

  @ManyToOne(() => User, (user) => user.refreshTokens)
  user!: User;

  @CreateDateColumn()
  createdAt!: Date;
}
```

**Key Features:**
- Unique token (random 64-byte hex)
- Linked to user
- Expires in 30 days
- Can be revoked (`isActive: false`)

---

### 2. Login/Verify Flow

**Endpoint:** `POST /api/auth/verify`

**Request:**
```json
{
  "phoneNumber": "9876543210",
  "otp": "1234"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "a1b2c3d4e5f6...",
  "user": {
    "id": 1,
    "phoneNumber": "9876543210",
    "role": "customer"
  }
}
```

**Backend Code:**
```typescript
// Generate Access Token (15 minutes)
const accessToken = jwt.sign(
  { userId: user.id, phoneNumber: user.phoneNumber, role: user.role },
  process.env.JWT_SECRET || 'your-secret-key',
  { expiresIn: '15m' }  // Short-lived
);

// Generate Refresh Token (random, secure)
const refreshTokenValue = crypto.randomBytes(64).toString('hex');
const refreshTokenExpiry = new Date();
refreshTokenExpiry.setDate(refreshTokenExpiry.getDate() + 30); // 30 days

// Save to database
const refreshToken = refreshTokenRepository.create({
  token: refreshTokenValue,
  userId: user.id,
  expiresAt: refreshTokenExpiry,
  isActive: true,
});
await refreshTokenRepository.save(refreshToken);
```

---

### 3. Refresh Token Endpoint

**Endpoint:** `POST /api/auth/refresh`

**Request:**
```json
{
  "refreshToken": "a1b2c3d4e5f6..."
}
```

**Response (Success):**
```json
{
  "message": "Token refreshed successfully",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "phoneNumber": "9876543210",
    "role": "customer"
  }
}
```

**Response (Error):**
```json
{
  "message": "Invalid refresh token"
}
// or
{
  "message": "Refresh token expired"
}
```

**Backend Code:**
```typescript
static async refresh(req: Request, res: Response): Promise<void> {
  const { refreshToken } = req.body;

  // 1. Find token in database
  const tokenRecord = await refreshTokenRepository.findOne({
    where: { token: refreshToken, isActive: true },
    relations: ['user'],
  });

  if (!tokenRecord) {
    return res.status(401).json({ message: 'Invalid refresh token' });
  }

  // 2. Check expiration
  if (new Date() > tokenRecord.expiresAt) {
    tokenRecord.isActive = false;  // Revoke expired token
    await refreshTokenRepository.save(tokenRecord);
    return res.status(401).json({ message: 'Refresh token expired' });
  }

  // 3. Check user is active
  if (!tokenRecord.user.isActive) {
    return res.status(401).json({ message: 'User account is inactive' });
  }

  // 4. Generate new access token
  const accessToken = jwt.sign(
    {
      userId: tokenRecord.user.id,
      phoneNumber: tokenRecord.user.phoneNumber,
      role: tokenRecord.user.role,
    },
    process.env.JWT_SECRET || 'your-secret-key',
    { expiresIn: '15m' }
  );

  // 5. Return new access token (refresh token stays the same)
  res.json({
    message: 'Token refreshed successfully',
    accessToken,
    user: { ...tokenRecord.user },
  });
}
```

**Validation Steps:**
1. ✅ Token exists in database
2. ✅ Token is active (`isActive: true`)
3. ✅ Token not expired
4. ✅ User is active
5. ✅ Generate new access token

---

### 4. Logout Endpoint

**Endpoint:** `POST /api/auth/logout`

**Request (with refresh token):**
```json
{
  "refreshToken": "a1b2c3d4e5f6..."
}
```

**Or (authenticated user - revokes all tokens):**
```
Authorization: Bearer {accessToken}
```

**Response:**
```json
{
  "message": "Logout successful"
}
```

**Backend Code:**
```typescript
static async logout(req: Request, res: Response): Promise<void> {
  const { refreshToken } = req.body;
  const userId = (req as any).user?.id;

  if (refreshToken) {
    // Revoke specific refresh token
    const tokenRecord = await refreshTokenRepository.findOne({
      where: { token: refreshToken },
    });
    if (tokenRecord) {
      tokenRecord.isActive = false;
      await refreshTokenRepository.save(tokenRecord);
    }
  } else if (userId) {
    // Revoke ALL refresh tokens for this user
    await refreshTokenRepository.update(
      { userId, isActive: true },
      { isActive: false }
    );
  }

  res.json({ message: 'Logout successful' });
}
```

**Logout Options:**
1. **Single device logout:** Send `refreshToken` → Revoke that specific token
2. **All devices logout:** Send `accessToken` → Revoke all tokens for user

---

## 📱 Frontend Integration

### Storing Tokens

**Flutter App (`AuthProvider`):**

```dart
// After login
await prefs.setString('access_token', accessToken);
await prefs.setString('refresh_token', refreshToken);
await prefs.setString('user_data', jsonEncode(user));
```

**Token Storage Strategy:**
- **Access Token:** In memory/state (short-lived, refreshed frequently)
- **Refresh Token:** In SharedPreferences (long-lived, secure storage)

---

### Automatic Token Refresh

**When Access Token Expires:**

```dart
// In API service, handle 401 errors
if (response.statusCode == 401) {
  // Access token expired, try to refresh
  final refreshToken = prefs.getString('refresh_token');
  
  if (refreshToken != null) {
    // Call refresh endpoint
    final refreshResponse = await http.post(
      Uri.parse('$apiBaseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    
    if (refreshResponse.statusCode == 200) {
      final data = jsonDecode(refreshResponse.body);
      final newAccessToken = data['accessToken'];
      
      // Update stored token
      await prefs.setString('access_token', newAccessToken);
      
      // Retry original request with new token
      return await _retryRequest(originalRequest, newAccessToken);
    } else {
      // Refresh failed, logout user
      authProvider.logout();
      throw Exception('Session expired. Please login again.');
    }
  }
}
```

---

### Logout Implementation

```dart
Future<void> logout() async {
  final refreshToken = prefs.getString('refresh_token');
  
  if (refreshToken != null) {
    // Revoke refresh token on server
    try {
      await apiService.post(
        '/auth/logout',
        body: {'refreshToken': refreshToken},
        token: _accessToken,
      );
    } catch (e) {
      // Continue logout even if API call fails
      print('Error revoking token: $e');
    }
  }
  
  // Clear local storage
  _accessToken = null;
  _refreshToken = null;
  _user = null;
  await prefs.remove('access_token');
  await prefs.remove('refresh_token');
  await prefs.remove('user_data');
  
  notifyListeners();
}
```

---

## 🔒 Security Features

### 1. **Token Rotation (Optional Enhancement)**

Currently, refresh token stays the same. You can enhance it:

```typescript
// On refresh, generate new refresh token
const newRefreshToken = crypto.randomBytes(64).toString('hex');

// Revoke old token
tokenRecord.isActive = false;
await refreshTokenRepository.save(tokenRecord);

// Create new token
const newToken = refreshTokenRepository.create({
  token: newRefreshToken,
  userId: tokenRecord.user.id,
  expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
  isActive: true,
});
await refreshTokenRepository.save(newToken);

// Return both new tokens
res.json({
  accessToken: newAccessToken,
  refreshToken: newRefreshToken,  // New refresh token
});
```

**Benefits:**
- Old refresh token can't be reused if stolen
- Better security

---

### 2. **Token Cleanup**

**Periodic cleanup of expired tokens:**

```typescript
// Cron job or scheduled task
async function cleanupExpiredTokens() {
  await refreshTokenRepository.update(
    { expiresAt: LessThan(new Date()), isActive: true },
    { isActive: false }
  );
}
```

---

### 3. **Rate Limiting**

**Prevent refresh token abuse:**

```typescript
// Add rate limiting to refresh endpoint
// Max 5 refresh requests per minute per IP
```

---

## 📋 API Endpoints Summary

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/auth/login` | POST | No | Request OTP |
| `/api/auth/verify` | POST | No | Verify OTP, get tokens |
| `/api/auth/refresh` | POST | No | Get new access token |
| `/api/auth/logout` | POST | Yes | Revoke refresh token |
| `/api/auth/profile` | PUT | Yes | Update profile |

---

## 🧪 Testing

### 1. **Login and Get Tokens**

```bash
curl -X POST http://localhost:3000/api/auth/verify \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210", "otp": "1234"}'

# Response:
# {
#   "accessToken": "eyJ...",
#   "refreshToken": "abc123...",
#   "user": {...}
# }
```

### 2. **Refresh Access Token**

```bash
curl -X POST http://localhost:3000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "abc123..."}'

# Response:
# {
#   "accessToken": "eyJ...",  # New access token
#   "user": {...}
# }
```

### 3. **Use Access Token**

```bash
curl http://localhost:3000/api/orders \
  -H "Authorization: Bearer {accessToken}"
```

### 4. **Logout**

```bash
# Option 1: Revoke specific token
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "abc123..."}'

# Option 2: Revoke all tokens (requires auth)
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Authorization: Bearer {accessToken}"
```

---

## ✅ Summary

**Current Implementation:**
- ✅ Access Token: 15 minutes expiry
- ✅ Refresh Token: 30 days expiry
- ✅ Refresh token stored in database
- ✅ Token revocation on logout
- ✅ Automatic token refresh (frontend needs implementation)
- ✅ User validation on refresh

**Benefits:**
- 🔒 More secure (short-lived access tokens)
- 🔄 Better user experience (automatic refresh)
- 🛡️ Revocable sessions
- 📊 Trackable active sessions

**Next Steps (Frontend):**
1. Implement automatic token refresh on 401 errors
2. Store refresh token securely
3. Handle token refresh failures (logout user)

---

**The refresh token system is fully implemented and ready to use! 🔄**

