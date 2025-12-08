# How to Generate App Icons

## The icons haven't been generated yet! Follow these steps:

### Step 1: Make sure you have logo.png
- Place your `logo.png` file in the `assets/icons/` folder
- If you only have `logoapp.png`, either:
  - Rename it to `logo.png`, OR
  - Update `pubspec.yaml` line 28 to use `"assets/icons/logoapp.png"`

### Step 2: Install the package and generate icons

Open your terminal/command prompt in the project folder and run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### Step 3: Clean and rebuild

After generating icons, you need to rebuild the app:

```bash
flutter clean
flutter pub get
flutter run
```

## Alternative: If you want to use logoapp.png instead

If you prefer to use the existing `logoapp.png` file, update `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icons/logoapp.png"
  adaptive_icon_background: "#FF9800"
  adaptive_icon_foreground: "assets/icons/logoapp.png"
```

Then run the commands above.

## Important Notes:

- The icon generation command (`flutter pub run flutter_launcher_icons`) must be run manually - it doesn't happen automatically
- After generating icons, you MUST do a clean rebuild (`flutter clean`) for the changes to take effect
- The logo image should be square and at least 1024x1024 pixels for best results

## Troubleshooting:

If the icon still doesn't change:
1. Make sure you ran `flutter clean` after generating icons
2. Uninstall the app from your device/emulator completely
3. Reinstall the app with `flutter run`
4. Check that the `image_path` in `pubspec.yaml` points to the correct file location

