# ✅ Google Maps API Key Added

## What I Did

✅ Added your API key to `mobile/android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyDoK9ANjz95e64YlDQsSv56RNpD91zftQA"/>
```

## Next Steps

### 1. Rebuild the App

```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

### 2. Test the Map

1. Run the app on Android device/emulator
2. Go to "Add Address" screen
3. Click "Use Current Location" or "Pick on Map"
4. You should see:
   - ✅ Interactive Google Maps
   - ✅ Centered pin (like Zomato/Blinkit)
   - ✅ Real-time address updates
   - ✅ Ability to pan and adjust location

### 3. Verify API Key is Working

If you see:
- ✅ Map loads successfully → API key is working!
- ❌ "Map not available" or blank screen → Check API key restrictions

## Important: API Key Restrictions (Recommended)

To protect your API key, add restrictions in Google Cloud Console:

1. Go to: https://console.cloud.google.com/apis/credentials
2. Click on your API key
3. Under **"API restrictions"**:
   - Select "Restrict key"
   - Check only: ✅ **Maps SDK for Android**
4. Under **"Application restrictions"** (optional):
   - Select "Android apps"
   - Package name: `com.easybasket.app`
   - SHA-1: Get from debug keystore (see below)

### Get SHA-1 for Android Restriction

**For Debug (Development):**
```bash
cd mobile/android
./gradlew signingReport
```

Look for `SHA1:` under debug variant, or:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy the SHA-1 value and add it in Google Cloud Console.

## Troubleshooting

### Map Not Showing
- ✅ API key is added correctly
- Check: API key has "Maps SDK for Android" enabled
- Check: Billing is enabled in Google Cloud
- Rebuild app after adding key

### "API key not valid"
- Verify key is correct (no extra spaces)
- Check key is enabled for Maps SDK
- Wait a few minutes after enabling (propagation delay)

### "This API key is not authorized"
- Go to Google Cloud Console → Credentials
- Check API restrictions include "Maps SDK for Android"
- Check application restrictions match your package name

## Security Note

⚠️ **Don't commit API key to public repositories!**

If using Git, make sure `.gitignore` includes:
- `android/app/src/main/AndroidManifest.xml` (if you want to keep key private)
- OR use environment variables (advanced)

For now, since this is your project, it's okay, but be careful if making it public.

## Test It Now!

Run the app and test the map picker:
```bash
cd mobile
flutter run -d android
```

The map should now work with the centered pin feature! 🗺️✨

