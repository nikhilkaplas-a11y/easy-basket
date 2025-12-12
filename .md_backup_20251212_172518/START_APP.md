# 🚀 Easy Basket - Quick Start Guide

## Start Backend

```bash
cd backend
npm run dev
```

Backend will run on: `http://localhost:3000`

## Start Flutter App

### Option 1: Using Run Script (Easiest)
```bash
cd mobile
./run.sh
```

### Option 2: Manual Commands
```bash
cd mobile
flutter pub get
flutter run
```

## Important Configuration

**Before running the app, update API URL:**

Edit `mobile/lib/config/app_config.dart`:

- **Android Emulator:** `http://10.0.2.2:3000/api`
- **iOS Simulator:** `http://localhost:3000/api`  
- **Physical Device:** `http://YOUR_IP:3000/api`

## Quick Test

1. Start backend: `cd backend && npm run dev`
2. Start app: `cd mobile && flutter run`
3. Login with phone number
4. Use OTP: `1234` (development mode)

## Full Documentation

- Backend: `backend/README.md`
- Mobile: `mobile/README.md`
- Run Commands: `mobile/RUN_COMMANDS.md`

