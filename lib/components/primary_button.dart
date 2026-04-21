import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// A reusable primary action button that adapts to light/dark mode.
/// Used in: Onboarding ("Next" / "Get Started"), Login ("Get OTP"),
/// and Verification ("Verify & Continue").
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 55,
    this.borderRadius = 18,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor =
        dark ? AppColors.darkAccentButton : AppColors.lightAccentButton;
    final fgColor =
        dark ? AppColors.darkAccentButtonText : AppColors.lightAccentButtonText;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: dark ? 0 : 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}
