# 🤖 Android Setup Guide for Easy Basket

## Issues Found

1. ❌ Android cmdline-tools missing
2. ❌ Android licenses not accepted
3. ❌ No Android emulator running

## Step-by-Step Fix

### Step 1: Install Android Command Line Tools

**Option A: Via Android Studio (Recommended)**

1. Open **Android Studio**
2. Go to **Tools → SDK Manager** (or **Android Studio → Settings → Appearance & Behavior → System Settings → Android SDK**)
3. Click on **SDK Tools** tab
4. Check **Android SDK Command-line Tools (latest)**
5. Click **Apply** and wait for installation

**Option B: Manual Installation**

```bash
# Download command line tools
cd ~/Library/Android/sdk
# Create cmdline-tools directory if it doesn't exist
mkdir -p cmdline-tools
cd cmdline-tools
# Download from: https://developer.android.com/studio#command-line-tools-only
# Extract to: ~/Library/Android/sdk/cmdline-tools/latest/
```

### Step 2: Accept Android Licenses

After installing cmdline-tools, run:

```bash
flutter doctor --android-licenses
```

Press `y` for each license prompt.

### Step 3: Create Android Emulator

**Via Android Studio:**

1. Open **Android Studio**
2. Click **More Actions → Virtual Device Manager** (or **Tools → Device Manager**)
3. Click **Create Device**
4. Select a device (e.g., **Pixel 5**)
5. Click **Next**
6. Select a system image (e.g., **API 33** or **API 34**)
7. Click **Download** if needed, then **Next**
8. Click **Finish**

**Or via Command Line:**

```bash
# List available system images
sdkmanager --list | grep system-images

# Install a system image (example)
sdkmanager "system-images;android-33;google_apis;arm64-v8a"

# Create AVD
avdmanager create avd -n pixel_5 -k "system-images;android-33;google_apis;arm64-v8a"
```

### Step 4: Start Emulator

**Via Android Studio:**
1. Open **Device Manager**
2. Click **Play** button next to your emulator

**Via Command Line:**
```bash
# List emulators
flutter emulators

# Start emulator
flutter emulators --launch <emulator_id>

# Or use emulator command directly
emulator -avd <avd_name>
```

### Step 5: Verify Setup

```bash
# Check Flutter doctor
flutter doctor

# Check devices
flutter devices

# You should see your Android emulator listed
```

### Step 6: Run the App

```bash
cd mobile
flutter run -d android
```

## Quick Fix Commands

```bash
# 1. Set ANDROID_HOME (add to ~/.zshrc or ~/.bash_profile)
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# 2. Reload shell
source ~/.zshrc  # or source ~/.bash_profile

# 3. Accept licenses
flutter doctor --android-licenses

# 4. Check setup
flutter doctor
```

## Alternative: Use Web or iOS

If Android setup is taking too long, you can use:

**Web:**
```bash
cd mobile
flutter run -d chrome
```

**iOS (if you have Xcode):**
```bash
cd mobile
flutter run -d ios
```

## Troubleshooting

### "No devices found"
- Make sure emulator is running
- Check: `flutter devices`
- Start emulator from Android Studio

### "Android SDK not found"
- Set ANDROID_HOME environment variable
- Check Android Studio SDK location

### "License not accepted"
- Run: `flutter doctor --android-licenses`
- Press `y` for all prompts

### "cmdline-tools missing"
- Install via Android Studio SDK Manager
- Or download manually from Android website

## Need Help?

1. Check Android Studio is fully installed
2. Verify SDK is installed (Android Studio → SDK Manager)
3. Create and start an emulator
4. Run `flutter doctor` to check status

