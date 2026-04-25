import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// A reusable role selection dropdown that expands in-place (no popup jump).
/// Options: User, Mechanic, Tow, Seller, Driver.
class RoleDropdown extends StatefulWidget {
  final ValueChanged<String?>? onChanged;
  final String? initialValue;

  const RoleDropdown({
    super.key,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<RoleDropdown> {
  String? _selectedRole;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialValue;
  }

  static const List<String> _roles = [
    'User',
    'Mechanic',
    'Tow',
  ];

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkSurface : Colors.grey[200]!;
    final textColor = dark ? Colors.white : Colors.black;
    final hintColor = Colors.grey[600]!;

    return Column(
      children: [
        // ── Header (tap to open/close) ──
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedRole ?? 'Choose Your Type',
                    style: TextStyle(
                      color: _selectedRole != null ? textColor : hintColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Expandable options list (stays in place) ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: _roles.map((role) {
                final isSelected = _selectedRole == role;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRole = role;
                      _isExpanded = false;
                    });
                    widget.onChanged?.call(role);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? (dark
                              ? AppColors.primaryBlue.withValues(alpha: 0.2)
                              : AppColors.primaryBlue.withValues(alpha: 0.08))
                          : Colors.transparent,
                      border: isSelected
                          ? Border.all(color: AppColors.primaryBlue, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
