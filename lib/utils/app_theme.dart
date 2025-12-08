import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color colorLightGray = Color(0xFFB4B0BF); // #B4B0BF (note: corrected from B4BOBF)
  static const Color colorBlueGray = Color(0xFF7E8EAA);  // #7E8EAA
  static const Color colorDarkBrown = Color(0xFF783D2E);  // #783D2E
  static const Color colorTan = Color(0xFF9B7F5B);       // #9B7F5B
  static const Color colorGoldenBrown = Color(0xFFB18552); // #B18552

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: colorDarkBrown, // #783D2E - Primary color
        onPrimary: Colors.white,
        secondary: colorGoldenBrown, // #B18552 - Secondary color
        onSecondary: Colors.white,
        tertiary: colorTan, // #9B7F5B
        onTertiary: Colors.white,
        error: colorDarkBrown,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: colorDarkBrown,
        surfaceVariant: colorLightGray.withOpacity(0.3),
        onSurfaceVariant: colorDarkBrown,
        outline: colorLightGray,
        shadow: colorDarkBrown.withOpacity(0.2),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorDarkBrown, // Using primary color
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorDarkBrown, // Primary color
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorDarkBrown, // Primary color
          textStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorLightGray.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorLightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorLightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorDarkBrown, width: 2), // Primary color
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorDarkBrown),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Outfit',
          color: colorDarkBrown,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Outfit',
          color: colorLightGray,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Mirador',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colorDarkBrown,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Mirador',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: colorDarkBrown,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Mirador',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorDarkBrown,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorDarkBrown,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorDarkBrown,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorDarkBrown,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorDarkBrown,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorDarkBrown,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorDarkBrown,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          color: colorDarkBrown,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          color: colorDarkBrown,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          color: colorDarkBrown,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorDarkBrown,
        ),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: colorDarkBrown, // Primary color
        size: 24,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorGoldenBrown,
        foregroundColor: Colors.white,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorLightGray.withOpacity(0.5),
        thickness: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorLightGray.withOpacity(0.2),
        labelStyle: TextStyle(
          fontFamily: 'Outfit',
          color: colorDarkBrown,
        ),
        selectedColor: colorDarkBrown, // Primary color
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Scaffold Background
      scaffoldBackgroundColor: Colors.grey[50],
    );
  }
}
