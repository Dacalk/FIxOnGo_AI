import 'package:flutter/material.dart';

class TowingService {
  final String id;
  final String title;
  final String description;
  final double basePrice;
  final IconData icon;

  const TowingService({
    required this.id,
    required this.title,
    required this.description,
    required this.basePrice,
    required this.icon,
  });

  static List<TowingService> getMockServices() {
    return [
      const TowingService(
        id: 'emergency_tow',
        title: 'Emergency Tow',
        description: 'High priority. Rapid response for critical situations.',
        basePrice: 2500.0,
        icon: Icons.emergency_share,
      ),
      const TowingService(
        id: 'flatbed_tow',
        title: 'Flatbed Tow',
        description: 'Specialized transport for luxury or damaged vehicles.',
        basePrice: 3500.0,
        icon: Icons.airport_shuttle,
      ),
      const TowingService(
        id: 'roadside_help',
        title: 'Roadside Help',
        description: 'Battery jump, fuel delivery, or flat tire change.',
        basePrice: 1500.0,
        icon: Icons.build_circle,
      ),
    ];
  }
}
