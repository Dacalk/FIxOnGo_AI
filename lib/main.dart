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
import 'screens/add_product_screen.dart';

import 'screens/video_call_screen.dart';
import 'screens/voice_call_screen.dart';
import 'screens/mechanic_chat_screen.dart';
import 'screens/ai_chat_history_screen.dart';
import 'screens/arrival_confirmation_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/mechanic_nav_to_user_screen.dart';
import 'screens/payment_successful_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/order_delivered_screen.dart';
import 'screens/call_support_screen.dart';
import 'screens/garage_screen.dart';
import 'screens/mechanic_shop_screen.dart';
import 'screens/payment_history_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/rate_experience_screen.dart';
import 'screens/user_shop_view_screen.dart';
import 'screens/job_history_screen.dart';
import 'theme_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';

import 'components/auth_guard.dart'; // Import AuthGuard

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // On Web, use path URL strategy (removes #) and wait for session restoration
  if (kIsWeb) {
    usePathUrlStrategy();

    // Improved waiting logic: wait for a non-null user OR a 2-second timeout
    // This solves the issue where authStateChanges().first returns null initially on Web
    await FirebaseAuth.instance
        .authStateChanges()
        .where((user) => user != null)
        .timeout(
          const Duration(seconds: 2),
          onTimeout: (sink) => sink.add(null),
        )
        .first;
  }

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
          routes: {
            // Public Routes
            '/': (context) => const FixOnGoSplashScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/verification': (context) => const VerificationScreen(),
            '/signup': (context) => SignupScreen(),

            // Protected Routes
            '/ai-chat': (context) => const AuthGuard(child: AiChatScreen()),
            '/ai-chat-history': (context) =>
                const AuthGuard(child: AiChatHistoryScreen()),
            '/service-request': (context) =>
                const AuthGuard(child: ServiceRequestScreen()),
            '/location': (context) => const AuthGuard(child: LocationScreen()),
            '/add-location': (context) =>
                const AuthGuard(child: AddLocationScreen()),
            '/searching-mechanics': (context) =>
                const AuthGuard(child: SearchingMechanicsScreen()),
            '/add-card': (context) => const AuthGuard(child: AddCardScreen()),
            '/mechanic-accepted': (context) =>
                const AuthGuard(child: MechanicAcceptedScreen()),
            '/add-product': (context) =>
                const AuthGuard(child: AddProductScreen()),

            '/video-call': (context) =>
                const AuthGuard(child: VideoCallScreen()),
            '/voice-call': (context) =>
                const AuthGuard(child: VoiceCallScreen()),
            '/mechanic-chat': (context) =>
                const AuthGuard(child: MechanicChatScreen()),
            '/arrival-confirmation': (context) =>
                const AuthGuard(child: ArrivalConfirmationScreen()),
            '/dashboard': (context) =>
                const AuthGuard(child: DashboardScreen()),
            '/mechanic-nav-to-user': (context) =>
                const AuthGuard(child: MechanicNavToUserScreen()),
            '/payment-successful': (context) =>
                const AuthGuard(child: PaymentSuccessfulScreen()),
            '/checkout': (context) => const AuthGuard(child: CheckoutScreen()),
            '/order-tracking': (context) =>
                const AuthGuard(child: OrderTrackingScreen()),
            '/order-delivered': (context) =>
                const AuthGuard(child: OrderDeliveredScreen()),
            '/profile': (context) => const AuthGuard(child: ProfileScreen()),
            '/call-support': (context) =>
                const AuthGuard(child: CallSupportScreen()),
            '/garage': (context) => const AuthGuard(child: GarageScreen()),
            '/mechanic-shop': (context) =>
                const AuthGuard(child: MechanicShopScreen()),
            '/payment-history': (context) =>
                const AuthGuard(child: PaymentHistoryScreen()),
            '/help-support': (context) =>
                const AuthGuard(child: HelpSupportScreen()),
            '/user-shop-view': (context) =>
                const AuthGuard(child: UserShopViewScreen()),
            '/rate-experience': (context) =>
                const AuthGuard(child: RateExperienceScreen()),
            '/job-history': (context) =>
                const AuthGuard(child: JobHistoryScreen()),
            '/home': (context) => const AuthGuard(child: HomeScreen()),
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
