import 'package:flutter/material.dart';

/// AppColors contains the entire dark-themed color palette for the offline application.
/// It uses a sleek Slate base with vibrant Teal/Emerald primaries and Indigo accents
/// to create a premium, modern, and trustworthy financial/order tracking atmosphere.
class AppColors {
  // Slate background and surface colors (Sleek dark mode)
  static const Color background = Color(0xFF0F172A); // Slate 900: App background
  static const Color surface = Color(0xFF1E293B);    // Slate 800: Card/Panel background
  static const Color surfaceLight = Color(0xFF334155); // Slate 700: Border/Highlight colors

  // Premium, harmonious brand colors (Teal & Emerald represent growth and commerce)
  static const Color primary = Color(0xFF0D9488);    // Teal 600: Core buttons, selection lines
  static const Color primaryLight = Color(0xFF14B8A6); // Teal 500: Active text and highlights
  static const Color accent = Color(0xFF6366F1);     // Indigo 500: Special badges and links
  
  // Status and utility colors
  static const Color success = Color(0xFF10B981);    // Emerald 500: Completed order, profitable metric
  static const Color warning = Color(0xFFF59E0B);    // Amber 500: Pending status, mid-stock items
  static const Color error = Color(0xFFEF4444);      // Red 500: Cancelled status, out-of-stock, delete actions

  // Sleek text colors (High contrast, highly legible)
  static const Color textPrimary = Color(0xFFF8FAFC);  // Slate 50: High-contrast white text
  static const Color textSecondary = Color(0xFF94A3B8);// Slate 400: Muted grey text
  static const Color textMuted = Color(0xFF64748B);    // Slate 500: Disabled state text

  // Premium glassmorphic linear gradient definitions
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF059669)], // Teal to Emerald
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], // Indigo gradients
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)], // Slate 800 to Slate 900
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
