import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/provider_service.dart';
import '../theme_provider.dart';

/// Checkout screen — review tool delivery order, select payment method,
/// and confirm the order. Shows item details, delivery address,
/// payment options, and order summary.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPayment = 0; // 0 = Credit/Debit, 1 = Cash on Delivery
  bool _isProcessing = false;
  Map<String, dynamic>? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;
    final labelColor = dark ? Colors.grey[500]! : Colors.grey[600]!;
    final btnColor = dark ? AppColors.brandYellow : AppColors.primaryBlue;
    final btnTextColor = dark ? Colors.black : Colors.white;

    final itemName = _args?['itemName'] ?? 'Item';
    final num priceVal = (_args?['itemPrice'] is num) ? _args!['itemPrice'] : (double.tryParse(_args?['itemPrice']?.toString() ?? '') ?? 0.0);
    final double itemPrice = priceVal.toDouble();
    final double deliveryFee = 350.0;
    final double totalAmount = itemPrice + deliveryFee;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Checkout',
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Tool Delivery Info ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        // Truck icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: dark
                                ? const Color(0xFF1E3350)
                                : const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_shipping_outlined,
                            size: 22,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tool Delivery',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Order ID: #RK-08278',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Item Row ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Qty: 1',
                              style: TextStyle(fontSize: 12, color: subColor),
                            ),
                          ],
                        ),
                        Text(
                          'Rs. ${itemPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── DELIVERY ADDRESS ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DELIVERY ADDRESS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: labelColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 20, color: Colors.red[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current GPS Location',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Main Street, Badulla Town, Sri Lanka',
                              style: TextStyle(fontSize: 12, color: subColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.primaryBlue.withAlpha(51)
                          : AppColors.primaryBlue.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 14,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'High Accuracy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── PAYMENT METHOD ──
                  Text(
                    'PAYMENT METHOD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: labelColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Credit/Debit Card
                  _paymentOption(
                    icon: Icons.credit_card,
                    title: 'Credit/Debit Card',
                    subtitle: '•••• •••• •••• 4242',
                    index: 0,
                    dark: dark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    titleColor: titleColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 10),

                  // Cash on Delivery
                  _paymentOption(
                    icon: Icons.money,
                    title: 'Cash on Delivery',
                    subtitle: 'Pay when item arrives',
                    index: 1,
                    dark: dark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    titleColor: titleColor,
                    subColor: subColor,
                  ),

                  const SizedBox(height: 24),

                  // ── Order Summary ──
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _summaryRow('Subtotal', 'Rs. ${itemPrice.toStringAsFixed(0)}', labelColor, titleColor),
                  const SizedBox(height: 10),
                  _summaryRow(
                    'Delivery Fee',
                    'Rs. ${deliveryFee.toStringAsFixed(0)}',
                    labelColor,
                    titleColor,
                  ),
                  const SizedBox(height: 14),
                  Divider(color: borderColor),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        'Rs. ${totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Pay & Confirm Order Button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: btnTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pay & Confirm Order',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_args == null) return;
    final productId = _args!['productId'];
    final name = _args!['itemName'];
    final num priceVal = (_args!['itemPrice'] is num) ? _args!['itemPrice'] : (double.tryParse(_args!['itemPrice']?.toString() ?? '') ?? 0.0);
    final itemPrice = priceVal.toDouble();
    final _mechanicId = _args!['mechanicId'];
    final _mechanicName = _args!['mechanicName'];

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);
    String? createdRequestId;

    try {
      LatLng userLoc;
      try {
        userLoc = await LocationService.instance.getCurrentLatLng();
      } catch (e) {
        userLoc = LatLng(6.9271, 79.8612);
      }

      final driver = await ProviderService.instance.findNearestAvailableDriver(userLoc);
      final deliveryFee = 350.0;
      final totalAmount = itemPrice + deliveryFee;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final productRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_mechanicId)
            .collection('products')
            .doc(productId);

        final pSnap = await transaction.get(productRef);
        if (!pSnap.exists) throw Exception("Product no longer available.");

        final currentStock = pSnap.data()?['stockCount'] ?? 0;
        if (currentStock <= 0) throw Exception("Out of stock.");

        transaction.update(productRef, {'stockCount': currentStock - 1});

        final requestRef = FirebaseFirestore.instance.collection('requests').doc();
        createdRequestId = requestRef.id;

        transaction.set(requestRef, {
          'targetRole': 'seller',
          'assignedProviderId': _mechanicId,
          'sellerId': _mechanicId,
          'sellerName': _mechanicName ?? 'Seller',
          'userId': user.uid,
          'userName': user.displayName ?? 'User',
          'type': 'shop_order',
          'status': 'paid',
          'productName': name,
          'productId': productId,
          'itemPrice': itemPrice,
          'deliveryFee': deliveryFee,
          'totalPrice': totalAmount,
          'createdAt': FieldValue.serverTimestamp(),
          'userLocation': {'lat': userLoc.latitude, 'lng': userLoc.longitude},
        });

        final deliveryRef = FirebaseFirestore.instance.collection('deliveries').doc();
        transaction.set(deliveryRef, {
          'sourceRole': 'seller',
          'targetRole': 'delivery',
          'senderId': _mechanicId,
          'senderName': _mechanicName ?? 'Seller',
          'assignedProviderId': driver?['uid'],
          'driverId': driver?['uid'],
          'driverName': driver?['name'],
          'itemName': name,
          'itemCategory': pSnap.data()?['category'] ?? 'Tools',
          'itemPrice': itemPrice,
          'pickupAddress': 'Seller Location',
          'dropAddress': 'Your Location',
          'pickupLat': 6.9271,
          'pickupLng': 79.8612,
          'dropLat': userLoc.latitude,
          'dropLng': userLoc.longitude,
          'status': 'pending',
          'earnings': deliveryFee,
          'orderId': createdRequestId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final paymentRef = FirebaseFirestore.instance.collection('payments').doc();
        transaction.set(paymentRef, {
          'userId': user.uid,
          'userName': user.displayName ?? 'User',
          'sellerId': _mechanicId,
          'providerId': _mechanicId,
          'sellerName': _mechanicName ?? 'Seller',
          'driverId': driver?['uid'],
          'amount': totalAmount,
          'itemPrice': itemPrice,
          'deliveryFee': deliveryFee,
          'itemName': name,
          'currency': 'LKR',
          'status': 'completed',
          'type': 'shop_order',
          'method': _selectedPayment == 0 ? 'Card' : 'Cash on Delivery',
          'requestId': createdRequestId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        if (createdRequestId != null) {
          Navigator.pushReplacementNamed(context, '/order-tracking', arguments: createdRequestId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _paymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
    required bool dark,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subColor,
  }) {
    final isSelected = _selectedPayment == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E3350) : const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : (dark ? Colors.grey[600]! : Colors.grey[400]!),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
