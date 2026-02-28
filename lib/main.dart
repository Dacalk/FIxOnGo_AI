import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/verification_screen.dart';

void main() {
  runApp(const FixOnGoApp());
}

class FixOnGoApp extends StatelessWidget {
  const FixOnGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FixOnGo',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1A4DBE),
        useMaterial3: true,
      ),
      // 1. App starts at the Splash Screen
      initialRoute: '/',
      // 2. Route Map (The Connector)
      routes: {
        '/': (context) => const FixOnGoSplashScreen(),
        'verification' :(context) => const VerificationScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FixOnGo Home")),
      body: const Center(child: Text("Home Content Goes Here")),
    );
  }
}
