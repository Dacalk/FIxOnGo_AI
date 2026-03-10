import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Help & Support Screen — linked from Profile.
/// Provides a search bar, a "How it works" timeline, and Terms & Conditions.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark
        ? AppColors.darkBackground
        : const Color(
            0xFFF2F8FE,
          ); // Similar blue-tinted light background as Payment History
    final topBarColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Helps & Support',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── How can we help you? ──
            Text(
              'How can we help you ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: dark ? Colors.white : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search here',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── How it works ──
            Text(
              'How it works',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Getting back on the road is easier than ever. Follow these four simple steps.',
              style: TextStyle(fontSize: 11, color: subColor),
            ),
            const SizedBox(height: 24),

            // Timeline
            _buildTimeline(dark, titleColor, subColor),

            const SizedBox(height: 40),

            // ── Terms & Conditions ──
            Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: dark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Last Updated : Feb 2026',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTermsText(subColor),

            const SizedBox(height: 24),
            _buildTermsSection('1. Introduction', titleColor, subColor),
            const SizedBox(height: 24),
            _buildTermsSection('2. Service Scope', titleColor, subColor),
            const SizedBox(height: 24),
            _buildTermsSection(
              '3. User Responsibilities',
              titleColor,
              subColor,
            ),

            const SizedBox(height: 40),

            // ── Back to Home Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dark
                      ? AppColors.brandYellow
                      : AppColors.primaryBlue,
                  foregroundColor: dark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(bool dark, Color titleColor, Color subColor) {
    return Column(
      children: [
        _buildTimelineStep(
          icon: Icons.location_on,
          title: 'Report Issue',
          isLast: false,
          dark: dark,
          titleColor: titleColor,
          subColor: subColor,
        ),
        _buildTimelineStep(
          icon: Icons
              .smart_toy, // Using a robot icon instead of the custom person w/ mechanics hat
          title: 'AI Diagnosis',
          isLast: false,
          dark: dark,
          titleColor: titleColor,
          subColor: subColor,
        ),
        _buildTimelineStep(
          icon: Icons.build,
          title: 'Track Help',
          isLast: false,
          dark: dark,
          titleColor: titleColor,
          subColor: subColor,
        ),
        _buildTimelineStep(
          icon: Icons.build,
          title: 'Easy Payment',
          isLast: true,
          dark: dark,
          titleColor: titleColor,
          subColor: subColor,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required bool isLast,
    required bool dark,
    required Color titleColor,
    required Color subColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator column
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFFD9D9D9)
                      : const Color(0xFFD9D9D9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: Colors.black),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: dark ? Colors.white70 : const Color(0xFFB0C4DE),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
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
                  const SizedBox(height: 8),
                  Text(
                    'Getting back on the road is easier than ever. Follow these four simple steps.Getting back on the road is easier than ever. Follow these four simple steps. Getting back on the road is easier than ever. Follow these four simple steps.',
                    style: TextStyle(
                      fontSize: 10,
                      color: subColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, Color titleColor, Color subColor) {
    return Column(
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
        const SizedBox(height: 12),
        _buildTermsText(subColor),
      ],
    );
  }

  Widget _buildTermsText(Color color) {
    return Text(
      'Getting back on the road is easier than ever. Follow these four simple stepsGetting back on the road is easier than ever. Follow these four simple steps.Getting back on the road is easier than ever. Follow these four simple steps.Getting back on the road is easier than ever. Follow these four simple steps..',
      style: TextStyle(fontSize: 10, color: color, height: 1.4),
    );
  }
}
