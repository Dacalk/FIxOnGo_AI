import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../components/primary_button.dart';

/// A nearby place suggestion chip data model.
class NearbyPlace {
  final String name;
  final String subtitle;

  const NearbyPlace({required this.name, required this.subtitle});
}

/// Location screen showing the user's current location on a map placeholder,
/// with a location info card, nearby place chips, and a Request Service button.
class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  static const List<NearbyPlace> _nearbyPlaces = [
    NearbyPlace(
      name: 'Little Adams Peak Ella',
      subtitle: 'Ella Road Wellawaya',
    ),
    NearbyPlace(name: 'Nine Arch Bridge', subtitle: 'Ella Road Wellawaya'),
    NearbyPlace(name: 'Ella Rock Trailhead', subtitle: 'Ella Town Center'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final cardBg = dark ? const Color(0xFF12233D) : Colors.white;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen Map Placeholder ──
          Positioned.fill(child: _buildMapPlaceholder(context, dark)),

          // ── Back Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _circleButton(
              icon: Icons.arrow_back,
              dark: dark,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // ── My Location Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _circleButton(
              icon: Icons.my_location,
              dark: dark,
              onTap: () {},
            ),
          ),

          // ── User Pin (center of map) ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_pin_circle,
                  size: 48,
                  color: dark ? Colors.white : Colors.black87,
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Compass / Navigate Button ──
          Positioned(
            bottom: 24,
            right: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.navigation_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),

          // ── Bottom Info Panel ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
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
                    // ── Location Info Row ──
                    _buildLocationCard(dark),

                    const SizedBox(height: 14),

                    // ── Nearby Places Chips ──
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _nearbyPlaces.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return _buildPlaceChip(_nearbyPlaces[index], dark);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Request Service Button ──
                    PrimaryButton(
                      label: 'Request Service',
                      onPressed: () {
                        Navigator.pushNamed(context, '/service-request');
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

  /// Location detail card with GPS status
  Widget _buildLocationCard(bool dark) {
    final titleColor = dark ? Colors.white : Colors.black;
    final labelColor = dark ? Colors.blue[300]! : AppColors.primaryBlue;
    final subtitleColor = dark ? Colors.grey[500]! : Colors.grey[600]!;
    return Row(
      children: [
        // Blue dot indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: labelColor, width: 2),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: labelColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Text info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR LOCATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ella Rock Trailhead, Ella',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'GPS location accurately fetched',
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ],
          ),
        ),

        // Action buttons
        IconButton(
          icon: Icon(Icons.add, color: dark ? Colors.white70 : Colors.black54),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            Icons.favorite_border,
            color: dark ? Colors.white70 : Colors.black54,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  /// Nearby place chip
  Widget _buildPlaceChip(NearbyPlace place, bool dark) {
    final chipBg = dark ? AppColors.darkSurface : Colors.grey[100]!;
    final textColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[500]! : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: AppColors.brandYellow, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                place.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                place.subtitle,
                style: TextStyle(fontSize: 10, color: subColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Map placeholder background
  Widget _buildMapPlaceholder(BuildContext context, bool dark) {
    return Container(
      color: dark ? const Color(0xFF1A2640) : const Color(0xFFE5EAD7),
      child: CustomPaint(
        size: Size.infinite,
        painter: _LocationMapPainter(dark: dark),
      ),
    );
  }

  /// Circular icon button overlay
  Widget _circleButton({
    required IconData icon,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
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
        child: Icon(icon, size: 20, color: dark ? Colors.white : Colors.black),
      ),
    );
  }
}

/// Painter that draws a stylized map background with roads and terrain
class _LocationMapPainter extends CustomPainter {
  final bool dark;

  _LocationMapPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    // Terrain patches
    final terrainPaint = Paint()
      ..color = dark
          ? const Color(0xFF1E3350).withValues(alpha: 0.5)
          : const Color(0xFFD4DFC7).withValues(alpha: 0.6);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      80,
      terrainPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.6),
      60,
      terrainPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.15),
      50,
      terrainPaint,
    );

    // Road lines
    final roadPaint = Paint()
      ..color = dark
          ? Colors.cyan.withValues(alpha: 0.12)
          : const Color(0xFF8899BB).withValues(alpha: 0.25)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.35,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.65,
        size.width,
        size.height * 0.55,
      );
    canvas.drawPath(path, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.3,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.7,
        size.width * 0.45,
        size.height,
      );
    canvas.drawPath(path2, roadPaint);

    // Grid-like subtle streets
    final streetPaint = Paint()
      ..color = dark
          ? Colors.grey[800]!.withValues(alpha: 0.2)
          : Colors.grey[400]!.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), streetPaint);
    }
    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), streetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
