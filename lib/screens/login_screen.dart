import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/social_button.dart';
import '../components/phone_input.dart';
import '../components/role_dropdown.dart';

import '../services/google_auth_service.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _phoneError;

  String _selectedRole = '';

  final GoogleAuthService _googleAuth = GoogleAuthService();

  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  //  FINAL COMMON FUNCTION (WITH ROLE)
  Future<void> checkUserAndNavigate(User user, String role) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    Map roles = doc.data()?['roles'] ?? {};

    if (roles.containsKey(role)) {
      //  role already exists
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(role: role),
        ),
      );
    } else {
      // ❗ role not exists → signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SignupScreen(),
          settings: RouteSettings(arguments: role),
        ),
      );
    }
  }

  // 🔵 OTP FLOW
  void _onGetOtp() async {
    final error = PhoneInput.validateSriLankanPhone(_phoneController.text);
    setState(() => _phoneError = error);

    if (error == null) {
      if (_selectedRole.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a role")),
        );
        return;
      }

      Navigator.pushNamed(
        context,
        '/verification',
        arguments: {
          'role': _selectedRole,
          'phone': _phoneController.text,
        },
      );
    }
  }

  //  GOOGLE LOGIN (FINAL)
  Future<void> _handleGoogleLogin() async {
    if (_selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a role")),
      );
      return;
    }

    setState(() => _isGoogleLoading = true);

    final user = await _googleAuth.signInWithGoogle();

    if (user != null) {
      await checkUserAndNavigate(user, _selectedRole); //  FIXED
    }

    setState(() => _isGoogleLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : AppColors.lightBackground;
    final titleColor = dark ? AppColors.darkTitleText : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ HEADER (UNCHANGED)
            Stack(
              children: [
                Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/assets/image.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        bgColor.withValues(alpha: 0.8),
                        bgColor,
                      ],
                      stops: const [0.3, 0.75, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: dark
                                ? AppColors.darkCardSurface
                                : Colors.amber.withValues(alpha: 0.8),
                            radius: 24,
                            child: Icon(
                              Icons.car_repair,
                              color:
                                  dark ? AppColors.brandYellow : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "ROADSIDE AI",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: dark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Help is on the way",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            //  BODY (UNCHANGED)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sign up with Mobile",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  //  ROLE REQUIRED
                  RoleDropdown(
                    onChanged: (role) =>
                        setState(() => _selectedRole = role ?? ''),
                  ),

                  const SizedBox(height: 15),

                  PhoneInput(
                    controller: _phoneController,
                    errorText: _phoneError,
                  ),

                  const SizedBox(height: 25),

                  PrimaryButton(
                    label: "Get OTP",
                    onPressed: _onGetOtp,
                    icon: Icons.arrow_forward,
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Or continue with"),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: SocialButton(
                          label: "Google",
                          imagePath: "lib/assets/google.png",
                          onPressed:
                              _isGoogleLoading ? null : _handleGoogleLogin,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: SocialButton(
                          label: "Apple",
                          imagePath: "lib/assets/apple.png",
                          onPressed: () {
                            print("Apple login not implemented yet");
                          },
                        ),
                      ),
                    ],
                  ),

                  if (_isGoogleLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  const SizedBox(height: 40),

                  const Center(
                    child: Text(
                      "By logging in, you agree to our Terms & Privacy Policy",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
