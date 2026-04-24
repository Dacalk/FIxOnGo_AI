import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Garage screen — manage vehicles.
/// Linked from the Bottom Navigation Bar 'Garage' tab.
class GarageScreen extends StatelessWidget {
  final bool isEmbedded;
  const GarageScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF8F9FA);
    final topBarColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? const Color(0xFF1E2836) : Colors.white;
    final borderColor = dark ? Colors.transparent : Colors.grey[200]!;

    // Status Badge Colors
    final activeBg = dark
        ? const Color(0xFF88D4A8).withValues(alpha: 0.2)
        : const Color(0xFFC8E6C9);
    final activeText = dark ? const Color(0xFF88D4A8) : Colors.green[800]!;
    final primaryBg = dark
        ? AppColors.brandYellow.withValues(alpha: 0.2)
        : const Color(0xFFFFF9C4);
    final primaryText = dark ? AppColors.brandYellow : Colors.orange[800]!;

    final content = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Overview Section ──
                Text(
                  'Overview',
                  style: TextStyle(fontSize: 13, color: titleColor),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total Vehicles : 02',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Add New Vehicle Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          dark ? AppColors.brandYellow : AppColors.primaryBlue,
                      foregroundColor: dark ? Colors.black : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: dark ? Colors.black : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add New Vehicle',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Vehicle Cards ──
                _buildVehicleCard(
                  imagePath:
                      'assets/images/placeholder_suv.png', // We'll use a placeholder colored box
                  name: 'Toyota Highlandr\nHybrid',
                  plate: 'CARBON - 10',
                  statusText: 'ACTIVE',
                  statusBgColor: activeBg,
                  statusTextColor: activeText,
                  dark: dark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  titleColor: titleColor,
                  subColor: subColor,
                ),
                const SizedBox(height: 16),
                _buildVehicleCard(
                  imagePath: 'assets/images/placeholder_sedan.png',
                  name: 'BYD\'s Flagship\nHan EV',
                  plate: 'LG73 - SDU',
                  statusText: 'PRIMARY',
                  statusBgColor: primaryBg,
                  statusTextColor: primaryText,
                  dark: dark,
                  cardBg: cardBg,
                  borderColor: borderColor,
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
          'My Garage',
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

  Widget _buildVehicleCard({
    required String imagePath,
    required String name,
    required String plate,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
    required bool dark,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subColor,
  }) {
    // Action button styles
    final actionBg = dark ? const Color(0xFF2A3A50) : Colors.grey[200]!;
    final actionText = dark ? Colors.white : Colors.black87;
    final removeText = Colors.red[400]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: dark ? null : Border.all(color: borderColor),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1E3350) : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions_car,
              size: 40,
              color: dark ? Colors.white54 : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Badge Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  plate,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit,
                      text: 'Edit',
                      bgColor: actionBg,
                      textColor: actionText,
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      text: 'Remove',
                      bgColor: actionBg,
                      textColor: removeText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
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
            _navItem(
                context, Icons.garage_rounded, 'Garage', true, dark, '/garage'),
            _navItem(context, Icons.payments_rounded, 'Payment', false, dark,
                '/payment-history'),
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
