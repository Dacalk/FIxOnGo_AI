import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Payment Successful screen — confirmation shown after a successful payment.
/// Displays a success icon, location info, map placeholder, payment details,
/// and action buttons ("Call To Mechanic" / "Back to Home").
class PaymentSuccessfulScreen extends StatelessWidget {
  const PaymentSuccessfulScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'] ?? 'user';
    final isMechanic = role == 'mechanic';

    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;
    final labelColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final valueColor = dark ? Colors.grey[300]! : Colors.grey[800]!;
    final btnColor = dark ? AppColors.brandYellow : AppColors.primaryBlue;
    final btnTextColor = dark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isMechanic ? 'Job Summary' : 'Receipt',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: dark ? AppColors.darkSurface : Colors.grey[100],
            child: IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: dark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: dark ? AppColors.darkSurface : Colors.grey[100],
              child: IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: dark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  // Share action
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Success Icon ──
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green[500],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Title ──
                  Text(
                    isMechanic ? 'Job Completed!' : 'Payment Successful',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMechanic
                        ? 'The payout has been added to your wallet.'
                        : 'Your payment has been processed successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: subColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Ella, Badulla',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ── Details Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          'Service Type',
                          'Mechanical Repair',
                          labelColor,
                          valueColor,
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          'Reference ID',
                          '#RQ-99231-EB',
                          labelColor,
                          valueColor,
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          'Date & Time',
                          'May 20, 2024 • 10:45 PM',
                          labelColor,
                          valueColor,
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          isMechanic ? 'Commission Fee' : 'Payment Method',
                          isMechanic ? 'Rs. 250.00' : '•••• 8182',
                          labelColor,
                          valueColor,
                        ),
                        const SizedBox(height: 20),
                        Divider(color: borderColor, thickness: 1),
                        const SizedBox(height: 16),
                        // Total Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isMechanic ? 'Total Payout' : 'Total Amount Paid',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            Text(
                              isMechanic ? 'Rs. 2,250.00' : 'Rs. 2,500.00',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ── Action Buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Primary action
                  if (isMechanic) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/', (route) => false);
                  } else {
                    // User might want to rate
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: btnTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isMechanic ? 'BACK TO DASHBOARD' : 'DOWNLOAD RECEIPT',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
          if (!isMechanic)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/', (route) => false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'BACK TO HOME',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: titleColor),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a label–value row for the payment details card.
  Widget _detailRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
