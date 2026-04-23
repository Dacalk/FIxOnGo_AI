import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/otp_box.dart';

import 'dashboard_screen.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';
import 'dart:async';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String _enteredOtp = '';
  String _verificationId = '';
  int? _resendToken;
  bool _isLoading = false;
  bool _isResending = false;

  // Timer related
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  final AuthService _authService = AuthService();

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _resendOtp() async {
    if (!_canResend || _isResending) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};
    final phone = args['phone'] ?? '';

    setState(() => _isResending = true);

    try {
      await _authService.verifyPhone(
        phoneNumber: '+94$phone',
        resendToken: _resendToken,
        onCodeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isResending = false;
          });
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP Resent Successfully")),
          );
        },
        onVerificationFailed: (e) {
          setState(() => _isResending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? "Resend failed")),
          );
        },
        onVerificationCompleted: (credential) async {
          // Auto-verification handling
          try {
            final userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);
            if (userCredential.user != null) {
              _handleNavigation(userCredential.user!);
            }
          } catch (e) {
            print("Auto-verification error: $e");
          }
        },
      );
    } catch (e) {
      setState(() => _isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _handleNavigation(User user) async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};
    final role = args['role'] as String?;

    try {
      final doc = await _authService.getUserData(user.uid);

      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        Map roles = data?['roles'] ?? {};

        if (roles.isNotEmpty) {
          String matchedRole = (role != null &&
                  roles.containsKey(role.toLowerCase()))
              ? role.toLowerCase()
              : roles.keys.first.toString();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardScreen(role: matchedRole),
              ),
            );
          }
        } else {
          _goToSignup(role);
        }
      } else {
        _goToSignup(role);
      }
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  void _goToSignup(String? role) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SignupScreen(),
          settings:
              role != null ? RouteSettings(arguments: role) : null,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>? ??
          {};
      setState(() {
        _verificationId = args['verificationId'] ?? '';
        _resendToken = args['resendToken'];
      });
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
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
                  _canResend ? "Didn't receive code? " : "Resend code in ",
                  style: TextStyle(
                    color: dark ? Colors.grey[500] : Colors.blueGrey[400],
                  ),
                ),
                GestureDetector(
                  onTap: _canResend ? _resendOtp : null,
                  child: Text(
                    _canResend
                        ? (_isResending ? "Sending..." : "Resend")
                        : "00:${_secondsRemaining.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: _canResend ? AppColors.primaryBlue : Colors.blue,
                      fontWeight: FontWeight.w500,
                      decoration: _canResend ? TextDecoration.underline : null,
                    ),
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
                    final user = await _authService.verifyOtp(
                      verificationId: _verificationId,
                      smsCode: _enteredOtp,
                    );

                    if (user != null) {
                      await _handleNavigation(user);
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
