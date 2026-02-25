import 'package:flutter/material.dart';

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
      "image": "lib/assets/onboarding_1.png", // High-quality Car
      "btnColor": "0xFF1A4DBE", // Exact Logo Yellow
      "txtColor": "0xFFFFFFFF",
    },
    {
      "title": "Professional Help Nearby",
      "subtitle": "Find verified mechanics and essential tools in minutes.",
      "image": "lib/assets/onboarding_2.png", // High-quality Mechanic
      "btnColor": "0xFF1A4DBE", // Exact Loading Screen Blue
      "txtColor": "0xFFFFFFFF",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text(
              "Skip",
              style: TextStyle(
                color: Colors.grey,
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
          btnColor: Color(int.parse(onboardingData[index]['btnColor']!)),
          txtColor: Color(int.parse(onboardingData[index]['txtColor']!)),
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
        ),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title, subtitle, image;
  final Color btnColor, txtColor;
  final bool isLastPage;
  final VoidCallback onNext;
  final int currentIndex;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.btnColor,
    required this.txtColor,
    required this.isLastPage,
    required this.onNext,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Image Container matching your rounded screenshot look
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
          const SizedBox(height: 40),
          // Text Content
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D286F), // Deep Brand Blue
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
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Dynamic Page Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    2,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: currentIndex == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? const Color(0xFF1A4DBE)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Action Button with your specific color scheme
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      foregroundColor: txtColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastPage ? "Get Started" : "Next",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
