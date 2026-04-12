import 'package:flutter/material.dart';

class FixOnGoSplashScreen extends StatefulWidget {
  const FixOnGoSplashScreen({super.key});

  @override
  State<FixOnGoSplashScreen> createState() => _FixOnGoSplashScreenState();
}

class _FixOnGoSplashScreenState extends State<FixOnGoSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Initialize the Animation Controller (3 seconds duration)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 2. Define the progress from 0.0 to 1.0
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // SUCCESS: This directs the app to the Onboarding screens after the bar fills
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      });

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A4DBE), Color(0xFF0D286F)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Logo Container
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2259D8),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.shield,
                                size: 70, color: Colors.white),
                            const Positioned.fill(
                              child: Icon(
                                Icons.add,
                                size: 28,
                                color: Color(0xFF2259D8),
                                weight: 900,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: -2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFE162),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'FixOnGo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help when you need it most',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(flex: 1),
                    // DYNAMIC Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: _animation.value,
                          backgroundColor: const Color(0xFF3B5FB5),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
