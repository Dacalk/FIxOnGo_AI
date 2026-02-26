import 'package:flutter/material.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.black,
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
            const Text(
              "Verify Your Phone\nNumber",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 15),
            RichText(
              text: const TextSpan(
                text: "We've sent a code to ",
                style: TextStyle(color: Colors.blueGrey, fontSize: 16),
                children: [
                  TextSpan(
                    text: "+94 77 123 4567",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => _otpBox(context, index == 0 ? "4" : ""),
              ),
            ),

            const SizedBox(height: 30),

            // Timer Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: Colors.blueGrey[300],
                ),
                const SizedBox(width: 5),
                Text(
                  "Resend code in ",
                  style: TextStyle(color: Colors.blueGrey[400]),
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

            // Verify Button
            Container(
              width: double.infinity,
              height: 55,
              margin: const EdgeInsets.only(bottom: 40),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF), // Vibrant Blue
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Verify & Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(BuildContext context, String value) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF), // Very light blue
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
