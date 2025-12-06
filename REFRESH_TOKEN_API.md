# 🔄 Refresh Token API Reference

Quick reference for the refresh token endpoint.

---

## 📍 Endpoint

**URL:** `POST /api/auth/refresh`

**Authentication:** Not required (public endpoint)

---

## 📤 Request

### Headers
```
Content-Type: application/json
```

### Body
```json
{
  "refreshToken": "your-refresh-token-here"
}
```

### Example (cURL)
```bash
curl -X POST http://localhost:3000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "a1b2c3d4e5f6..."}'
```

### Example (Production)
```bash
curl -X POST https://api.easybasket.in/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "a1b2c3d4e5f6..."}'
```

---

## 📥 Response

### Success (200 OK)
```json
{
  "message": "Token refreshed successfully",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "phoneNumber": "9876543210",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "customer"
  }
}
```

### Error Responses

#### 400 Bad Request - Missing Token
```json
{
  "message": "Refresh token is required"
}
```

#### 401 Unauthorized - Invalid Token
```json
{
  "message": "Invalid refresh token"
}
```

#### 401 Unauthorized - Expired Token
```json
{
  "message": "Refresh token expired"
}
```

#### 401 Unauthorized - Inactive User
```json
{
  "message": "User account is inactive"
}
```

#### 500 Internal Server Error
```json
{
  "message": "Internal server error"
}
```

---

## 🔑 How It Works

1. **Client sends refresh token** in request body
2. **Backend validates:**
   - Token exists in database
   - Token is active (`isActive: true`)
   - Token not expired
   - User is active
3. **Backend generates new access token** (15 minutes expiry)
4. **Backend returns:**
   - New access token
   - User information
   - Refresh token stays the same (not rotated)

---

## 📱 Flutter Integration Example

```dart
// Refresh access token
Future<Map<String, dynamic>?> refreshAccessToken(String refreshToken) async {
  try {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'accessToken': data['accessToken'],
        'user': data['user'],
      };
    } else {
      // Handle error
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to refresh token');
    }
  } catch (e) {
    throw Exception('Error refreshing token: $e');
  }
}

// Usage in AuthProvider
Future<void> refreshToken() async {
  final refreshToken = prefs.getString('refresh_token');
  if (refreshToken == null) {
    logout();
    return;
  }

  try {
    final result = await refreshAccessToken(refreshToken);
    if (result != null) {
      _accessToken = result['accessToken'];
      _user = UserModel.fromJson(result['user']);
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString('user_data', jsonEncode(result['user']));
      notifyListeners();
    }
  } catch (e) {
    // Refresh failed, logout user
    logout();
  }
}
```

---

## 🔄 Automatic Token Refresh Flow

```dart
// In API service, handle 401 errors
Future<dynamic> get(String endpoint, {String? token}) async {
  final response = await http.get(
    Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
    headers: {
      'Authorization': token != null ? 'Bearer $token' : '',
      'Content-Type': 'application/json',
    },
  );

  // If access token expired, try to refresh
  if (response.statusCode == 401) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshToken();
    
    // Retry request with new token
    if (authProvider.token != null) {
      return await get(endpoint, token: authProvider.token);
    } else {
      throw Exception('Session expired. Please login again.');
    }
  }

  // Handle other errors
  if (response.statusCode != 200) {
    throw Exception('Request failed: ${response.statusCode}');
  }

  return jsonDecode(response.body);
}
```

---

## 🧪 Testing

### 1. Get Refresh Token (Login)
```bash
# First, login to get tokens
curl -X POST http://localhost:3000/api/auth/verify \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210", "otp": "1234"}'

# Response includes refreshToken
```

### 2. Refresh Access Token
```bash
# Use the refreshToken from step 1
curl -X POST http://localhost:3000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "YOUR_REFRESH_TOKEN_HERE"}'

# Response includes new accessToken
```

### 3. Use New Access Token
```bash
# Use the new accessToken for API requests
curl http://localhost:3000/api/orders \
  -H "Authorization: Bearer NEW_ACCESS_TOKEN_HERE"
```

---

## 📋 Token Lifecycle

```
Login (verify)
  ↓
Get: accessToken (15 min) + refreshToken (30 days)
  ↓
Use accessToken for API requests
  ↓
Access token expires (after 15 min)
  ↓
Call /api/auth/refresh with refreshToken
  ↓
Get: new accessToken (15 min)
  ↓
Continue using new accessToken
  ↓
Repeat until refreshToken expires (30 days)
  ↓
User must login again
```

---

## ✅ Summary

**Endpoint:** `POST /api/auth/refresh`

**Request:**
```json
{ "refreshToken": "..." }
```

**Response:**
```json
{
  "accessToken": "...",
  "user": {...}
}
```

**Use Case:** Get a new access token when the current one expires (after 15 minutes)

**Refresh Token Validity:** 30 days

---

**The refresh token API is ready to use! 🔄**

