import 'package:flutter/material.dart';
import 'colors.dart';

/// AppStyles contains the typography, shadows, margins, and card decorations used
/// throughout the system. Centralizing these ensures structural consistency across screens.
class AppStyles {
  // Border radius configurations for ultra-premium, sharp, and technical modern interfaces.
  // We avoid bulky rounded "bubbles" (16px/24px) in favor of high-precision Swiss-inspired
  // sharp micro-radii (4px/6px/8px). This mimics high-end trading terminals and SaaS dashboards.
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 6.0;
  static const double radiusLarge = 8.0;

  // Tight, flat drop shadows for precise, professional depth without blurry glowing edges.
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 4.0,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // Premium typography system (Self-contained, highly readable, and optimized for data density)
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

  // Modern input text field style builder with thin borders and sharp corners
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
      // Idle border outline - sharp radius and thin 1.0px hairline
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.surfaceLight, width: 1.0),
      ),
      // Active border outline - sharp radius and thin glowing border
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      // Validation error borders
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  // High-precision minimalist card decoration builder with crisp thin borders and flat shadows
  static BoxDecoration glassCardDecoration({bool hasGlow = false}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: hasGlow ? AppColors.primary.withOpacity(0.3) : AppColors.surfaceLight,
        width: 1.0, // Ultra-thin 1px border for premium hairline layout divisions
      ),
      boxShadow: premiumShadow,
    );
  }
}
