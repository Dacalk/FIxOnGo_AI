import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme_provider.dart';

/// Call Support screen — linked from Profile > Emergency Contacts.
/// Provides immediate assistance ("Call Now"), regional emergency,
/// and AI assistant chat options.
class CallSupportScreen extends StatelessWidget {
  const CallSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark
        ? AppColors.darkBackground
        : const Color(0xFFF8F9FA); // slightly off-white for light background
    final topBarColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[500]!;
    final cardBg = dark ? const Color(0xFF1E2836) : Colors.white;
    final badgeBg = dark ? const Color(0xFF1E2836) : Colors.white;

    // AI Chat Card background gradient
    final aiCardGradient = LinearGradient(
      colors: dark
          ? [const Color(0xFF434E60), const Color(0xFF83876B)]
          : [
              const Color(0xFFE2E6EC),
              const Color(0xFFE5EFBD),
            ], // silver/grey to pale yellow
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Call Support',
          style: TextStyle(
            fontSize: 18,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // ── Support Team Online Badge ──
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(30),
                  border: dark
                      ? Border.all(color: Colors.white10)
                      : Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Support Team Online',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Main Call Container ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: dark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                        ),
                      ],
              ),
              child: Column(
                children: [
                  // Call Now Button (Glowing)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandYellow.withValues(
                                alpha: 0.8,
                              ),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      // Core button
                      GestureDetector(
                        onTap: () => _makeCall('1234'), // Example support number
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            color: AppColors.brandYellow,
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.phone_in_talk,
                                size: 36,
                                color: Colors.black,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'CALL NOW',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Tap for immediate breakdown assistance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: dark ? Colors.white : Colors.blueGrey[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Average wait time : < 1 min',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.white54 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Regional Emergency Header ──
            Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  color: AppColors.brandYellow,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Regional Emergency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Emergency Options List ──
            _buildEmergencyOption(
              icon: Icons.local_police,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFF1E3A8A), // Navy blue
              title: 'Police / Highway Patrol',
              subtitle: 'For accidents & safety hazards',
              trailing: '119',
              onTap: () => _makeCall('119'),
              dark: dark,
              cardBg: cardBg,
              titleColor: titleColor,
              subColor: subColor,
            ),

            const SizedBox(height: 12),

            _buildEmergencyOption(
              icon: Icons.directions_car,
              iconColor: Colors.white,
              iconBgColor: Colors.red[700]!, // Red
              title: 'Medical Emergency',
              subtitle: 'Suwa Seriya Ambulance',
              trailing: '1990',
              onTap: () => _makeCall('1990'),
              dark: dark,
              cardBg: cardBg,
              titleColor: titleColor,
              subColor: subColor,
            ),

            const SizedBox(height: 12),

            _buildEmergencyOption(
              icon: Icons.rv_hookup, // Tow truck likeness
              iconColor: Colors.white,
              iconBgColor: Colors.orange[700]!, // Orange
              title: 'Local Towing Services',
              subtitle: 'Nearest partnered provider',
              trailingIcon: Icons.chevron_right,
              onTap: () {
                // Future: Navigate to a list of towing providers or call a dispatch center
                _makeCall('0117466466'); // Example towing hotline
              },
              dark: dark,
              cardBg: cardBg,
              titleColor: titleColor,
              subColor: subColor,
            ),

            const SizedBox(height: 32),

            // ── AI Assistant Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: aiCardGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  // Robot Icon Bubble
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: dark ? Colors.white24 : Colors.black12,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: dark ? AppColors.primaryBlue : Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Not an Emergency ?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use our AI assistant to troubleshoot minor issues or find nearby repair shops',
                          style: TextStyle(
                            fontSize: 12,
                            color: dark ? Colors.white70 : Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/ai-chat');
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Start AI Chat',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: dark
                                      ? AppColors.brandYellow
                                      : Colors.orange[500],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: dark
                                    ? AppColors.brandYellow
                                    : Colors.orange[500],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Widget _buildEmergencyOption({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    String? trailing,
    IconData? trailingIcon,
    required bool dark,
    required Color cardBg,
    required Color titleColor,
    required Color subColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                ),
              ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: dark
                  ? iconBgColor.withValues(alpha: 0.2)
                  : iconBgColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: dark ? iconBgColor : iconBgColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Title & Subtitle
          Expanded(
            child: Column(
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
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
              ],
            ),
          ),
          // Trailing text or Icon
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          if (trailingIcon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dark ? Colors.white10 : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(trailingIcon, color: subColor, size: 20),
            ),
        ],
      ),
    ),
  );
}
}
