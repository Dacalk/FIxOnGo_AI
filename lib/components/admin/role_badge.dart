import 'package:flutter/material.dart';

/// Displays a colored chip for a given role string.
class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge(this.role, {super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(role.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 11, color: cfg.text),
          const SizedBox(width: 4),
          Text(
            cfg.label,
            style: TextStyle(
              color: cfg.text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeCfg _config(String r) {
    switch (r) {
      case 'mechanic':
        return _BadgeCfg(
          label: 'Mechanic', icon: Icons.build_rounded,
          bg: const Color(0xFF1A3A1A), border: const Color(0xFF4CAF50),
          text: const Color(0xFF81C784),
        );
      case 'seller':
        return _BadgeCfg(
          label: 'Seller', icon: Icons.store_rounded,
          bg: const Color(0xFF3A2A0A), border: const Color(0xFFFFC107),
          text: const Color(0xFFFFD54F),
        );
      case 'deliver':
        return _BadgeCfg(
          label: 'Deliver', icon: Icons.delivery_dining_rounded,
          bg: const Color(0xFF0A2A3A), border: const Color(0xFF29B6F6),
          text: const Color(0xFF81D4FA),
        );
      case 'admin':
        return _BadgeCfg(
          label: 'Admin', icon: Icons.shield_rounded,
          bg: const Color(0xFF3A0A3A), border: const Color(0xFFCE93D8),
          text: const Color(0xFFCE93D8),
        );
      default: // user
        return _BadgeCfg(
          label: 'User', icon: Icons.person_rounded,
          bg: const Color(0xFF0A1A3A), border: const Color(0xFF1A4DBE),
          text: const Color(0xFF90CAF9),
        );
    }
  }
}

class _BadgeCfg {
  final String label;
  final IconData icon;
  final Color bg, border, text;
  const _BadgeCfg(
      {required this.label, required this.icon, required this.bg,
       required this.border, required this.text});
}
