import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// "Searching for nearby mechanics" screen.
/// Shown after a user requests a service — displays a map with mechanic pins
/// and an animated bottom sheet indicating the search is in progress.
class SearchingMechanicsScreen extends StatefulWidget {
  const SearchingMechanicsScreen({super.key});

  @override
  State<SearchingMechanicsScreen> createState() =>
      _SearchingMechanicsScreenState();
}

class _SearchingMechanicsScreenState extends State<SearchingMechanicsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final sheetBg = dark ? AppColors.darkBackground : Colors.white;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen Map Placeholder ──
          Positioned.fill(child: _buildMapArea(context, dark)),

          // ── Back Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
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
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          // ── Cancel Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkSurface : const Color(0xFF2C3E50),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          // ── Location Pin Label ──
          Positioned(
            right: MediaQuery.of(context).size.width * 0.12,
            top: MediaQuery.of(context).size.height * 0.28,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.location_on, size: 30, color: AppColors.primaryBlue),
              ],
            ),
          ),

          // ── Bottom Sheet ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: BoxDecoration(
                color: sheetBg,
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
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: dark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Searching for nearby\nmechanics...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Animated dots
                    AnimatedBuilder(
                      animation: _dotController,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final progress = _dotController.value;
                            final activeIndex = (progress * 5).floor() % 5;
                            final isActive = index <= activeIndex;
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? AppColors.primaryBlue
                                    : (dark
                                          ? Colors.grey[700]
                                          : Colors.grey[300]),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // Status text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sync,
                          size: 16,
                          color: dark ? Colors.grey[500] : Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Contacting service providers',
                          style: TextStyle(
                            fontSize: 14,
                            color: dark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
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

  /// Map area with mechanic pins scattered
  Widget _buildMapArea(BuildContext context, bool dark) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Container(
      color: dark ? const Color(0xFF1A2640) : const Color(0xFFE5EAD7),
      child: Stack(
        children: [
          // Map grid
          CustomPaint(
            size: Size.infinite,
            painter: _SearchMapPainter(dark: dark),
          ),
          // Mechanic pins scattered
          _mechanicPin(dark, left: sw * 0.05, top: sh * 0.22),
          _mechanicPin(dark, left: sw * 0.15, top: sh * 0.24),
          _mechanicPin(dark, left: sw * 0.50, top: sh * 0.18),
          _mechanicPin(dark, left: sw * 0.55, top: sh * 0.22),
          _mechanicPin(dark, left: sw * 0.40, top: sh * 0.42),
        ],
      ),
    );
  }

  Widget _mechanicPin(bool dark, {required double left, required double top}) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E3350) : const Color(0xFF2C3E50),
          shape: BoxShape.circle,
          border: Border.all(
            color: dark ? Colors.grey[700]! : Colors.white,
            width: 2,
          ),
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 16),
      ),
    );
  }
}

/// Map background painter for the search screen
class _SearchMapPainter extends CustomPainter {
  final bool dark;

  _SearchMapPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    // Terrain
    final terrainPaint = Paint()
      ..color = dark
          ? const Color(0xFF1E3350).withValues(alpha: 0.5)
          : const Color(0xFFD4DFC7).withValues(alpha: 0.6);

    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.35),
      70,
      terrainPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.55),
      55,
      terrainPaint,
    );

    // Roads
    final roadPaint = Paint()
      ..color = dark
          ? Colors.grey[700]!.withValues(alpha: 0.4)
          : const Color(0xFF8899BB).withValues(alpha: 0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.3, 0)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.4,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.6,
        size.width * 0.4,
        size.height,
      );
    canvas.drawPath(path, roadPaint);

    // Dotted search radius circle
    final radiusPaint = Paint()
      ..color = dark
          ? Colors.red.withValues(alpha: 0.2)
          : Colors.red.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.35),
      120,
      radiusPaint,
    );

    // Subtle grid
    final gridPaint = Paint()
      ..color = dark
          ? Colors.grey[800]!.withValues(alpha: 0.2)
          : Colors.grey[400]!.withValues(alpha: 0.12)
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
