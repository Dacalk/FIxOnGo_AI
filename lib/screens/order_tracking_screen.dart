import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Order Tracking screen — shows real-time delivery status with map,
/// driver info, and order timeline (Confirmed → Picked Up → Delivered).
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Map Area ──
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                // Map placeholder
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFC8E6C9),
                        const Color(0xFFE8F5E9),
                        const Color(0xFFF1F8E9),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: _TrackingMapPainter(),
                    child: Stack(
                      children: [
                        // Location labels
                        Positioned(
                          top: 100,
                          left: 60,
                          child: Text(
                            'Little Adam\'s\nPeak Trailhead',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 80,
                          left: 20,
                          child: Text(
                            'Flying Ravana\nAdventure Park',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                          ),
                        ),
                        // Destination pin
                        Positioned(
                          top: 80,
                          left: 100,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.flag,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                        // Blue route dot
                        Positioned(
                          top: 60,
                          right: 80,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        // Driver icon on route
                        Positioned(
                          top: 120,
                          right: 100,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        // "SUNIL IS ON THE WAY" badge
                        Positioned(
                          top: 108,
                          right: 140,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SUNIL IS ON THE WAY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Back button
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
              ],
            ),
          ),

          // ── Bottom Sheet ──
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: dark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Order Picked Up header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Picked Up',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: dark
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '13 mins',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sunil has collected your Battery & Fuel',
                      style: TextStyle(fontSize: 13, color: subColor),
                    ),

                    const SizedBox(height: 20),

                    // ── Driver Card ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryBlue,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sunil Perera',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'A - 5222',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '4.3',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: titleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Call & Chat
                          _actionCircle(Icons.phone, dark),
                          const SizedBox(width: 8),
                          _actionCircle(Icons.chat_bubble_outline, dark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Delivery Timeline ──
                    _timelineStep(
                      title: 'Order Confirmed',
                      subtitle: 'Your request was accepted at 10:45 AM',
                      isCompleted: true,
                      isLast: false,
                      dark: dark,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    _timelineStep(
                      title: 'Order Picked Up',
                      subtitle: 'Sunil is heading towards your location',
                      isCompleted: true,
                      isLast: false,
                      dark: dark,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    _timelineStep(
                      title: 'Delivered',
                      subtitle: 'Estimated arrival in 13 mins',
                      isCompleted: false,
                      isLast: true,
                      dark: dark,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),

                    const SizedBox(height: 20),

                    // ── View Order Details ──
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'View Order Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ),
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

  Widget _actionCircle(IconData icon, bool dark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: dark
            ? AppColors.darkSurface
            : AppColors.primaryBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: dark ? Colors.white70 : AppColors.primaryBlue,
      ),
    );
  }

  Widget _timelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLast,
    required bool dark,
    required Color titleColor,
    required Color subColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green
                    : (dark ? Colors.grey[700] : Colors.grey[300]),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.4)
                    : (dark ? Colors.grey[700] : Colors.grey[300]),
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? (dark ? Colors.green[400] : Colors.green[700])
                        : (dark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the tracking map background.
class _TrackingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Road curve 1
    final path1 = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.4,
        size.width,
        size.height * 0.5,
      );
    canvas.drawPath(path1, roadPaint);

    // Road curve 2
    final path2 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.7,
        size.height,
      );
    canvas.drawPath(path2, roadPaint);

    // Blue dashed route
    final routePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.45,
        size.width * 0.6,
        size.height * 0.55,
      );
    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
