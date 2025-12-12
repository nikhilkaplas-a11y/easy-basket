# 🚀 Easy Basket - Quick Start Commands

## ⚡ Fastest Way to Run Everything

### 1. Start Backend (Terminal 1)
```bash
cd backend
npm run dev
```
✅ Backend runs on: `http://localhost:3000`

### 2. Start Flutter App (Terminal 2)
```bash
cd mobile
flutter pub get    # First time only
flutter run        # Run the app
```

## 📱 Platform-Specific Commands

### Android
```bash
cd mobile
flutter run -d android
```

### iOS
```bash
cd mobile
flutter run -d ios
```

### Web
```bash
cd mobile
flutter run -d chrome
```

## ⚙️ Important: Configure API URL First!

**Edit:** `mobile/lib/config/app_config.dart`

```dart
// For Android Emulator
static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

// For iOS Simulator
static const String apiBaseUrl = 'http://localhost:3000/api';

// For Physical Device (replace with your IP)
static const String apiBaseUrl = 'http://192.168.1.100:3000/api';
```

**Find your IP:**
- Mac/Linux: `ifconfig | grep "inet " | grep -v 127.0.0.1`
- Windows: `ipconfig`

## 🧪 Test the Setup

1. **Test Backend:**
   ```bash
   curl http://localhost:3000/
   # Should return: "Easy Basket Backend is running"
   ```

2. **Test API:**
   ```bash
   curl http://localhost:3000/api/categories
   # Should return: [] (empty array)
   ```

3. **Test App:**
   - Launch app
   - Enter phone number
   - Use OTP: `1234` (development mode)

## 📋 Complete Workflow

```bash
# Terminal 1: Backend
cd backend
npm run dev

# Terminal 2: Flutter App
cd mobile
flutter pub get
flutter run
```

## 🛠️ Troubleshooting

### "Network error" or "Connection refused"
- ✅ Backend running? Check: `curl http://localhost:3000/`
- ✅ API URL correct in `app_config.dart`?
- ✅ Same WiFi network? (for physical devices)

### "No devices found"
- ✅ Start emulator/simulator
- ✅ Check: `flutter devices`

### Build errors
```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

## 📚 More Info

- **Backend Docs:** `backend/README.md`
- **Mobile Docs:** `mobile/README.md`
- **Run Commands:** `mobile/RUN_COMMANDS.md`

---

**Happy Coding! 🎉**

