import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Payment Successful screen — confirmation shown after a successful payment.
/// Displays a success icon, location info, map placeholder, payment details,
/// and action buttons ("Call To Mechanic" / "Back to Home").
class PaymentSuccessfulScreen extends StatelessWidget {
  const PaymentSuccessfulScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;
    final labelColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final valueColor = dark ? Colors.grey[300]! : Colors.grey[800]!;
    final btnColor = dark ? AppColors.brandYellow : AppColors.primaryBlue;
    final btnTextColor = dark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: dark ? AppColors.darkSurface : Colors.grey[100],
            child: IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: dark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: dark ? AppColors.darkSurface : Colors.grey[100],
              child: IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: dark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  // Share action
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Success Icon ──
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green[500],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Payment Successful Title ──
                  Text(
                    'Payment Successful',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your payment has been processed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: subColor),
                  ),
                  Text(
                    'Help is arriving at your location in',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: subColor),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Ella',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Map Placeholder ──
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: dark ? const Color(0xFF1E3350) : Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Simulated map background
                          Container(
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
                          ),
                          // Road lines
                          CustomPaint(painter: _MapPainter()),
                          // Location labels
                          Positioned(
                            top: 30,
                            left: 80,
                            child: Text(
                              'Ella',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            left: 130,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'B113',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            right: 40,
                            child: Text(
                              'Cafe Chill',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 30,
                            child: Text(
                              'Ravana Range',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          // Pin marker
                          Positioned(
                            top: 40,
                            left: 70,
                            child: Icon(
                              Icons.location_on,
                              color: Colors.red[600],
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Payment Details Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          'Service Type',
                          'Machanical',
                          labelColor,
                          valueColor,
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          'Reference ID',
                          '#LK-99231-COL',
                          labelColor,
                          valueColor,
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          'Date & Time',
                          'May 15, 2024 • 02:15 PM',
                          labelColor,
                          valueColor,
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          'Payment Method',
                          '•••• 8182',
                          labelColor,
                          valueColor,
                        ),
                        const SizedBox(height: 20),
                        Divider(color: borderColor, thickness: 1),
                        const SizedBox(height: 16),
                        // Total Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount Paid',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            Text(
                              'Rs. 2,000.00',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Action Buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Call to mechanic action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: btnTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Call To Machanic',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a label–value row for the payment details card.
  Widget _detailRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Custom painter that draws simplified road lines for the map placeholder.
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Horizontal road
    final path1 = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.35,
        size.width,
        size.height * 0.45,
      );
    canvas.drawPath(path1, paint);

    // Diagonal road
    final path2 = Path()
      ..moveTo(size.width * 0.3, 0)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.5,
        size.width * 0.6,
        size.height,
      );
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
