import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme_provider.dart';

/// A row of 4 OTP input fields that support:
///  • Typing one digit per box (auto-advances to the next)
///  • Backspace to go back to the previous box
///  • Pasting a full 4-digit code (distributes digits across boxes)
///
/// Returns the complete OTP string via [onCompleted] when all 4 digits are filled.
class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;

  const OtpInput({super.key, this.length = 6, this.onCompleted});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// Get the combined OTP string
  String get _otp => _controllers.map((c) => c.text).join();

  /// Handle paste: distribute digits across all boxes
  void _handlePaste(String pastedText) {
    final digits = pastedText.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < widget.length && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }
    // Focus the last filled box or the next empty one
    final focusIndex = digits.length >= widget.length
        ? widget.length - 1
        : digits.length;
    _focusNodes[focusIndex].requestFocus();

    if (digits.length >= widget.length) {
      widget.onCompleted?.call(_otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final boxColor = dark ? AppColors.darkSurface : const Color(0xFFF1F6FF);
    final textColor = dark ? Colors.white : Colors.black;
    final cursorColor = dark ? AppColors.brandYellow : AppColors.primaryBlue;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return Container(
          width: 50,
          height: 70,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(15),
            border: dark
                ? Border.all(color: Colors.grey[800]!, width: 0.5)
                : null,
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            cursorColor: cursorColor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            decoration: const InputDecoration(
              counterText: '', // hide the "0/1" counter
              border: InputBorder.none,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              // Intercept paste of multiple digits
              _OtpPasteFormatter(length: widget.length, onPaste: _handlePaste),
            ],
            onChanged: (value) {
              if (value.length == 1 && index < widget.length - 1) {
                // Move focus to next box
                _focusNodes[index + 1].requestFocus();
              }
              if (_otp.length == widget.length) {
                widget.onCompleted?.call(_otp);
              }
            },
            onTap: () {
              // Select all text when tapping a box
              _controllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controllers[index].text.length,
              );
            },
          ),
        );
      }),
    );
  }
}

/// Custom formatter that detects a pasted multi-digit string and triggers
/// the paste handler instead of inserting into a single field.
class _OtpPasteFormatter extends TextInputFormatter {
  final int length;
  final ValueChanged<String> onPaste;

  _OtpPasteFormatter({required this.length, required this.onPaste});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If user pasted more than 1 digit, treat it as a full OTP paste
    if (newValue.text.length > 1) {
      // Schedule the paste handler after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPaste(newValue.text);
      });
      // Only keep the first digit in this field
      return TextEditingValue(
        text: newValue.text[0],
        selection: const TextSelection.collapsed(offset: 1),
      );
    }
    return newValue;
  }
}
