import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Payment History screen — view past transactions.
/// Linked from the Bottom Navigation Bar 'Payment' tab.
class PaymentHistoryScreen extends StatelessWidget {
  final bool isEmbedded;
  const PaymentHistoryScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark
        ? AppColors.darkBackground
        : const Color(0xFFF2F8FE); // Slightly blue-tinted light background
    final topBarColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? const Color(0xFF222F3E) : Colors.white;

    // Header banner colors
    final bannerBg = dark ? const Color(0xFFBAD5F0) : const Color(0xFFD4E6F8);
    final bannerText = dark ? const Color(0xFF2466A8) : const Color(0xFF3B7BC2);
    final bannerCircle1 =
        dark ? const Color(0xFF98C1EA) : const Color(0xFFB3D4F3);
    final bannerCircle2 =
        dark ? const Color(0xFFDDEBFA) : const Color(0xFFEAF2FB);

    final content = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Total Spent Banner ──
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: bannerBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      // Left decoration circle
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: bannerCircle1,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Right decoration circle
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: bannerCircle2,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'TOTAL SPENT THIS MONTH',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: bannerText,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'RS. 5000.00',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: bannerText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Filters & Headers ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: dark ? AppColors.brandYellow : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Last 4 Month',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: dark ? Colors.black : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: dark ? Colors.black : Colors.grey[700],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Group: February 2026 ──
                _buildMonthHeader('February 2026', titleColor),
                _buildTransactionCard(
                  icon: Icons.build,
                  title: 'Mechanic Request',
                  date: '12 Feb, 10.30 AM',
                  vehicle: 'TOYOTA HYBRID',
                  amount: 'RS.2,500',
                  status: 'COMPLETED',
                  cardLogo: 'VISA',
                  cardTail: 'Ending in 4587',
                  dark: dark,
                  cardBg: cardBg,
                  titleColor: titleColor,
                  subColor: subColor,
                ),

                const SizedBox(height: 24),

                // ── Group: November 2025 ──
                _buildMonthHeader('November 2025', titleColor),
                _buildTransactionCard(
                  icon: Icons.car_repair,
                  title: 'Tool Request',
                  date: '12 Nov, 12 PM',
                  vehicle: 'BYD Vehicle',
                  amount: 'RS.1,500',
                  status: 'COMPLETED',
                  cardLogo: 'VISA',
                  cardTail: 'Ending in 4587',
                  dark: dark,
                  cardBg: cardBg,
                  titleColor: titleColor,
                  subColor: subColor,
                ),

                const SizedBox(height: 24),

                // ── Group: October 2025 ──
                _buildMonthHeader('October 2025', titleColor),
                _buildTransactionCard(
                  icon: Icons.build,
                  title: 'Mechanic Request',
                  date: '12 OCT, 11.30 AM',
                  vehicle: 'TOYOTA HYBRID',
                  amount: 'RS.1,500',
                  status: 'COMPLETED',
                  cardLogo: 'VISA',
                  cardTail: 'Ending in 4587',
                  dark: dark,
                  cardBg: cardBg,
                  titleColor: titleColor,
                  subColor: subColor,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        if (!isEmbedded)
          // ── Bottom Navigation Bar ──
          _buildBottomNav(context, dark),
      ],
    );

    if (isEmbedded) return content;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Payment History',
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
                Icons.arrow_back,
                size: 18,
                color: dark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: content,
    );
  }

  Widget _buildMonthHeader(String month, Color titleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        month,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: titleColor,
        ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required IconData icon,
    required String title,
    required String date,
    required String vehicle,
    required String amount,
    required String status,
    required String cardLogo,
    required String cardTail,
    required bool dark,
    required Color cardBg,
    required Color titleColor,
    required Color subColor,
  }) {
    final statusBg = dark ? const Color(0xFF163E2B) : const Color(0xFFD1F2DD);
    final statusText = dark ? const Color(0xFF4DB07B) : const Color(0xFF23A05B);
    final amountColor =
        dark ? const Color(0xFF4B89D7) : const Color(0xFF1E61D8);
    final iconColor = dark ? Colors.grey[400] : Colors.black;
    final cardInfoBg = dark ? Colors.grey[800] : Colors.grey[200];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Icon
              Icon(icon, size: 36, color: iconColor),
              const SizedBox(width: 16),
              // Main Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        Text(
                          amount,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Date & Vehicle & Status
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 10,
                            color: subColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '•',
                          style: TextStyle(fontSize: 10, color: subColor),
                        ),
                        Text(
                          vehicle,
                          style: TextStyle(
                            fontSize: 10,
                            color: subColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: statusText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Divider space for lower section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cardInfoBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      cardLogo,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    cardTail,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View Receipt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 14, color: amountColor),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A2432) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, Icons.home_rounded, 'Dashboard', false, dark,
                '/dashboard'),
            _navItem(context, Icons.history_rounded, 'Activities', false, dark,
                '/job-history'),
            _navItem(context, Icons.garage_rounded, 'Vehicles', false, dark,
                '/garage'),
            _navItem(context, Icons.person_rounded, 'Profile', false, dark,
                '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    bool dark,
    String routeName,
  ) {
    final color = isActive
        ? AppColors.primaryBlue
        : (dark ? Colors.grey[500]! : Colors.grey[400]!);

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, routeName);
            }
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
