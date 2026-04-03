import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// A reusable labeled dropdown for forms with dark mode support.
/// Used for Vehicle Type, Expertise, Towing Capacity, etc.
class FormDropdown extends StatefulWidget {
  final String label;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String? initialValue;

  const FormDropdown({
    super.key,
    required this.label,
    required this.hintText,
    required this.items,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<FormDropdown> createState() => _FormDropdownState();
}

class _FormDropdownState extends State<FormDropdown> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final labelColor = dark ? Colors.white : Colors.black;
    final fillColor = dark ? AppColors.darkSurface : Colors.grey[100]!;
    final textColor = dark ? Colors.white : Colors.black;
    final hintColor = dark ? Colors.grey[600]! : Colors.grey[400]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: labelColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selected,
              dropdownColor: dark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              hint: Text(widget.hintText, style: TextStyle(color: hintColor)),
              icon: Icon(Icons.keyboard_arrow_down, color: hintColor),
              items: widget.items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: TextStyle(color: textColor)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() => _selected = val ?? '');
                widget.onChanged?.call(val ?? '');
              },
            ),
          ),
        ),
      ],
    );
  }
}
