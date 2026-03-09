import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// A reusable social login button (Google, Apple, etc.) with dark mode support.
/// Supports both Material icons and image assets.
class SocialButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? imagePath;
  final VoidCallback? onPressed;

  const SocialButton({
    super.key,
    required this.label,
    this.icon,
    this.imagePath,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);

    return OutlinedButton(
      onPressed: onPressed ?? () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: dark ? AppColors.darkCardSurface : Colors.grey[100],
        side: dark
            ? BorderSide(color: Colors.grey[800]!, width: 0.5)
            : BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath!,
              width: 22,
              height: 22,
            )
          else if (icon != null)
            Icon(icon, color: dark ? Colors.white : Colors.black),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: dark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
