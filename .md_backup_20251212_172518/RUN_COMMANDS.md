# 🚀 Run Commands - Easy Basket

## Quick Start Commands

### 1. Start Backend Server

```bash
cd backend
npm run dev
```

**Or if backend is not running:**
```bash
cd backend
npm install  # First time only
npm run dev
```

Backend will run on: `http://localhost:3000`

---

### 2. Start Flutter App

#### Option A: Run on Chrome (Web) - Fastest
```bash
cd mobile
flutter run -d chrome
```

#### Option B: Run on Android Emulator
```bash
cd mobile
flutter run -d android
```

#### Option C: Run on iOS Simulator (Mac only)
```bash
cd mobile
flutter run -d ios
```

---

## Complete Setup (First Time)

### Backend Setup
```bash
# Navigate to backend
cd backend

# Install dependencies (first time only)
npm install

# Create .env file (if not exists)
cp .env.example .env

# Edit .env with your database credentials
# DB_HOST=localhost
# DB_PORT=3306
# DB_USER=root
# DB_PASS=your_password
# DB_NAME=easy_basket

# Seed sample data (optional)
npm run seed

# Start backend
npm run dev
```

### Flutter Setup
```bash
# Navigate to mobile
cd mobile

# Get dependencies (first time only)
flutter pub get

# Run the app
flutter run -d chrome
```

---

## One-Line Commands

### Start Everything (Terminal 1 - Backend)
```bash
cd backend && npm run dev
```

### Start Everything (Terminal 2 - Flutter)
```bash
cd mobile && flutter run -d chrome
```

---

## Check if Services are Running

### Check Backend
```bash
curl http://localhost:3000/
# Should return: "Easy Basket Backend is running"
```

### Check Flutter Devices
```bash
cd mobile
flutter devices
```

---

## Troubleshooting

### Backend not starting?
```bash
cd backend
# Check if port 3000 is in use
lsof -i :3000
# Kill process if needed
kill -9 <PID>
# Then start again
npm run dev
```

### Flutter not running?
```bash
cd mobile
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

### Database connection error?
- Make sure MySQL is running
- Check `.env` file has correct credentials
- Verify database exists: `CREATE DATABASE easy_basket;`

---

## Development Workflow

1. **Terminal 1** - Backend:
   ```bash
   cd backend
   npm run dev
   ```

2. **Terminal 2** - Flutter:
   ```bash
   cd mobile
   flutter run -d chrome
   ```

3. **Make changes** - Hot reload will update automatically!

---

## Quick Test

1. **Backend running?** → Open `http://localhost:3000/api/categories`
2. **Flutter running?** → App opens in browser/emulator
3. **Login** → Phone: any number, OTP: `1234`
4. **Test** → Browse products, add to cart, place order!

---

**Happy Coding! 🎉**

