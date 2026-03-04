# Twilio OTP Setup (Verify API)

This project uses **Twilio Verify API v2** for sending and verifying OTP over SMS. When Twilio is configured, real SMS OTP is used; when not configured, the app accepts the dev OTP `1234` for testing.

## Required account details

Add these to your `.env` file in the `backend` directory:

| Variable | Description | Example |
|----------|-------------|---------|
| `TWILIO_ACCOUNT_SID` | Your Twilio Account SID | `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| `TWILIO_AUTH_TOKEN` | Your Twilio Auth Token | (from Console) |
| `TWILIO_VERIFY_SERVICE_SID` | Verify Service SID | `VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |

## How to get them

1. **Sign up / log in**: https://www.twilio.com  
2. **Account SID & Auth Token**:  
   - Twilio Console → **Account** → **Account Info**  
   - Copy **Account SID** and **Auth Token** (click “Show” for token).  
3. **Verify Service SID**:  
   - Console → **Explore Products** → **Verify** → **Services**  
   - Click **Create new**  
   - Name it (e.g. “Easy Basket OTP”) and choose **SMS** (or SMS + Voice)  
   - After creation, copy the **Service SID** (starts with `VA`).

## .env example

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Phone number format

- Twilio expects numbers in **E.164** (e.g. `+919876543210`).  
- The backend normalizes Indian 10-digit numbers (e.g. `9876543210`) to `+91` automatically.  
- For other countries, send the number with country code or ensure your app sends E.164; you can extend `TwilioService.normalizePhoneToE164()` if needed.

## Flow

- **POST /api/auth/login** with `{ "phoneNumber": "9876543210" }` → sends OTP via Twilio (or returns “Use 1234” in dev).  
- **POST /api/auth/verify** with `{ "phoneNumber": "9876543210", "otp": "123456" }` → verifies with Twilio and returns JWT on success.

## Troubleshooting

- **“Twilio credentials not configured”**: Ensure all three env vars are set and the server was restarted after changing `.env`.  
- **Invalid phone / 21212**: Use E.164; for India use 10 digits (backend adds +91) or `+91...`.  
- **OTP not received**: Check Twilio Verify logs in the Console and that the number is verified (trial accounts may require verified numbers).
