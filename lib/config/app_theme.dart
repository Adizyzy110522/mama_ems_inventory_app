import 'package:flutter/material.dart';

/// App theme configuration.
/// Contains all theme-related settings for consistent appearance across the app.
class AppTheme {
  // App-wide colors
  static const Color primaryColor = Color(0xFF1E88E5); // Blue 600
  static const Color primaryDarkColor = Color(0xFF1565C0); // Blue 800
  static const Color accentColor = Color(0xFF26A69A); // Teal 400
  static const Color backgroundColor = Color(0xFFF5F5F5); // Grey 100
  static const Color cardColor = Colors.white;
  
  // Status colors
  static const Color completedColor = Color(0xFF4CAF50); // Green
  static const Color cancelledColor = Color(0xFFF44336); // Red
  static const Color processingColor = Color(0xFFFF9800); // Orange
  static const Color holdColor = Color(0xFF9C27B0); // Purple
  static const Color paidColor = Color(0xFF4CAF50); // Green
  static const Color unpaidColor = Color(0xFFFFEB3B); // Yellow
  static const Color pendingPaymentColor = Color(0xFFFFEB3B); // Yellow
  
  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121); // Grey 900
  static const Color textSecondaryColor = Color(0xFF757575); // Grey 600
  static const Color textLightColor = Color(0xFFBDBDBD); // Grey 400
  
  // Border radius
  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  
  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Spacings
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  
  // Get a color for order status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return completedColor;
      case 'cancelled':
        return cancelledColor;
      case 'hold':
        return holdColor;
      case 'processing':
      default:
        return processingColor;
    }
  }
  
  // Get a color for payment status
  static Color getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return paidColor;
      case 'unpaid':
        return unpaidColor;
      case 'pending':
        return pendingPaymentColor;
      case 'cancelled':
        return cancelledColor;
      default:
        return pendingPaymentColor;
    }
  }
  
  /// Get the app's theme data
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: cardColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      // Use material properties directly instead of card theme
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(cardBorderRadius),
            bottomRight: Radius.circular(cardBorderRadius),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: mediumSpacing * 1.5,
            vertical: smallSpacing,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: cancelledColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: mediumSpacing,
          vertical: smallSpacing,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        space: mediumSpacing,
      ),
    );
  }
}
