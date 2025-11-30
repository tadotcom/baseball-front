import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFF2196F3);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color scaffoldBackgroundColor = Color(0xFFF5F5F5);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundColor,
        surface: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onBackground: textPrimaryColor,
        onSurface: textPrimaryColor,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.3,
          )
      ),
      textTheme: _buildTextTheme(ThemeData.light().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: secondaryColor,
            side: const BorderSide(color: secondaryColor, width: 1),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          )
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondaryColor),
        hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.1),
        labelStyle: TextStyle(color: primaryColor, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
    );
  }


  static TextTheme _buildTextTheme(TextTheme base) {
    // TODO: Consider using Google Fonts package (google_fonts) for specific fonts if needed.

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2, color: textPrimaryColor),
      displayMedium: base.displayMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3, color: textPrimaryColor),
      displaySmall: base.displaySmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4, color: textPrimaryColor),

      headlineMedium: base.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2, color: textPrimaryColor),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3, color: textPrimaryColor),
      titleLarge: base.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4, color: textPrimaryColor),

      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: textPrimaryColor),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, color: textPrimaryColor),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, color: textSecondaryColor),

      labelLarge: base.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, height: 1.2),

    ).apply(
      bodyColor: textPrimaryColor,
      displayColor: textPrimaryColor,
    );
  }
}