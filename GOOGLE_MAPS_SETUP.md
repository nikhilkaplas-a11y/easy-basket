# Google Maps Setup for Address Picker

## Overview
The address picker now uses an interactive Google Maps widget with a **centered draggable pin** (like Zomato/Blinkit). Users can:
- See their current location on the map
- Pan the map to adjust location
- See a fixed pin in the center that marks the exact delivery location
- Get real-time address updates as they move the map

## Features

### ✅ Interactive Map
- Full Google Maps integration
- Pan and zoom to adjust location
- Current location button
- Street view zoom level (17.0)

### ✅ Centered Pin Design
- Fixed pin in the center of the screen (like Zomato/Blinkit)
- Map moves underneath the pin
- Real-time address updates as user pans
- Visual pin with shadow for better visibility

### ✅ Real-time Address
- Address updates automatically as user moves the map
- Shows coordinates for verification
- Loading indicator while fetching address

## Setup Required

### Step 1: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable **Maps SDK for Android** and **Maps SDK for iOS**
4. Create API Key
5. (Optional but recommended) Restrict the key to your app

### Step 2: Add API Key to Android

Edit `mobile/android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE"/>
```

Replace `YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE` with your actual API key.

### Step 3: Add API Key to iOS (if needed)

Edit `mobile/ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

// In application:didFinishLaunchingWithOptions:
GMSServices.provideAPIKey("YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE")
```

### Step 4: Rebuild the App

After adding the API key:

```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

## How It Works

### User Flow
1. User clicks "Use Current Location" or "Pick on Map"
2. Map opens with current location centered
3. **Fixed pin appears in the center** of the screen
4. User pans the map to adjust location
5. Pin stays fixed, map moves underneath
6. Address updates in real-time at the bottom
7. User confirms location

### Technical Details

- **Centered Pin**: Overlay widget fixed in center, not a map marker
- **Camera Movement**: `onCameraMove` updates coordinates
- **Address Fetching**: `onCameraIdle` fetches address when user stops panning
- **Zoom Level**: 17.0 (street view, perfect for delivery addresses)

## Web Fallback

On web, the map shows a fallback UI since Google Maps Flutter doesn't work on web. Users can still:
- Use current location
- See selected coordinates
- Confirm location

For full map experience, use mobile app (Android/iOS).

## Troubleshooting

### Map Not Showing
- Check API key is added correctly
- Verify API key has Maps SDK enabled
- Check AndroidManifest.xml has correct key
- Rebuild app after adding key

### "Failed to load map"
- API key might be invalid
- Check API key restrictions
- Verify billing is enabled (Google Maps requires billing)

### Location Not Accurate
- Check location permissions are granted
- Ensure GPS is enabled on device
- Try moving to open area for better GPS signal

## Benefits

1. **Better UX**: Visual map selection like zomato / blinkit
2. **More Accurate**: Users can fine-tune exact location
3. **Faster**: No need to type full address
4. **Professional**: Modern, polished experience
5. **Instant Delivery Ready**: Precise coordinates for delivery agents

