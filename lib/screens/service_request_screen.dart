import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../components/primary_button.dart';

/// Service type data model
class ServiceOption {
  final String title;
  final String subtitle;
  final String price;
  final String eta;
  final IconData icon;

  const ServiceOption({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.eta,
    required this.icon,
  });
}

/// Service request screen with map area and service type selector.
/// Shows available roadside services with prices and estimated arrival times.
class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  int _selectedIndex = 0; // Default to "Towing"

  static const List<ServiceOption> _services = [
    ServiceOption(
      title: 'Towing',
      subtitle: 'Flatbed or wheel-lift',
      price: 'RS.2500',
      eta: '12 mins',
      icon: Icons.local_shipping_outlined,
    ),
    ServiceOption(
      title: 'On-site Repair',
      subtitle: 'Minor fixes on the spot',
      price: 'RS.2000',
      eta: '18 mins',
      icon: Icons.build_outlined,
    ),
    ServiceOption(
      title: 'Engine Diagnostics',
      subtitle: 'Full scan & troubleshooting',
      price: 'RS.3000',
      eta: '24 mins',
      icon: Icons.settings_suggest_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Map Area (placeholder) ──
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: _buildMapPlaceholder(dark),
          ),

          // ── Back Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkSurface : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          // ── Location Bar ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 64,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Little Adams Peak',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── My Location Button ──
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.47,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.my_location,
                color: dark ? Colors.white : Colors.black87,
                size: 22,
              ),
            ),
          ),

          // ── Bottom Sheet: Service Selection ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Service Type',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Service cards
                    ...List.generate(_services.length, (index) {
                      return _buildServiceCard(
                        _services[index],
                        isSelected: _selectedIndex == index,
                        onTap: () => setState(() => _selectedIndex = index),
                        dark: dark,
                      );
                    }),

                    const SizedBox(height: 16),

                    // Request button — label changes based on selection
                    PrimaryButton(
                      label: _selectedIndex == 0
                          ? 'Request Tow'
                          : 'Request Mechanic',
                      onPressed: () {
                        // TODO: Handle service request
                      },
                      borderRadius: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Map placeholder with subtle styling
  Widget _buildMapPlaceholder(bool dark) {
    return Container(
      color: dark ? const Color(0xFF1A2640) : const Color(0xFFE8ECF2),
      child: Stack(
        children: [
          // Grid lines to simulate map
          CustomPaint(
            size: Size.infinite,
            painter: _MapGridPainter(dark: dark),
          ),
          // Location pins
          Positioned(
            left: MediaQuery.of(context).size.width * 0.35,
            top: MediaQuery.of(context).size.height * 0.25,
            child: _buildMapPin(dark),
          ),
          // Service provider pins (trucks/mechanics nearby)
          Positioned(
            right: MediaQuery.of(context).size.width * 0.15,
            top: MediaQuery.of(context).size.height * 0.12,
            child: _buildServiceProviderPin(dark),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.12,
            top: MediaQuery.of(context).size.height * 0.16,
            child: _buildServiceProviderPin(dark),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.55,
            top: MediaQuery.of(context).size.height * 0.30,
            child: _buildServiceProviderPin(dark),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(bool dark) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
        Container(width: 2, height: 10, color: AppColors.primaryBlue),
      ],
    );
  }

  Widget _buildServiceProviderPin(bool dark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: dark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.local_shipping_outlined,
        color: dark ? Colors.white : AppColors.primaryBlue,
        size: 18,
      ),
    );
  }

  /// A single service option card
  Widget _buildServiceCard(
    ServiceOption service, {
    required bool isSelected,
    required VoidCallback onTap,
    required bool dark,
  }) {
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final titleColor = dark ? Colors.white : Colors.black;
    final subtitleColor = dark ? Colors.grey[500]! : Colors.grey[600]!;
    final priceColor = dark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primaryBlue, width: 2)
              : Border.all(
                  color: dark ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: dark
                    ? AppColors.primaryBlue.withValues(alpha: 0.15)
                    : AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(service.icon, color: AppColors.primaryBlue, size: 24),
            ),
            const SizedBox(width: 14),
            // Title & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.subtitle,
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                ],
              ),
            ),
            // Price & ETA
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service.price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: priceColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.eta,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple grid painter to simulate a map background
class _MapGridPainter extends CustomPainter {
  final bool dark;

  _MapGridPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dark
          ? Colors.grey[800]!.withValues(alpha: 0.3)
          : Colors.grey[300]!.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Draw vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw a few "road" lines
    final roadPaint = Paint()
      ..color = dark
          ? Colors.cyan.withValues(alpha: 0.15)
          : Colors.blue.withValues(alpha: 0.08)
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.5),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
