import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/otp_box.dart';

import 'dashboard_screen.dart';
import 'signup_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String _enteredOtp = '';
  String _verificationId = '';
  bool _isLoading = false;

  // 🔹 SEND OTP
  Future<void> _sendOtp() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>? ??
            {};

    final rawPhone = args['phone'] ?? '';
    final phone = rawPhone.startsWith('0') ? rawPhone.substring(1) : rawPhone;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+94$phone',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Verification failed")),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });

        print("Verification ID: $verificationId");
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOtp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>? ??
            {};

    final role = args['role']; // Nullable
    final phone = args['phone'] ?? '7X XXX XXXX';

    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subtitleColor = dark ? Colors.grey[400]! : Colors.blueGrey;
    final phoneColor = dark ? Colors.white : Colors.black;
    final backBtnBg = dark ? AppColors.darkSurface : Colors.blue[50]!;
    final backBtnIcon = dark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
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
            OtpInput(
              length: 6,
              onCompleted: (otp) {
                setState(() {
                  _enteredOtp = otp;
                });
              },
            ),
            const SizedBox(height: 30),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: PrimaryButton(
                label: _isLoading ? "Verifying..." : "Verify & Continue",
                onPressed: () async {
                  if (_verificationId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("OTP not sent yet")),
                    );
                    return;
                  }

                  if (_enteredOtp.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter valid 6-digit OTP")),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    final credential = PhoneAuthProvider.credential(
                      verificationId: _verificationId,
                      smsCode: _enteredOtp,
                    );

                    // ✅ LOGIN ONCE
                    await FirebaseAuth.instance
                        .signInWithCredential(credential);

                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    //  CHECK FIRESTORE
                    var doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();

                    if (doc.exists) {
                      final data = doc.data();
                      Map roles = data?['roles'] ?? {};

                      if (roles.isNotEmpty) {
                        // Use pre-selected role if provided and exists, else pick first
                        String matchedRole = (role != null &&
                                roles.containsKey(role.toLowerCase()))
                            ? role.toLowerCase()
                            : roles.keys.first.toString();

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
                        // No roles found -> Signup
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
                      // Doc doesn't exist -> Signup
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid OTP")),
                    );
                  }

                  setState(() => _isLoading = false);
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
