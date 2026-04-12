import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data matched to your provided designs
  final List<Map<String, String>> onboardingData = [
    {
      "title": "AI-Powered\nGuidance",
      "subtitle": "Diagnose minor issues instantly with our smart assistant.",
      "image": "lib/assets/onboarding_1.png",
    },
    {
      "title": "Professional\nHelp Nearby",
      "subtitle": "Find verified mechanics and essential tools in minutes.",
      "image": "lib/assets/onboarding_2.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);

    return Scaffold(
      backgroundColor:
          dark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text(
              "Skip",
              style: TextStyle(
                color: dark ? AppColors.darkSkipText : AppColors.lightSkipText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (value) => setState(() => _currentPage = value),
        itemCount: onboardingData.length,
        itemBuilder: (context, index) => OnboardingContent(
          title: onboardingData[index]['title']!,
          subtitle: onboardingData[index]['subtitle']!,
          image: onboardingData[index]['image']!,
          isDark: dark,
          isLastPage: index == onboardingData.length - 1,
          onNext: () {
            if (index < onboardingData.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          currentIndex: _currentPage,
          totalPages: onboardingData.length,
        ),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title, subtitle, image;
  final bool isDark, isLastPage;
  final VoidCallback onNext;
  final int currentIndex, totalPages;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.isDark,
    required this.isLastPage,
    required this.onNext,
    required this.currentIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Image Container
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Text("Image not found")),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Text Content
          Flexible(
            flex: 2,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.darkTitleText
                          : AppColors.lightTitleText,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? AppColors.darkSubtitleText
                            : Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ── Reusable Page Indicator ──
                  PageIndicator(
                    currentIndex: currentIndex,
                    totalPages: totalPages,
                  ),
                  const SizedBox(height: 32),
                  // ── Reusable Primary Button ──
                  PrimaryButton(
                    label: isLastPage ? "Get Started" : "Next",
                    onPressed: onNext,
                    icon: Icons.arrow_forward_rounded,
                    height: 60,
                    borderRadius: 18,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
