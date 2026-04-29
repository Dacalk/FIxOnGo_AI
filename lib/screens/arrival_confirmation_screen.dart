import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Arrival Confirmation screen — shown when the mechanic has arrived
/// at the user's location. Displays a hero image, arrival message,
/// verified mechanic info, and an Arrival Confirm button.
class ArrivalConfirmationScreen extends StatelessWidget {
  const ArrivalConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;
    final btnColor = dark ? AppColors.brandYellow : AppColors.primaryBlue;
    final btnTextColor = dark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Arrival Confirmation',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: dark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // ── Hero image placeholder ──
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: dark ? const Color(0xFF1E3350) : Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Simulated mechanic working image
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: dark
                                    ? [
                                        const Color(0xFF2A3F5A),
                                        const Color(0xFF1A2E4A),
                                      ]
                                    : [
                                        const Color(0xFF4A6B8A),
                                        const Color(0xFF3A5A7A),
                                      ],
                              ),
                            ),
                          ),
                          // Tool icons overlay
                          Positioned(
                            left: 20,
                            top: 20,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(38),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.laptop,
                                size: 30,
                                color: Colors.white.withAlpha(178),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.build,
                                  size: 50,
                                  color: Colors.white.withAlpha(127),
                                ),
                                const SizedBox(height: 6),
                                Icon(
                                  Icons.car_repair,
                                  size: 40,
                                  color: Colors.white.withAlpha(102),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Mechanic Arrived! ──
                  Text(
                    'Mechanic Arrived!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: dark
                          ? AppColors.primaryBlue
                          : AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Help has reached your location. Your vehicle is in good hands.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: subColor,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Verified Mechanic Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verified badge
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green[400],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'VERIFIED MECHANIC',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Mechanic info row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dulan Thabrew',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gray Van • PH 2553',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Mechanic avatar
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primaryBlue,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // View Profile link
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryBlue.withAlpha((0.4 * 255).toInt()),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'View Profile',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Arrival Confirm Button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate forward or confirm arrival
                },
                icon: const Icon(Icons.play_circle_outline, size: 22),
                label: const Text(
                  'Arrival Confirm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: btnTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
