import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/osm_map_widget.dart';
import '../services/map_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Screen shown when a mechanic has accepted the service request.
/// Displays mechanic info, pricing breakdown, and payment options.
class MechanicAcceptedScreen extends StatefulWidget {
  const MechanicAcceptedScreen({super.key});

  @override
  State<MechanicAcceptedScreen> createState() => _MechanicAcceptedScreenState();
}

class _MechanicAcceptedScreenState extends State<MechanicAcceptedScreen> {
  int _selectedPayment = 0; // 0=Card, 1=Cash, 2=Paypal

  final MapController _mapController = MapController();

  StreamSubscription? _requestSub;
  String? _requestId;
  String? _mechanicId;
  Map<String, dynamic>? _requestData;
  Map<String, dynamic>? _mechanicData;
  String _paymentStatus = 'pending';
  LatLng? _userLatLng;
  LatLng? _mechanicLatLng;
  List<LatLng> _routePoints = [];
  String? _eta;
  bool _isProcessingPayment = false;
  bool _isRemovingTool = false;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    // Arguments handling
    Future.microtask(() {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _requestId = args is String ? args : null);
          _startListeningToRequest();
        }
      });
    });
  }

  Future<void> _handlePayment() async {
    if (_isProcessingPayment) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isProcessingPayment = true);
    });

    // Simulate banking delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (_requestId != null) {
      try {
        final reqDoc = await FirebaseFirestore.instance
            .collection('requests')
            .doc(_requestId)
            .get();
        final reqData = reqDoc.data();

        if (reqData != null) {
          // 1. Create Formal Payment Record
          await FirebaseFirestore.instance.collection('payments').add({
            'requestId': _requestId,
            'userId': reqData['userId'],
            'mechanicId': reqData['mechanicId'],
            'mechanicName': reqData['mechanicName'] ?? 'Mechanic',
            'userName': reqData['userName'] ?? 'User',
            'amount': reqData['totalPrice'] ?? 2000,
            'currency': 'LKR',
            'status': 'success',
            'createdAt': FieldValue.serverTimestamp(),
          });

          // 2. Mark Request status
          await FirebaseFirestore.instance
              .collection('requests')
              .doc(_requestId)
              .update({'paymentStatus': 'paid'});
        }
      } catch (e) {
        print("Error saving payment: $e");
      }
    }

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        Navigator.pushReplacementNamed(context, '/order-tracking',
            arguments: _requestId);
      }
    });
  }

  void _startListeningToRequest() {
    if (_requestId == null) return;
    _requestSub = FirebaseFirestore.instance
        .collection('requests')
        .doc(_requestId)
        .snapshots()
        .listen((snap) async {
      if (snap.exists) {
        final data = snap.data()!;

        final uLoc = data['userLocation'] as Map<String, dynamic>;
        final mId = data['mechanicId'];
        _mechanicId = mId;

        // Fetch User location (should be fixed usually, but could move)
        final userLatLng = LatLng(uLoc['lat'], uLoc['lng']);

        // Fetch Mechanic current location from users collection
        final mechSnap =
            await FirebaseFirestore.instance.collection('users').doc(mId).get();
        if (mechSnap.exists) {
          final mData = mechSnap.data()!;
          _mechanicData = mData['roles']['mechanic'];
          final mLoc = _mechanicData!['location'] as Map<String, dynamic>?;

          if (mLoc != null) {
            final mechLatLng = LatLng(mLoc['lat'], mLoc['lng']);

            if (!mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _userLatLng = userLatLng;
                  _mechanicLatLng = mechLatLng;
                  _requestData = data;
                  _paymentStatus = data['paymentStatus'] ?? 'pending';
                });
                _updateRoute();
              }
            });
          }
        }
      }
    });
  }

  Future<void> _updateRoute() async {
    if (_userLatLng == null || _mechanicLatLng == null) return;
    try {
      final route = await MapService.instance
          .getDirections(_mechanicLatLng!, _userLatLng!);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _routePoints = route.points;
            _eta = '${(route.durationSeconds / 60).ceil()} mins';
          });
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[500]! : Colors.grey[600]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // â”€â”€ Map area (top portion) â”€â”€
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.32,
            child: _buildMap(dark),
          ),

          // â”€â”€ Back button â”€â”€
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkSurface : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          // â”€â”€ Bottom scrollable content â”€â”€
          DraggableScrollableSheet(
            initialChildSize: 0.70,
            minChildSize: 0.55,
            maxChildSize: 0.90,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: dark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Status Header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STATUS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: subColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _eta != null
                                      ? 'Arriving in $_eta'
                                      : 'Calculating ETA...',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF1E3350)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Live',
                                style:
                                    TextStyle(fontSize: 12, color: titleColor),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.circle,
                                  color: Colors.red, size: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 4),

                    // â”€â”€ Mechanic info card â”€â”€
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryBlue,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name & details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _mechanicData?['fullName'] ?? 'Mechanic',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _mechanicData?['vehicleType'] ??
                                      'Professional Mechanic',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '4.9',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: titleColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/voice-call',
                                      ),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: dark
                                              ? AppColors.darkBackground
                                              : AppColors.primaryBlue
                                                  .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: dark
                                              ? Colors.white70
                                              : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/video-call',
                                      ),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: dark
                                              ? AppColors.darkBackground
                                              : AppColors.primaryBlue
                                                  .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.videocam,
                                          size: 14,
                                          color: dark
                                              ? Colors.white70
                                              : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/mechanic-chat',
                                      ),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: dark
                                              ? AppColors.darkBackground
                                              : AppColors.primaryBlue
                                                  .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.chat_bubble,
                                          size: 14,
                                          color: dark
                                              ? Colors.white70
                                              : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. 2000',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Est. price',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // â”€â”€ Current Location â”€â”€
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 18, top: 2),
                      child: Text(
                        'Little Adams Peak Ella Road, Badulla',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // â”€â”€ Request Tools â”€â”€
                    GestureDetector(
                      onTap: () {
                        if (_mechanicId != null) {
                          Navigator.pushNamed(
                            context,
                            '/user-shop-view',
                            arguments: {
                              'mechanicId': _mechanicId,
                              'mechanicName':
                                  _mechanicData?['fullName'] ?? 'Mechanic',
                              'requestId': _requestId,
                            },
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings,
                              color: dark ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Request Tools',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: subColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'If you want Tool you can Request',
                      style: TextStyle(fontSize: 11, color: subColor),
                    ),
                    const SizedBox(height: 16),

                    // â”€â”€ Total Price breakdown â”€â”€
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Price',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _priceRow(
                              'Service Fee',
                              'Rs. ${(_requestData?['basePrice'] ?? 2000).toString()}',
                              dark),
                          const SizedBox(height: 6),
                          ...((_requestData?['tools'] as List<dynamic>?) ?? [])
                              .asMap()
                              .entries
                              .map((entry) {
                            final tool = entry.value;
                            final idx = entry.key;
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _priceRow(tool['name'] ?? 'Tool',
                                          'Rs. ${tool['price'] ?? 0}', dark),
                                    ),
                                    if (_paymentStatus != 'paid')
                                      IconButton(
                                        icon: _isRemovingTool
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.red),
                                                ),
                                              )
                                            : const Icon(Icons.delete_outline,
                                                color: Colors.red, size: 20),
                                        onPressed: _isRemovingTool
                                            ? null
                                            : () =>
                                                _handleRemoveTool(idx, tool),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        splashRadius: 24,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                            );
                          }),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(fontSize: 12, color: subColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Rs. ${(_requestData?['totalPrice'] ?? 2000).toString()}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // â”€â”€ Payment Method â”€â”€
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Payment tabs
                          Row(
                            children: [
                              _paymentTab(0, Icons.credit_card, 'Card', dark),
                              const SizedBox(width: 10),
                              _paymentTab(1, Icons.money, 'Cash', dark),
                              const SizedBox(width: 10),
                              _paymentTab(2, Icons.payment, 'Paypal', dark),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Saved cards
                          _savedCardRow(
                            'Visa card ending in 5689',
                            dark,
                            borderColor,
                          ),
                          const SizedBox(height: 8),
                          _savedCardRow(
                            'Mastercard ending in 5741',
                            dark,
                            borderColor,
                          ),
                          const SizedBox(height: 8),
                          // Link PayPal
                          _actionRow(
                            icon: Icons.payment,
                            label: 'Link Paypal Account',
                            dark: dark,
                            borderColor: borderColor,
                            labelColor: AppColors.primaryBlue,
                          ),
                          const SizedBox(height: 8),
                          // Add Card
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/add-card');
                            },
                            child: _actionRow(
                              icon: Icons.credit_card,
                              label: 'ADD CARD',
                              dark: dark,
                              borderColor: borderColor,
                              showArrow: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // â”€â”€ Confirm + Cancel buttons â”€â”€
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: _isProcessingPayment
                                ? 'Processing...'
                                : 'Confirm',
                            onPressed: _isProcessingPayment
                                ? null
                                : () {
                                    _handlePayment();
                                  },
                            borderRadius: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Rs. 2,000+',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, bool dark) {
    final labelColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final amountColor = dark ? Colors.white : Colors.black;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 8, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: amountColor,
          ),
        ),
      ],
    );
  }

  Widget _paymentTab(int index, IconData icon, String label, bool dark) {
    final isSelected = _selectedPayment == index;
    final selectedBg = AppColors.primaryBlue.withValues(alpha: 0.1);
    final unselectedBg = dark ? const Color(0xFF1A2E4A) : Colors.grey[100]!;

    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primaryBlue, width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primaryBlue
                  : (dark ? Colors.white60 : Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primaryBlue
                    : (dark ? Colors.white60 : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedCardRow(String text, bool dark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.credit_card,
            size: 18,
            color: dark ? Colors.white60 : Colors.grey[500],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Icon(
            Icons.circle,
            size: 10,
            color: dark ? Colors.grey[700] : Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required bool dark,
    required Color borderColor,
    Color? labelColor,
    bool showArrow = false,
  }) {
    final textColor = labelColor ?? (dark ? Colors.white : Colors.black);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: labelColor ?? (dark ? Colors.white60 : Colors.grey[500]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (showArrow)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: dark ? Colors.grey[600] : Colors.grey[400],
            ),
        ],
      ),
    );
  }

  Widget _buildMap(bool dark) {
    final center = _userLatLng ?? const LatLng(6.9271, 79.8612);
    final markers = <Marker>[];

    if (_userLatLng != null) {
      markers.add(
        Marker(
          point: _userLatLng!,
          width: 40,
          height: 40,
          child: Icon(
            Icons.location_on,
            size: 30,
            color: AppColors.primaryBlue,
          ),
        ),
      );
    }

    if (_mechanicLatLng != null) {
      markers.add(
        Marker(
          point: _mechanicLatLng!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1E3350) : const Color(0xFF2C3E50),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.build, color: Colors.white, size: 18),
          ),
        ),
      );
    }

    return OsmMapWidget(
      center: center,
      zoom: 13,
      mapController: _mapController,
      markers: markers,
      polylinePoints: _routePoints.isNotEmpty ? _routePoints : null,
      showLocateButton: false,
    );
  }

  Future<void> _handleRemoveTool(int index, Map<String, dynamic> tool) async {
    if (_requestId == null || _isRemovingTool) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isRemovingTool = true);
    });

    try {
      // Use FieldValue for atomic updates - more robust on Web than transactions
      final requestRef =
          FirebaseFirestore.instance.collection('requests').doc(_requestId);

      // Safe price extraction for increment
      num toolPrice = 0;
      final rawToolPrice = tool['price'];
      if (rawToolPrice is num) {
        toolPrice = rawToolPrice;
      } else if (rawToolPrice is String) {
        toolPrice = num.tryParse(rawToolPrice) ?? 0;
      }

      // 1. Update Request (Atomic)
      await requestRef.update({
        'tools': FieldValue.arrayRemove([tool]),
        'totalPrice': FieldValue.increment(-toolPrice),
      });

      // 2. Restore Stock (Atomic)
      final String? productId = tool['productId']?.toString();
      if (productId != null &&
          productId.isNotEmpty &&
          _mechanicId != null &&
          _mechanicId!.isNotEmpty) {
        final productRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_mechanicId)
            .collection('products')
            .doc(productId);

        await productRef.update({
          'stockCount': FieldValue.increment(1),
        }).catchError((e) {
          debugPrint("Safe ignore: Stock restore failed: $e");
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final errorMsg = e.toString().contains('converted Future')
                ? "Update failed (Web Engine). Please try again."
                : "Error: $e";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        });
      }
    } finally {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isRemovingTool = false);
        });
      }
    }
  }
}
