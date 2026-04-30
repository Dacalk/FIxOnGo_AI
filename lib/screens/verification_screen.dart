import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Theme and UI components
import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/otp_box.dart';

// Navigation screens
import 'dashboard_screen.dart';
import 'signup_screen.dart';

// Main verification screen
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

// State class
class _VerificationScreenState extends State<VerificationScreen> {
  String _enteredOtp = ''; // stores entered OTP
  String _verificationId = ''; // stores Firebase verification ID
  bool _isLoading = false; // loading state

  // Send OTP to phone
  Future<void> _sendOtp() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>? ??
            {};

    final rawPhone = args['phone'] ?? '';

    // Remove leading 0 from phone number
    final phone = rawPhone.startsWith('0') ? rawPhone.substring(1) : rawPhone;

    try {
      if (mounted) setState(() => _isLoading = true);

      // Firebase phone verification
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+94$phone',
        timeout: const Duration(seconds: 60),

        // Auto verification (if SMS detected)
        verificationCompleted: (PhoneAuthCredential credential) async {
          print("AUTO VERIFIED");
          await FirebaseAuth.instance.signInWithCredential(credential);
        },

        // Error handling
        verificationFailed: (FirebaseAuthException e) {
          print("OTP ERROR: ${e.code} - ${e.message}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message ?? "Verification failed")),
            );
          }
        },

        // OTP sent successfully
        codeSent: (String verificationId, int? resendToken) {
          print("OTP SENT SUCCESS");
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
          }
        },

        // Timeout handling
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      print("GENERAL ERROR: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Call OTP when screen loads
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>? ??
            {};

    final role = args['role'];
    final phone = args['phone'] ?? '7X XXX XXXX';

    // Theme settings
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subtitleColor = dark ? Colors.grey[400]! : Colors.blueGrey;
    final phoneColor = dark ? Colors.white : Colors.black;
    final backBtnBg = dark ? AppColors.darkSurface : Colors.blue[50]!;
    final backBtnIcon = dark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,

      // App bar with back button
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: backBtnBg,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: backBtnIcon,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),

      // Main UI
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Title text
            Text(
              "Verify Your Phone\nNumber",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
                color: titleColor,
              ),
            ),

            const SizedBox(height: 15),

            // Phone number display
            RichText(
              text: TextSpan(
                text: "We've sent a code to  ",
                style: TextStyle(color: subtitleColor, fontSize: 16),
                children: [
                  TextSpan(
                    text: "+94 $phone",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: phoneColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // OTP input field
            OtpInput(
              length: 6,
              onCompleted: (otp) {
                setState(() {
                  _enteredOtp = otp;
                });
              },
            ),

            const SizedBox(height: 30),

            // Timer UI
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: dark ? Colors.grey[600] : Colors.blueGrey[300],
                ),
                const SizedBox(width: 5),
                Text(
                  "Resend code in ",
                  style: TextStyle(
                    color: dark ? Colors.grey[500] : Colors.blueGrey[400],
                  ),
                ),
                const Text(
                  "00:27",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Verify button
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: PrimaryButton(
                label: _isLoading ? "Verifying..." : "Verify & Continue",
                onPressed: () async {
                  // Check OTP sent
                  if (_verificationId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("OTP not sent yet")),
                    );
                    return;
                  }

                  // Check OTP length
                  if (_enteredOtp.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter valid 6-digit OTP")),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    // Create credential from OTP
                    final credential = PhoneAuthProvider.credential(
                      verificationId: _verificationId,
                      smsCode: _enteredOtp,
                    );

                    // Sign in user
                    final userCredential = await FirebaseAuth.instance
                        .signInWithCredential(credential);

                    final user = userCredential.user;
                    if (user == null) return;

                    // Fetch user data from Firestore
                    var doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();

                    if (doc.exists) {
                      final data = doc.data();
                      Map roles = data?['roles'] ?? {};

                      if (roles.isNotEmpty) {
                        // Match role
                        String matchedRole = (role != null &&
                                roles.containsKey(role.toLowerCase()))
                            ? role.toLowerCase()
                            : roles.keys.first.toString();

                        // Go to dashboard
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DashboardScreen(role: matchedRole),
                            ),
                          );
                        }
                      } else {
                        // No roles → signup
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                              settings: role != null
                                  ? RouteSettings(arguments: role)
                                  : null,
                            ),
                          );
                        }
                      }
                    } else {
                      // New user → signup
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                            settings: role != null
                                ? RouteSettings(arguments: role)
                                : null,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    // Invalid OTP
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid OTP")),
                    );
                  }

                  if (mounted) setState(() => _isLoading = false);
                },
                borderRadius: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
