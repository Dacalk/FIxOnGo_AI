import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../components/primary_button.dart';

/// Screen shown when a mechanic has accepted the service request.
/// Displays mechanic info, pricing breakdown, and payment options.
class MechanicAcceptedScreen extends StatefulWidget {
  const MechanicAcceptedScreen({super.key});

  @override
  State<MechanicAcceptedScreen> createState() => _MechanicAcceptedScreenState();
}

class _MechanicAcceptedScreenState extends State<MechanicAcceptedScreen> {
  int _selectedPayment = 0; // 0=Card, 1=Cash, 2=Paypal

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[500]! : Colors.grey[600]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Map area (top portion) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.32,
            child: _buildMapPlaceholder(context, dark),
          ),

          // ── Back button ──
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

          // ── Bottom scrollable content ──
          DraggableScrollableSheet(
            initialChildSize: 0.70,
            minChildSize: 0.55,
            maxChildSize: 0.90,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
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
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  children: [
                    // Drag handle
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
                    const SizedBox(height: 10),

                    // ── Status badge & arrival ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'REQUEST ACCEPTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 13, color: subColor),
                            children: [
                              const TextSpan(text: 'Arriving In  '),
                              TextSpan(
                                text: '2 mins',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      'Mechanic is on the way!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Mechanic info card ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryBlue,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name & details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dulan Thabrew',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Gray Van · PH 2553',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '4.9',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: titleColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/voice-call',
                                      ),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: dark
                                              ? AppColors.darkBackground
                                              : AppColors.primaryBlue
                                                    .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: dark
                                              ? Colors.white70
                                              : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/video-call',
                                      ),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: dark
                                              ? AppColors.darkBackground
                                              : AppColors.primaryBlue
                                                    .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.videocam,
                                          size: 14,
                                          color: dark
                                              ? Colors.white70
                                              : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/mechanic-chat',
                                      ),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: dark
                                              ? AppColors.darkBackground
                                              : AppColors.primaryBlue
                                                    .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.chat_bubble,
                                          size: 14,
                                          color: dark
                                              ? Colors.white70
                                              : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. 2000',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Est. price',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Current Location ──
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 18, top: 2),
                      child: Text(
                        'Little Adams Peak Ella Road, Badulla',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Request Tools ──
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/request-tools');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings,
                              color: dark ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Request Tools',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: subColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'If you want Tool you can Request',
                      style: TextStyle(fontSize: 11, color: subColor),
                    ),
                    const SizedBox(height: 16),

                    // ── Total Price breakdown ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Price',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _priceRow('Service Fee', 'Rs. 2,000', dark),
                          const SizedBox(height: 6),
                          _priceRow('Parts (Battery)', 'Rs. 0', dark),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(fontSize: 12, color: subColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Rs. 2,000',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Payment Method ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Payment tabs
                          Row(
                            children: [
                              _paymentTab(0, Icons.credit_card, 'Card', dark),
                              const SizedBox(width: 10),
                              _paymentTab(1, Icons.money, 'Cash', dark),
                              const SizedBox(width: 10),
                              _paymentTab(2, Icons.payment, 'Paypal', dark),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Saved cards
                          _savedCardRow(
                            'Visa card ending in 5689',
                            dark,
                            borderColor,
                          ),
                          const SizedBox(height: 8),
                          _savedCardRow(
                            'Mastercard ending in 5741',
                            dark,
                            borderColor,
                          ),
                          const SizedBox(height: 8),
                          // Link PayPal
                          _actionRow(
                            icon: Icons.payment,
                            label: 'Link Paypal Account',
                            dark: dark,
                            borderColor: borderColor,
                            labelColor: AppColors.primaryBlue,
                          ),
                          const SizedBox(height: 8),
                          // Add Card
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/add-card');
                            },
                            child: _actionRow(
                              icon: Icons.credit_card,
                              label: 'ADD CARD',
                              dark: dark,
                              borderColor: borderColor,
                              showArrow: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Confirm + Cancel buttons ──
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Confirm',
                            onPressed: () {},
                            borderRadius: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Rs. 2,000+',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, bool dark) {
    final labelColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final amountColor = dark ? Colors.white : Colors.black;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 8, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  Widget _paymentTab(int index, IconData icon, String label, bool dark) {
    final isSelected = _selectedPayment == index;
    final selectedBg = AppColors.primaryBlue.withValues(alpha: 0.1);
    final unselectedBg = dark ? const Color(0xFF1A2E4A) : Colors.grey[100]!;

    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primaryBlue, width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primaryBlue
                  : (dark ? Colors.white60 : Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primaryBlue
                    : (dark ? Colors.white60 : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedCardRow(String text, bool dark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.credit_card,
            size: 18,
            color: dark ? Colors.white60 : Colors.grey[500],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Icon(
            Icons.circle,
            size: 10,
            color: dark ? Colors.grey[700] : Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required bool dark,
    required Color borderColor,
    Color? labelColor,
    bool showArrow = false,
  }) {
    final textColor = labelColor ?? (dark ? Colors.white : Colors.black);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: labelColor ?? (dark ? Colors.white60 : Colors.grey[500]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (showArrow)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: dark ? Colors.grey[600] : Colors.grey[400],
            ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(BuildContext context, bool dark) {
    return Container(
      color: dark ? const Color(0xFF1A2640) : const Color(0xFFE5EAD7),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _AcceptedMapPainter(dark: dark),
          ),
          // Location label
          Positioned(
            right: MediaQuery.of(context).size.width * 0.12,
            top: MediaQuery.of(context).size.height * 0.14,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(6),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Icon(Icons.location_on, size: 24, color: AppColors.primaryBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptedMapPainter extends CustomPainter {
  final bool dark;
  _AcceptedMapPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final terrain = Paint()
      ..color = dark
          ? const Color(0xFF1E3350).withValues(alpha: 0.5)
          : const Color(0xFFD4DFC7).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), 60, terrain);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), 50, terrain);

    final road = Paint()
      ..color = dark
          ? Colors.grey[700]!.withValues(alpha: 0.4)
          : const Color(0xFF8899BB).withValues(alpha: 0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.3, 0)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.5,
        size.width * 0.5,
        size.height,
      );
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
