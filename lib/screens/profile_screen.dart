import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_provider.dart';

/// Profile screen — user settings, payment methods, vehicles, and sign out.
/// Features a bottom navigation bar.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String userPhotoUrl = '';
  String userRole = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final roles = data?['roles'] as Map<String, dynamic>? ?? {};
        final firstRole = roles.isNotEmpty ? roles.keys.first : '';
        final rd = roles.isNotEmpty
            ? roles[firstRole] as Map<String, dynamic>? ?? {}
            : <String, dynamic>{};

        setState(() {
          userName = rd['fullName']?.toString().isNotEmpty == true
              ? rd['fullName']
              : user.displayName ?? 'User';
          userEmail = data?['email']?.toString().isNotEmpty == true
              ? data!['email']
              : user.email ?? '';
          userPhone = data?['phone']?.toString().isNotEmpty == true
              ? data!['phone']
              : user.phoneNumber ?? '';
          userPhotoUrl = data?['photoUrl']?.toString() ?? user.photoURL ?? '';
          userRole = firstRole;
          isLoading = false;
        });
      } else {
        setState(() {
          userName = user.displayName ?? 'User';
          userEmail = user.email ?? '';
          userPhone = user.phoneNumber ?? '';
          userPhotoUrl = user.photoURL ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = user.displayName ?? 'User';
        userEmail = user.email ?? '';
        userPhotoUrl = user.photoURL ?? '';
        isLoading = false;
      });
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final topBgColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? const Color(0xFF1E2836) : const Color(0xFFF4F8FA);
    final signOutBgDark = AppColors.brandYellow;
    final signOutBgLight = const Color(
      0xFFFFF2F2,
    ); // Light red tint for sign out

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Profile',
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
                Icons.arrow_back,
                size: 18,
                color: dark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Edit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: topBgColor,
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      // ── Avatar ──
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: dark
                                    ? const Color(0xFF2A3A50)
                                    : const Color(0xFFD4E3FB),
                                width: 4,
                              ),
                            ),
                            child: ClipOval(
                              child: userPhotoUrl.isNotEmpty
                                  ? Image.network(
                                      userPhotoUrl,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          _getInitials(userName),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        _getInitials(userName),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(color: topBgColor, width: 3),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: TextStyle(fontSize: 13, color: subColor),
                      ),
                      if (userPhone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          userPhone,
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // ── Menu List ──
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: Icons.directions_car_outlined,
                                title: 'My Vehicles',
                                dark: dark,
                                titleColor: titleColor,
                                subColor: subColor,
                              ),
                              _buildMenuItem(
                                icon: Icons.credit_card_outlined,
                                title: 'Payment Methods',
                                dark: dark,
                                titleColor: titleColor,
                                subColor: subColor,
                              ),
                              _buildMenuItem(
                                icon: Icons.history,
                                title: 'Payment History',
                                dark: dark,
                                titleColor: titleColor,
                                subColor: subColor,
                              ),
                              _buildMenuItem(
                                icon: Icons.people_outline,
                                title: 'Emergency Contacts',
                                dark: dark,
                                titleColor: titleColor,
                                subColor: subColor,
                                onTap: () {
                                  Navigator.pushNamed(context, '/call-support');
                                },
                              ),
                              _buildMenuItem(
                                icon: Icons.help_outline,
                                title: 'Help & Support',
                                dark: dark,
                                titleColor: titleColor,
                                subColor: subColor,
                                showDivider: false,
                                onTap: () {
                                  Navigator.pushNamed(context, '/help-support');
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Sign Out Button ──
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  dark ? signOutBgDark : signOutBgLight,
                              foregroundColor: dark ? Colors.black : Colors.red,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout,
                                  size: 20,
                                  color: dark ? Colors.black : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sign Out',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: dark ? Colors.black : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(context, dark),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailingText,
    required bool dark,
    required Color titleColor,
    required Color subColor,
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: dark ? Colors.white : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: dark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primaryBlue, // Dark blue for icon
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(
                  trailingText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                ),
              if (trailingText != null) const SizedBox(width: 8),
              if (showDivider) // re-purposing showDivider as a generic check
                Icon(Icons.chevron_right, size: 20, color: subColor),
            ],
          ),
          onTap: onTap ?? () {},
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A2432) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              context,
              Icons.home,
              'Dashboard',
              false,
              dark,
              '/dashboard',
            ),
            _navItem(context, Icons.garage, 'Garage', false, dark, '/garage'),
            _navItem(
              context,
              Icons.payments,
              'Payment',
              false,
              dark,
              '/payment-history',
            ),
            _navItem(
              context,
              Icons.person,
              'Profile',
              true,
              dark,
              '/profile',
            ), // Active state
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    bool dark,
    String routeName,
  ) {
    final color = isActive
        ? AppColors.primaryBlue
        : (dark ? Colors.grey[500]! : Colors.grey[400]!);

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacementNamed(context, routeName);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
