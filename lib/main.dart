import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/verification_screen.dart';
<<<<<<< Updated upstream
=======
import 'screens/signup_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/service_request_screen.dart';
import 'screens/location_screen.dart';
import 'screens/add_location_screen.dart';
import 'screens/searching_mechanics_screen.dart';
import 'screens/add_card_screen.dart';
import 'screens/mechanic_accepted_screen.dart';
import 'screens/request_tools_screen.dart';
import 'screens/video_call_screen.dart';
import 'screens/voice_call_screen.dart';
import 'screens/mechanic_chat_screen.dart';
import 'screens/arrival_confirmation_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/payment_successful_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/order_delivered_screen.dart';
import 'screens/call_support_screen.dart';
import 'screens/garage_screen.dart';
import 'screens/payment_history_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/profile_screen.dart';
import 'theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
>>>>>>> Stashed changes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
