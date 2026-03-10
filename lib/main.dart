import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/verification_screen.dart';
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
import 'screens/profile_screen.dart';
import 'theme_provider.dart';

void main() {
  runApp(const FixOnGoApp());
}

class FixOnGoApp extends StatelessWidget {
  const FixOnGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FixOnGo',

          // ─── Light Theme ───
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF1A4DBE),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
            ),
            useMaterial3: true,
          ),

          // ─── Dark Theme ───
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF1A4DBE),
            scaffoldBackgroundColor: const Color(0xFF0A1628),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0A1628),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            useMaterial3: true,
          ),

          // Driven by the global themeNotifier
          themeMode: currentMode,

          // Route Map
          initialRoute: '/',
          routes: {
            '/': (context) => const FixOnGoSplashScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/verification': (context) => const VerificationScreen(),
            '/signup': (context) => const SignupScreen(),
            '/ai-chat': (context) => const AiChatScreen(),
            '/service-request': (context) => const ServiceRequestScreen(),
            '/location': (context) => const LocationScreen(),
            '/add-location': (context) => const AddLocationScreen(),
            '/searching-mechanics': (context) =>
                const SearchingMechanicsScreen(),
            '/add-card': (context) => const AddCardScreen(),
            '/mechanic-accepted': (context) => const MechanicAcceptedScreen(),
            '/request-tools': (context) => const RequestToolsScreen(),
            '/video-call': (context) => const VideoCallScreen(),
            '/voice-call': (context) => const VoiceCallScreen(),
            '/mechanic-chat': (context) => const MechanicChatScreen(),
            '/arrival-confirmation': (context) =>
                const ArrivalConfirmationScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/payment-successful': (context) => const PaymentSuccessfulScreen(),
            '/checkout': (context) => const CheckoutScreen(),
            '/order-tracking': (context) => const OrderTrackingScreen(),
            '/order-delivered': (context) => const OrderDeliveredScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/call-support': (context) => const CallSupportScreen(),
          },
        );
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
