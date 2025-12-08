# Font Setup Instructions

## Current Setup: Using Google Fonts

The app is currently configured to use **Google Fonts** package, which automatically loads fonts from Google's servers. This works immediately without downloading fonts.

### Current Fonts:
- **Playfair Display** (similar to Mirador) - Used for display/heading text
- **Outfit** - Used for body text, buttons, and UI elements

## Option 1: Keep Google Fonts (Current - Works Now) ✅

The app works immediately with Google Fonts. No action needed!

## Option 2: Use Custom Font Files (For Offline Support)

If you want to use the exact **Mirador** font (not available on Google Fonts) or want offline font support:

### Step 1: Download Fonts

#### Mirador Font (if you have it):
- Mirador-Regular.ttf
- Mirador-Bold.ttf

#### Outfit Font:
- Outfit-Regular.ttf
- Outfit-Medium.ttf
- Outfit-SemiBold.ttf
- Outfit-Bold.ttf

### Step 2: Where to Download

1. **Outfit** - Google Fonts:
   - https://fonts.google.com/specimen/Outfit
   - Click "Download family" to get all weights

2. **Mirador** - Check:
   - Your design software (Figma, Adobe, etc.)
   - Font foundries or purchase if needed
   - Note: Mirador is not available on Google Fonts, so you'll need to source it separately

### Step 3: Organize Font Files

1. Create the fonts folder structure:
   ```
   assets/
     fonts/
       Mirador-Regular.ttf (if available)
       Mirador-Bold.ttf (if available)
       Outfit-Regular.ttf
       Outfit-Medium.ttf
       Outfit-SemiBold.ttf
       Outfit-Bold.ttf
   ```

2. Place all font files in `assets/fonts/` folder

3. Update `lib/utils/app_theme.dart` to use local fonts instead of Google Fonts

### Step 4: Verify Configuration

After adding fonts, run:

```bash
flutter pub get
flutter clean
flutter run
```

## Font Usage in App

- **Display/Headings**: Playfair Display (Google Fonts) or Mirador (if custom)
- **Body Text/UI**: Outfit (Google Fonts or custom)

## Note

The current setup with Google Fonts works perfectly and provides a beautiful, professional look. Custom fonts are optional and mainly needed for:
- Offline support
- Exact brand font matching (Mirador)
- Reduced data usage

