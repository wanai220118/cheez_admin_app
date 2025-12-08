# How to Run the App on Emulator

## Prerequisites

1. **Flutter SDK** - Make sure Flutter is installed and added to your PATH
2. **Android Studio** (for Android emulator) or **Xcode** (for iOS simulator on Mac)
3. **Firebase Setup** - The app is already configured with Firebase

## Step-by-Step Instructions

### For Android Emulator:

1. **Open Android Studio**
   - Launch Android Studio
   - Go to **Tools > Device Manager** (or click the device manager icon)

2. **Create/Start an Android Emulator**
   - Click **Create Device** (if you don't have one)
   - Select a device (e.g., Pixel 5, Pixel 6)
   - Select a system image (API 33 or higher recommended)
   - Click **Finish** and wait for the emulator to download
   - Click the **Play** button to start the emulator

3. **Open Terminal/Command Prompt**
   - Navigate to your project directory:
     ```bash
     cd C:\Users\wanad\OneDrive\Desktop\cheez_admin_app
     ```

4. **Check Available Devices**
   ```bash
   flutter devices
   ```
   You should see your emulator listed (e.g., "sdk gphone64 arm64")

5. **Get Dependencies**
   ```bash
   flutter pub get
   ```

6. **Run the App**
   ```bash
   flutter run
   ```
   Or if you have multiple devices:
   ```bash
   flutter run -d <device-id>
   ```

### For iOS Simulator (Mac only):

1. **Open Xcode**
   - Launch Xcode
   - Go to **Xcode > Settings > Platforms** and install iOS Simulator if needed

2. **Open Simulator**
   - In Xcode: **Xcode > Open Developer Tool > Simulator**
   - Or use Spotlight: Search "Simulator" and open it
   - Select a device: **File > Open Simulator > iPhone 14** (or any iPhone)

3. **Run the App**
   ```bash
   cd C:\Users\wanad\OneDrive\Desktop\cheez_admin_app
   flutter pub get
   flutter run
   ```

## Quick Commands Reference

```bash
# Check Flutter setup
flutter doctor

# List available devices/emulators
flutter devices

# Get dependencies
flutter pub get

# Run the app
flutter run

# Run in release mode
flutter run --release

# Hot reload (press 'r' in terminal while app is running)
# Hot restart (press 'R' in terminal)
# Quit (press 'q' in terminal)
```

## Troubleshooting

### If Flutter is not recognized:
- Make sure Flutter is installed and added to your system PATH
- Restart your terminal/command prompt
- Verify installation: `flutter --version`

### If no devices are found:
- Make sure your emulator/simulator is running
- For Android: Check Android Studio's Device Manager
- For iOS: Check Xcode Simulator is open
- Run `flutter devices` to verify

### If you get dependency errors:
```bash
flutter clean
flutter pub get
flutter run
```

### If Firebase errors occur:
- Make sure `google-services.json` is in `android/app/`
- Verify Firebase project is properly configured
- Check `lib/firebase_options.dart` exists

## Running on Physical Device

### Android:
1. Enable **Developer Options** and **USB Debugging** on your phone
2. Connect via USB
3. Run `flutter devices` to see your device
4. Run `flutter run`

### iOS:
1. Connect iPhone via USB
2. Trust the computer on your iPhone
3. Run `flutter devices`
4. Run `flutter run`

## Notes

- The app requires Firebase authentication, so make sure you have valid credentials
- First run might take longer as it builds the app
- Use hot reload (press 'r') for quick updates during development

