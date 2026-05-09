import 'package:flutter/material.dart';
import 'colors.dart';

/// AppStyles contains the typography, shadows, margins, and card decorations used
/// throughout the system. Centralizing these ensures structural consistency across screens.
class AppStyles {
  // Border radius configurations for ultra-premium modern interfaces
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  // Premium elevation shadow styling
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 15.0,
      offset: const Offset(0, 8),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: AppColors.primaryLight.withOpacity(0.05),
      blurRadius: 30.0,
      offset: const Offset(0, 4),
      spreadRadius: -5,
    ),
  ];

  // Premium typography system (Self-contained and highly legible)
  static const TextStyle heading1 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle subheading = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyPrimary = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySecondary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle priceLarge = TextStyle(
    color: AppColors.primaryLight,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );

  // Modern input text field style builder
  static InputDecoration customInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: AppColors.primaryLight),
      prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      // Idle border outline
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.surfaceLight, width: 1.5),
      ),
      // Active border outline (vibrant glow)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2.0),
      ),
      // Validation error border
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
    );
  }

  // Beautiful modern card decoration builder (supports glassmorphic look)
  static BoxDecoration glassCardDecoration({bool hasGlow = false}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: hasGlow ? AppColors.primary.withOpacity(0.3) : AppColors.surfaceLight,
        width: 1.5,
      ),
      boxShadow: premiumShadow,
    );
  }
}
