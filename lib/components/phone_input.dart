import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme_provider.dart';

/// A phone input field with country code selector, validation, and dark mode support.
///
/// Sri Lankan phone validation rules:
///  • Must be exactly 9 digits
///  • Must start with 7
///  • Valid prefixes: 70, 71, 72, 74, 75, 76, 77, 78
class PhoneInput extends StatelessWidget {
  final TextEditingController? controller;
  final String countryCode;
  final String countryFlag;
  final String hintText;
  final String? errorText;

  const PhoneInput({
    super.key,
    this.controller,
    this.countryCode = '+94',
    this.countryFlag = '🇱🇰',
    this.hintText = '7X XXX XXXX',
    this.errorText,
  });

  /// Validates a Sri Lankan phone number (without country code).
  /// Returns null if valid, or an error message string if invalid.
  static String? validateSriLankanPhone(String phone) {
    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');

    if (cleaned.isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Only digits are allowed';
    }

    if (cleaned.length != 9) {
      return 'Must be exactly 9 digits';
    }

    if (!cleaned.startsWith('7')) {
      return 'Must start with 7';
    }

    // Valid Sri Lankan mobile prefixes: 70, 71, 72, 74, 75, 76, 77, 78
    final validPrefixes = ['70', '71', '72', '74', '75', '76', '77', '78'];
    final prefix = cleaned.substring(0, 2);
    if (!validPrefixes.contains(prefix)) {
      return 'Invalid mobile number prefix';
    }

    return null; // valid
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final inputFill = dark ? AppColors.darkInputFill : Colors.indigo[50]!;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Country code box
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(12),
                border: dark
                    ? Border.all(color: Colors.grey[800]!, width: 0.5)
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    '$countryFlag $countryCode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.black,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: dark ? Colors.white70 : Colors.black,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Phone number text field
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(
                  color: dark ? Colors.white : Colors.black,
                ),
                keyboardType: TextInputType.phone,
                maxLength: 9,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: InputDecoration(
                  hintText: hintText,
                  counterText: '', // hide the "0/9" counter
                  hintStyle: TextStyle(
                    color: dark ? Colors.grey[600] : Colors.grey,
                  ),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: hasError
                        ? const BorderSide(color: Colors.red, width: 1.5)
                        : dark
                            ? BorderSide(
                                color: Colors.grey[800]!, width: 0.5)
                            : BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: hasError
                        ? const BorderSide(color: Colors.red, width: 1.5)
                        : dark
                            ? BorderSide(
                                color: Colors.grey[800]!, width: 0.5)
                            : BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: hasError
                          ? Colors.red
                          : dark
                              ? AppColors.brandYellow
                              : AppColors.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Error message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
