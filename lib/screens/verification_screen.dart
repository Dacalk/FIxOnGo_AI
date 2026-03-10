import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/otp_box.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the role + phone passed from the login screen
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>? ??
            {};
    final role = args['role'] ?? 'User';
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

            // ── Interactive OTP Input (type or paste) ──
            OtpInput(
              onCompleted: (otp) {
                debugPrint('OTP entered: $otp');
              },
            ),

            const SizedBox(height: 30),

            // Timer Row
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

            // ── Reusable Primary Button (Verify) ──
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: PrimaryButton(
                label: "Verify & Continue",
                onPressed: () {
                  Navigator.pushNamed(context, '/signup',
                      arguments: role);
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
