import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/social_button.dart';
import '../components/phone_input.dart';
import '../components/role_dropdown.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _phoneError;
  String _selectedRole = 'User';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onGetOtp() {
    final error =
        PhoneInput.validateSriLankanPhone(_phoneController.text);
    setState(() => _phoneError = error);

    if (error == null) {
      // Phone is valid — navigate to verification, pass role + phone
      Navigator.pushNamed(context, '/verification',
          arguments: {
            'role': _selectedRole,
            'phone': _phoneController.text,
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : AppColors.lightBackground;
    final titleColor =
        dark ? AppColors.darkTitleText : const Color(0xFF1A1A1A);
    final subtitleColor =
        dark ? AppColors.darkSubtitleText : Colors.blueGrey;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image Section
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
                // Dark overlay for better text readability
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
                              color: dark ? AppColors.brandYellow : Colors.black,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "ROADSIDE AI",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: dark ? Colors.white70 : Colors.black54,
                              letterSpacing: 1,
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
                      Text(
                        "Sri Lanka's fastest emergency assistance.",
                        style: TextStyle(
                          fontSize: 14,
                          color: dark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

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
                  Text(
                    "Choose Your Role",
                    style: TextStyle(
                      color: dark ? AppColors.brandYellow : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Reusable Role Dropdown ──
                  RoleDropdown(
                    onChanged: (role) {
                      if (role != null) {
                        setState(() => _selectedRole = role);
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Enter your phone number to receive a verification code.",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ── Reusable Phone Input with validation ──
                  PhoneInput(
                    controller: _phoneController,
                    errorText: _phoneError,
                  ),

                  const SizedBox(height: 25),

                  // ── Reusable Primary Button (Get OTP) ──
                  PrimaryButton(
                    label: "Get OTP",
                    onPressed: _onGetOtp,
                    icon: Icons.arrow_forward,
                    borderRadius: 30,
                  ),

                  const SizedBox(height: 30),

                  // Divider with "Or continue with"
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: dark ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Or continue with",
                          style: TextStyle(
                            color: dark ? Colors.grey[500] : Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: dark ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Reusable Social Buttons ──
                  const Row(
                    children: [
                      Expanded(
                        child: SocialButton(
                          label: "Google",
                          imagePath: "lib/assets/google.png",
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: SocialButton(
                          label: "Apple",
                          imagePath: "lib/assets/apple.png",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: "By logging in, you agree to our ",
                        style: TextStyle(
                          fontSize: 11,
                          color: dark ? Colors.grey[500] : Colors.grey,
                        ),
                        children: [
                          TextSpan(
                            text: "Terms of Service",
                            style: TextStyle(
                              color: dark
                                  ? AppColors.brandYellow
                                  : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: " & ",
                            style: TextStyle(
                              color: dark ? Colors.grey[500] : Colors.grey,
                            ),
                          ),
                          TextSpan(
                            text: "Privacy policy",
                            style: TextStyle(
                              color: dark
                                  ? AppColors.brandYellow
                                  : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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