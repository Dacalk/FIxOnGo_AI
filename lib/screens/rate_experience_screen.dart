import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Rate Your Experience screen — post-service feedback form.
/// Allows the user to confirm service completion, rate the mechanic,
/// select feedback tags, and write comments.
class RateExperienceScreen extends StatefulWidget {
  const RateExperienceScreen({super.key});

  @override
  State<RateExperienceScreen> createState() => _RateExperienceScreenState();
}

class _RateExperienceScreenState extends State<RateExperienceScreen> {
  bool? _isFixed; // true = Yes Fixed, false = No not Fixed
  int _rating = 4; // default 4 stars
  final Set<String> _selectedTags = {'Professional'};
  final TextEditingController _commentController = TextEditingController();

  static const List<String> _feedbackTags = [
    'On Time',
    'Professional',
    'Knowledgeable',
    'Fair Pricing',
    'Good Communication',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;
    final btnColor = dark ? AppColors.brandYellow : AppColors.primaryBlue;
    final btnTextColor = dark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Rate Your Experience',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: dark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ── Avatar ──
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: dark
                        ? const Color(0xFF1E3350)
                        : Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: dark ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Name ──
                  Text(
                    'Dulan Thabrew',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Post - service Verification',
                    style: TextStyle(fontSize: 13, color: subColor),
                  ),

                  const SizedBox(height: 28),

                  // ── Was the service completed? ──
                  Text(
                    'WAS THE SERVICE COMPLETED ?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _completionButton('Yes Fixed', true, dark),
                      const SizedBox(width: 14),
                      _completionButton('No, not Fixed', false, dark),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Rate Mechanic Service ──
                  Text(
                    'Rate Mechanic Service',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _rating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            size: 44,
                            color: Colors.amber,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // ── What went well? (light) / tags directly (dark) ──
                  Text(
                    'What went well?',
                    style: TextStyle(fontSize: 14, color: subColor),
                  ),
                  const SizedBox(height: 12),

                  // Feedback tags
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _feedbackTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTags.remove(tag);
                            } else {
                              _selectedTags.add(tag);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : borderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : titleColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Comment label ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tell us more about the service (optional)',
                      style: TextStyle(fontSize: 13, color: subColor),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Comment field ──
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 3,
                      style: TextStyle(fontSize: 14, color: titleColor),
                      decoration: InputDecoration(
                        hintText: 'Write your comments here...',
                        hintStyle: TextStyle(
                          color: dark ? Colors.grey[600] : Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Submit Feedback ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Submit feedback logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: btnTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Submit Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completionButton(String label, bool value, bool dark) {
    final isSelected = _isFixed == value;
    final selectedColor = value ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: () => setState(() => _isFixed = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : (dark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? selectedColor
                : (dark ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}
