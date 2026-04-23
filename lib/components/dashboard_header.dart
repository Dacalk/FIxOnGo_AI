import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Reusable dashboard header with greeting, avatar, and role-specific info.
class DashboardHeader extends StatelessWidget {
  final String userName;
  final String role;
  final String? vehicleInfo;
  final String? statusText;
  final String? photoUrl;
  final List<String>? availableRoles;
  final Function(String)? onSwitchRole;

  const DashboardHeader({
    super.key,
    required this.userName,
    required this.role,
    this.vehicleInfo,
    this.statusText,
    this.photoUrl,
    this.availableRoles,
    this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [const Color(0xFF0D1B3E), const Color(0xFF0A1628)]
              : [const Color(0xFFE3EDFF), const Color(0xFFF0F6FF)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + greeting + theme toggle
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    dark ? AppColors.darkSurface : Colors.blue[100],
                backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null || photoUrl!.isEmpty
                    ? Icon(
                        _roleIcon(),
                        color: dark
                            ? AppColors.brandYellow
                            : AppColors.primaryBlue,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WELCOME BACK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: dark
                            ? AppColors.brandYellow
                            : AppColors.primaryBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hello, $userName',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              // Theme toggle buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sun → Light mode
                    GestureDetector(
                      onTap: () {
                        if (dark) toggleTheme();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: !dark
                              ? Colors.orange.withValues(alpha: 0.15)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.light_mode,
                          size: 18,
                          color: dark ? Colors.grey[500] : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Moon → Dark mode
                    GestureDetector(
                      onTap: () {
                        if (!dark) toggleTheme();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: dark
                              ? Colors.blue.withValues(alpha: 0.15)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.dark_mode,
                          size: 18,
                          color: dark ? Colors.blue[300] : Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (availableRoles != null && availableRoles!.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    final nextIndex =
                        (availableRoles!.indexOf(role.toLowerCase()) + 1) %
                            availableRoles!.length;
                    final nextRole = availableRoles![nextIndex];
                    onSwitchRole?.call(nextRole);
                  },
                  icon: Icon(
                    Icons.swap_horiz,
                    color: dark ? Colors.white70 : AppColors.primaryBlue,
                    size: 20,
                  ),
                  tooltip: 'Switch Role',
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Status row
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: statusText ?? _defaultStatus(),
                    style: TextStyle(
                      fontSize: 13,
                      color: dark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                    children: [
                      if (role == 'User')
                        TextSpan(
                          text: ' Protected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: dark
                                ? AppColors.brandYellow
                                : AppColors.primaryBlue,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Vehicle / business info badge
              if (vehicleInfo != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: dark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _badgeEmoji(),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vehicleInfo!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _roleIcon() {
    final r = role.toLowerCase();
    switch (r) {
      case 'mechanic':
        return Icons.build_circle;
      case 'tow':
        return Icons.local_shipping;
      case 'seller':
        return Icons.storefront;
      case 'driver':
        return Icons.delivery_dining;
      default:
        return Icons.person;
    }
  }

  String _defaultStatus() {
    final r = role.toLowerCase();
    switch (r) {
      case 'mechanic':
        return 'Ready to help drivers today.';
      case 'tow':
        return 'Your truck is ready for action.';
      case 'seller':
        return 'Your shop is open and active.';
      case 'driver':
        return 'Ready for deliveries today.';
      default:
        return 'Stay safe on the road today.\nYour current status is';
    }
  }

  String _badgeEmoji() {
    final r = role.toLowerCase();
    switch (r) {
      case 'mechanic':
        return '🔧';
      case 'tow':
        return '🚛';
      case 'seller':
        return '🏪';
      case 'driver':
        return '🚚';
      default:
        return '🚗';
    }
  }
}
