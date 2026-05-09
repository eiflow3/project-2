import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';

/// CustomTextField provides a unified, pre-styled input box with premium micro-animations.
/// Centralizing input decorations prevents styling drift across different forms.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;
  final bool readOnly;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      maxLines: maxLines,
      style: AppStyles.bodyPrimary, // Core text font style
      cursorColor: AppColors.primaryLight, // Blinking cursor color matching brand
      decoration: AppStyles.customInputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
