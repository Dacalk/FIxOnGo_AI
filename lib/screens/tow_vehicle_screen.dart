import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_provider.dart';

/// Tow Vehicle Screen — shows the tow driver's real truck info from Firestore.
class TowVehicleScreen extends StatefulWidget {
  const TowVehicleScreen({super.key});

  @override
  State<TowVehicleScreen> createState() => _TowVehicleScreenState();
}

class _TowVehicleScreenState extends State<TowVehicleScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _towData = {};

  @override
  void initState() {
    super.initState();
    _loadTowData();
  }

  Future<void> _loadTowData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final roles = doc.data()?['roles'] as Map<String, dynamic>? ?? {};
        final towData = roles['tow'] as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() {
            _towData = towData;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF8F9FA);
    final topBarColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? const Color(0xFF1E2836) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Tow Truck',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: dark
                            ? [const Color(0xFF1E3A5F), const Color(0xFF15294A)]
                            : [const Color(0xFF1A4DBE), const Color(0xFF0D286F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        // Truck Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(38),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _towData['truckModel']?.isNotEmpty == true
                              ? _towData['truckModel']
                              : 'No Truck Registered',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _towData['plate']?.isNotEmpty == true
                                ? _towData['plate']
                                : 'No plate registered',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Info Card ──
                  Text(
                    'Truck Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: dark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        _infoTile(
                          icon: Icons.local_shipping_outlined,
                          label: 'Truck Model',
                          value: _towData['truckModel']?.toString().isNotEmpty == true
                              ? _towData['truckModel']
                              : 'Not set',
                          titleColor: titleColor,
                          subColor: subColor,
                          dark: dark,
                        ),
                        _divider(dark),
                        _infoTile(
                          icon: Icons.numbers_outlined,
                          label: 'Plate Number',
                          value: _towData['plate']?.toString().isNotEmpty == true
                              ? _towData['plate']
                              : 'Not set',
                          titleColor: titleColor,
                          subColor: subColor,
                          dark: dark,
                        ),
                        _divider(dark),
                        _infoTile(
                          icon: Icons.straighten,
                          label: 'Towing Capacity',
                          value: _towData['towingCapacity']?.toString().isNotEmpty == true
                              ? '${_towData['towingCapacity']} Tons'
                              : 'Not set',
                          titleColor: titleColor,
                          subColor: subColor,
                          dark: dark,
                        ),
                        _divider(dark),
                        _infoTile(
                          icon: Icons.badge_outlined,
                          label: 'NIC / ID',
                          value: _towData['nic']?.toString().isNotEmpty == true
                              ? _towData['nic']
                              : 'Not set',
                          titleColor: titleColor,
                          subColor: subColor,
                          dark: dark,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Status Section ──
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: dark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(38),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.check_circle,
                              color: Colors.green, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REGISTERED',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your tow truck is active on FixOnGo',
                              style: TextStyle(
                                fontSize: 12,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Edit Button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Go to Edit Profile to update your truck details.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit Truck Details',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            dark ? AppColors.brandYellow : AppColors.primaryBlue,
                        foregroundColor: dark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color titleColor,
    required Color subColor,
    required bool dark,
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF253447) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: subColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: dark ? Colors.white10 : Colors.black.withAlpha(12),
      ),
    );
  }
}
