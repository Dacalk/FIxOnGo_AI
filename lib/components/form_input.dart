import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// A reusable labeled text input field with dark mode support.
/// Used across all signup forms for Full Name, Plate Number, etc.
class FormInput extends StatelessWidget {
  final String label;
  final String hintText;
  final String? helperText;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  const FormInput({
    super.key,
    required this.label,
    required this.hintText,
    this.helperText,
    this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final labelColor = dark ? Colors.white : Colors.black;
    final fillColor = dark ? AppColors.darkSurface : Colors.grey[100]!;
    final textColor = dark ? Colors.white : Colors.black;
    final hintColor = dark ? Colors.grey[600]! : Colors.grey[400]!;
    final helperColor = dark ? AppColors.brandYellow : AppColors.primaryBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: labelColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: fillColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: dark ? AppColors.brandYellow : AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: TextStyle(fontSize: 12, color: helperColor),
          ),
        ],
      ],
    );
  }
}
