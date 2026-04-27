import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_provider.dart';
import '../components/form_input.dart';
import '../components/seller_bottom_nav.dart';
import 'payment_screen.dart';
import 'edit_profile_screen.dart';

/// Profile screen — user settings, payment methods, vehicles, and sign out.
/// Features a bottom navigation bar.
class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? role;
  final bool isEmbedded;

  /// Called when the user taps a nav item that should switch the parent Dashboard tab.
  /// Only used when [isEmbedded] is true.
  final void Function(int tabIndex)? onSwitchTab;

  const ProfileScreen({
    super.key,
    this.userData,
    this.role,
    this.isEmbedded = false,
    this.onSwitchTab,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String userPhotoUrl = '';
  String userRole = '';
  Map<String, dynamic> roleData = {};
  List<String> availableRoles = [];
  bool isLoading = true;
  bool hasPassword = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if data is available
    if (widget.userData != null) {
      userName = widget.userData!['fullName'] ?? '';
      userEmail = widget.userData!['email'] ?? '';
    }
    userRole = widget.role ?? 'User';

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check providers for password status
    final providers = user.providerData.map((p) => p.providerId).toList();
    hasPassword = providers.contains('password');

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final roles = data?['roles'] as Map<String, dynamic>? ?? {};

        // Use the passed role or resolve dynamically
        String effectiveRole =
            widget.role ?? (roles.isNotEmpty ? roles.keys.first : 'User');

        final rd =
            roles[effectiveRole.toLowerCase()] as Map<String, dynamic>? ??
                roles[effectiveRole] as Map<String, dynamic>? ??
                (roles.isNotEmpty ? roles.values.first : {});

        final fbName = (data?['displayName']?.toString().isNotEmpty == true)
            ? data!['displayName'].toString()
            : null;

        setState(() {
          if (effectiveRole.toLowerCase() == 'seller' &&
              rd['shopName']?.toString().isNotEmpty == true) {
            userName = rd['shopName'];
          } else {
            userName = rd['fullName']?.toString().isNotEmpty == true
                ? rd['fullName']
                : fbName ?? user.displayName ?? 'User';
          }
          userEmail = data?['email']?.toString().isNotEmpty == true
              ? data!['email']
              : user.email ?? '';
          userPhone = data?['phone']?.toString().isNotEmpty == true
              ? data!['phone']
              : user.phoneNumber ?? '';
          userPhotoUrl = data?['photoUrl']?.toString() ?? user.photoURL ?? '';
          userRole = effectiveRole;
          roleData = rd;
          availableRoles = roles.keys.toList();
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            userName = user.displayName ?? 'User';
            userEmail = user.email ?? '';
            userPhone = user.phoneNumber ?? '';
            userPhotoUrl = user.photoURL ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = user.displayName ?? 'User';
          userEmail = user.email ?? '';
          userPhotoUrl = user.photoURL ?? '';
          isLoading = false;
        });
      }
    }
  }

  void _showPasswordDialog() {
    final TextEditingController passController = TextEditingController();
    final dark = isDarkMode(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dark ? AppColors.darkSurface : Colors.white,
        title: Text(
          hasPassword ? 'Change Password' : 'Enable Email Login',
          style: TextStyle(color: dark ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasPassword
                  ? 'Enter your new password below.'
                  : 'Set a password to enable logging in with your email address.',
              style: TextStyle(
                  fontSize: 13,
                  color: dark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            FormInput(
              label: 'New Password',
              hintText: '••••••••',
              controller: passController,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password must be at least 6 characters')),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.updatePassword(passController.text.trim());
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password updated successfully!')),
                    );
                    _loadProfile(); // Refresh provider status
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text(hasPassword ? 'Update' : 'Enable'),
          ),
        ],
      ),
    );
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

  Widget _buildAvatar() {
    final url = userPhotoUrl;
    final initials = Center(
      child: Text(
        _getInitials(userName),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );

    if (url.isEmpty) return initials;

    // base64 data URL (saved locally)
    if (url.startsWith('data:')) {
      try {
        final comma = url.indexOf(',');
        final bytes = _base64ToBytes(url.substring(comma + 1));
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
          errorBuilder: (_, __, ___) => initials,
        );
      } catch (_) {
        return initials;
      }
    }

    // Remote URL
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: 100,
      height: 100,
      errorBuilder: (_, __, ___) => initials,
    );
  }

  Uint8List _base64ToBytes(String base64Str) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final cleaned = base64Str.replaceAll(RegExp(r'\s'), '');
    final result = <int>[];
    for (var i = 0; i < cleaned.length; i += 4) {
      final c0 = chars.indexOf(cleaned[i]);
      final c1 = chars.indexOf(cleaned[i + 1]);
      final c2 = cleaned[i + 2] == '=' ? 0 : chars.indexOf(cleaned[i + 2]);
      final c3 = cleaned[i + 3] == '=' ? 0 : chars.indexOf(cleaned[i + 3]);
      result.add(((c0 << 2) | (c1 >> 4)) & 0xFF);
      if (cleaned[i + 2] != '=') result.add(((c1 << 4) | (c2 >> 2)) & 0xFF);
      if (cleaned[i + 3] != '=') result.add(((c2 << 6) | c3) & 0xFF);
    }
    return Uint8List.fromList(result);
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
    final signOutBgLight = const Color(0xFFFFF2F2);

    final content = SingleChildScrollView(
      child: Column(
        children: [
          // ── Profile Header ──
          Container(
            width: double.infinity,
            color: topBgColor,
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),
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
                        child: _buildAvatar(),
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

          // ── Seller Shop Info ──
          if (userRole.toLowerCase() == 'seller')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.store,
                            color: AppColors.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Shop Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _shopInfoRow('Shop Name', roleData['shopName'] ?? 'No Name',
                      Icons.business, subColor, titleColor),
                  const Divider(height: 24),
                  _shopInfoRow(
                      'Category',
                      roleData['category'] ?? 'No Category',
                      Icons.category,
                      subColor,
                      titleColor),
                  const Divider(height: 24),
                  _shopInfoRow('Address', roleData['address'] ?? 'No Address',
                      Icons.location_on, subColor, titleColor),
                ],
              ),
            ),

          // ── Menu List ──
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        dark: dark,
                        titleColor: titleColor,
                        subColor: subColor,
                        onTap: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(
                                roleData: roleData,
                                role: userRole,
                                initialPhotoUrl: userPhotoUrl,
                                email: userEmail,
                                phone: userPhone,
                              ),
                            ),
                          );
                          if (updated == true) _loadProfile();
                        },
                      ),
                      if (userRole.toLowerCase() != 'seller')
                        _buildMenuItem(
                          icon: userRole.toLowerCase() == 'tow'
                              ? Icons.local_shipping_outlined
                              : Icons.directions_car_outlined,
                          title: userRole.toLowerCase() == 'tow'
                              ? 'My Tow Truck'
                              : 'My Vehicles',
                          dark: dark,
                          titleColor: titleColor,
                          subColor: subColor,
                          onTap: () {
                            if (userRole.toLowerCase() == 'tow') {
                              Navigator.pushNamed(context, '/tow-vehicle');
                            } else {
                              Navigator.pushNamed(context, '/garage');
                            }
                          },
                        ),
                      _buildMenuItem(
                        icon: Icons.credit_card_outlined,
                        title: 'Payment Methods',
                        dark: dark,
                        titleColor: titleColor,
                        subColor: subColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(role: userRole),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.history,
                        title: 'Payment History',
                        dark: dark,
                        titleColor: titleColor,
                        subColor: subColor,
                        onTap: () {
                          if (widget.isEmbedded && widget.onSwitchTab != null) {
                            // Switch to Payment tab (index 2) within the Dashboard
                            widget.onSwitchTab!(2);
                          } else {
                            Navigator.pushNamed(
                              context,
                              '/payment-history',
                              arguments: {
                                'isProviderView':
                                    userRole.toLowerCase() == 'mechanic' ||
                                        userRole.toLowerCase() == 'tow',
                                'filterType': userRole.toLowerCase() == 'tow'
                                    ? 'towing'
                                    : (userRole.toLowerCase() == 'mechanic'
                                        ? 'mechanic'
                                        : null),
                              },
                            );
                          }
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.security,
                        title: 'Account Security',
                        trailingText: hasPassword ? 'Protected' : 'Incomplete',
                        dark: dark,
                        titleColor: titleColor,
                        subColor: subColor,
                        onTap: _showPasswordDialog,
                      ),
                      _buildMenuItem(
                        icon: Icons.people_outline,
                        title: 'Emergency Contacts',
                        dark: dark,
                        titleColor: titleColor,
                        subColor: subColor,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/call-support',
                          arguments: userRole,
                        ),
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        dark: dark,
                        titleColor: titleColor,
                        subColor: subColor,
                        showDivider: false,
                        onTap: () =>
                            Navigator.pushNamed(context, '/help-support'),
                      ),
                      if (availableRoles.length > 1)
                        _buildMenuItem(
                          icon: Icons.swap_horiz,
                          title: 'Switch Mode',
                          trailingText: userRole.toUpperCase(),
                          dark: dark,
                          titleColor: titleColor,
                          subColor: subColor,
                          onTap: () {
                            final nextIndex =
                                (availableRoles.indexOf(userRole) + 1) %
                                    availableRoles.length;
                            final nextRole = availableRoles[nextIndex];
                            Navigator.pushReplacementNamed(
                                context, '/dashboard',
                                arguments: nextRole);
                          },
                          showDivider: false,
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
                      await GoogleAuthService().signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dark ? signOutBgDark : signOutBgLight,
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
        ],
      ),
    );

    if (widget.isEmbedded) return content;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
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
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/dashboard',
                  arguments: userRole,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    roleData: roleData,
                    role: userRole,
                    initialPhotoUrl: userPhotoUrl,
                    email: userEmail,
                    phone: userPhone,
                  ),
                ),
              );
              if (updated == true) _loadProfile();
            },
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
      body: content,
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
              color: Colors.white,
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
              color: AppColors.primaryBlue,
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
              Icon(Icons.chevron_right, size: 20, color: subColor),
            ],
          ),
          onTap: onTap ?? () {},
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              height: 1,
              color:
                  dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, bool dark) {
    // Seller: use the shared 4-tab nav, Profile = index 3
    if (userRole.toLowerCase() == 'seller') {
      return SellerBottomNav(currentIndex: 3, role: userRole);
    }

    // Other roles: custom row-based nav
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111D35) : Colors.white,
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
            _navItem(context, Icons.home_rounded, 'Dashboard', false, dark,
                '/dashboard'),
            _navItem(
                context,
                userRole.toLowerCase() == 'mechanic'
                    ? Icons.shopping_bag
                    : Icons.history_rounded,
                userRole.toLowerCase() == 'mechanic' ? 'Shop' : 'Activities',
                false,
                dark,
                userRole.toLowerCase() == 'mechanic'
                    ? '/mechanic-shop'
                    : '/job-history'),
            _navItem(context, Icons.payments_rounded, 'Payment', false, dark,
                '/payment-history'),
            _navItem(context, Icons.person_rounded, 'Profile', true, dark,
                '/profile'),
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
    String? routeName,
  ) {
    final color = isActive
        ? (dark ? AppColors.brandYellow : AppColors.primaryBlue)
        : (dark ? Colors.grey[600]! : Colors.grey[400]!);

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          if (label == 'Dashboard') {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
              arguments: userRole,
            );
          } else if (routeName != null) {
            if (routeName == '/payment-history') {
              Navigator.pushReplacementNamed(
                context,
                routeName,
                arguments: {
                  'isProviderView': userRole.toLowerCase() == 'mechanic' ||
                      userRole.toLowerCase() == 'tow',
                  'filterType': userRole.toLowerCase() == 'tow'
                      ? 'towing'
                      : (userRole.toLowerCase() == 'mechanic'
                          ? 'mechanic'
                          : null),
                },
              );
            } else {
              Navigator.pushReplacementNamed(context, routeName);
            }
          }
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

  Widget _shopInfoRow(String label, String value, IconData icon, Color subColor,
      Color titleColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: subColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: subColor)),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
