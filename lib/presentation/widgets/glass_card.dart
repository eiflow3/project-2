import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';

/// GlassCard is a premium card container widget with glassmorphism design traits.
/// It displays widgets with custom margins, padding, subtle borders, and soft shadows,
/// providing consistent modern depth in our Slate UI.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool hasGlow; // Activates a vibrant glowing border for featured cards

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8.0),
      // Uses the stylized card decoration with borders and drop shadows
      decoration: AppStyles.glassCardDecoration(hasGlow: hasGlow),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Container(
          // Adds a subtle inner gradient overlay to mimic glass panel textures
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.015),
                Colors.black.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
