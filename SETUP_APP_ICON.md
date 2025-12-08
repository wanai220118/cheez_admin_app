# Setting Up App Icon and Name

## Changes Made:
1. ✅ Updated app name to "Cheezn'Cream Co." in AndroidManifest.xml
2. ✅ Updated app title in main.dart
3. ✅ Added flutter_launcher_icons package configuration

## Next Steps to Generate App Icons:

### Option 1: If you have logo.png (recommended)
1. Place your `logo.png` file in `assets/icons/` folder
2. Update `pubspec.yaml` to use `logo.png`:
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: false
     image_path: "assets/icons/logo.png"
   ```

### Option 2: Use existing logoapp.png
The configuration is already set to use `logoapp.png`. Just run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

This will generate all the required icon sizes for Android automatically.

## After Generating Icons:

1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Verify the changes:**
   - The app name should show as "Cheezn'Cream Co." on your device
   - The app icon should be your logo

## Notes:
- The logo image should be at least 1024x1024 pixels for best results
- Square images work best for app icons
- The package will automatically generate all required sizes (hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)

