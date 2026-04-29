import 'package:flutter/material.dart';
import '../models/towing_service.dart';
import '../../../theme_provider.dart';

class ServiceCard extends StatelessWidget {
  final TowingService service;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final primaryColor = isSelected ? AppColors.emergencyRed : (dark ? AppColors.darkSurface : Colors.white);
    final textColor = isSelected ? Colors.white : (dark ? Colors.white : Colors.black87);
    final subtitleColor = isSelected ? Colors.white.withAlpha(204) : (dark ? Colors.grey[400] : Colors.grey[600]);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.emergencyRed : (dark ? Colors.grey[800]! : Colors.grey[300]!),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.emergencyRed.withAlpha(76),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(51) : AppColors.emergencyRed.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                service.icon,
                color: isSelected ? Colors.white : AppColors.emergencyRed,
                size: 28,
              ),
            ),
            const Spacer(),
            Text(
              service.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              service.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Starts at Rs. ${service.basePrice.toInt()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.emergencyRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
