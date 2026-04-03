import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADD THIS
=======
import 'package:cloud_firestore/cloud_firestore.dart';
>>>>>>> d7834c90fc7a19ffe39458df4bcf79b13bc6feef
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

<<<<<<< HEAD
  // ✅ 🔥 SAVE USER DATA TO FIRESTORE
  Future<void> _saveUserData(String phone, String role) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(phone) // unique ID
          .set({'phone': phone, 'role': role, 'createdAt': Timestamp.now()});

      print("User saved to Firestore");
    } catch (e) {
      print("Error saving user: $e");
    }
  }

  // ✅ 🔥 UPDATED FUNCTION
=======
>>>>>>> d7834c90fc7a19ffe39458df4bcf79b13bc6feef
  void _onGetOtp() async {
    final error = PhoneInput.validateSriLankanPhone(_phoneController.text);
    setState(() => _phoneError = error);

    if (error == null) {
      String phone = _phoneController.text;

<<<<<<< HEAD
      // 🔥 SAVE DATA FIRST
      await _saveUserData(phone, _selectedRole);

      // 👉 Navigate to OTP screen
=======
>>>>>>> d7834c90fc7a19ffe39458df4bcf79b13bc6feef
      Navigator.pushNamed(
        context,
        '/verification',
        arguments: {'role': _selectedRole, 'phone': phone},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : AppColors.lightBackground;
    final titleColor = dark ? AppColors.darkTitleText : const Color(0xFF1A1A1A);
    final subtitleColor = dark ? AppColors.darkSubtitleText : Colors.blueGrey;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                              color: dark
                                  ? AppColors.brandYellow
                                  : Colors.black,
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

                  RoleDropdown(
                    onChanged: (role) =>
                        setState(() => _selectedRole = role ?? 'User'),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Enter your phone number to receive a verification code.",
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  const SizedBox(height: 15),

                  PhoneInput(
                    controller: _phoneController,
                    errorText: _phoneError,
                  ),

                  const SizedBox(height: 25),

<<<<<<< HEAD
                  // 🔥 BUTTON (UPDATED FUNCTION)
=======
>>>>>>> d7834c90fc7a19ffe39458df4bcf79b13bc6feef
                  PrimaryButton(
                    label: "Get OTP",
                    onPressed: _onGetOtp,
                    icon: Icons.arrow_forward,
                    borderRadius: 30,
                  ),

                  const SizedBox(height: 30),

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
                    child: Text(
                      "By logging in, you agree to our Terms & Privacy Policy",
                      style: TextStyle(
                        fontSize: 11,
                        color: dark ? Colors.grey[500] : Colors.grey,
                      ),
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
