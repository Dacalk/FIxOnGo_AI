import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Animated page indicator dots for paginated views (e.g. onboarding).
/// Used in: Onboarding screen.
class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalPages;

  const PageIndicator({
    super.key,
    required this.currentIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 8),
          height: 8,
          width: currentIndex == index ? 24 : 8,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? (dark ? AppColors.darkDotActive : AppColors.lightDotActive)
                : (dark
                    ? AppColors.darkDotInactive
                    : AppColors.lightDotInactive),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
