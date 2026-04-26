import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../theme_provider.dart';
import '../components/osm_map_widget.dart';

/// Shows the live delivery tracking map + status stepper for an active delivery.
/// Receives deliveryId as a route argument: Navigator.pushNamed(context, '/active-delivery', arguments: deliveryId)
class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  String? _deliveryId;
  Map<String, dynamic>? _data;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() => _deliveryId = args);
        _listenToDelivery(args);
      }
    });
  }

  void _listenToDelivery(String id) {
    FirebaseFirestore.instance
        .collection('deliveries')
        .doc(id)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        setState(() => _data = snap.data());
      }
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_deliveryId == null) return;
    setState(() => _isUpdating = true);
    try {
      final updateData = <String, dynamic>{'status': newStatus};
      if (newStatus == 'delivered') {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }
      await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(_deliveryId)
          .update(updateData);

      if (newStatus == 'delivered' && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black87;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;

    final status = _data?['status'] ?? 'accepted';
    final itemName = _data?['itemName'] ?? 'Item';
    final pickup = _data?['pickupAddress'] ?? 'Pickup location';
    final drop = _data?['dropAddress'] ?? 'Delivery location';
    final earnings = _data?['earnings'] ?? 0;
    final sourceRole = _data?['sourceRole'] ?? 'seller';

    String nextStatusLabel = '';
    String nextStatus = '';
    IconData nextIcon = Icons.check;
    Color nextColor = Colors.green;

    if (status == 'accepted') {
      nextStatusLabel = 'Mark as Picked Up';
      nextStatus = 'en_route';
      nextIcon = Icons.local_shipping;
      nextColor = Colors.blue;
    } else if (status == 'en_route') {
      nextStatusLabel = 'Mark as Delivered';
      nextStatus = 'delivered';
      nextIcon = Icons.check_circle;
      nextColor = Colors.green;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Active Delivery',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: titleColor, fontSize: 17),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18, color: dark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _data == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item info card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: dark
                            ? [
                                const Color(0xFF1E3A5F),
                                const Color(0xFF15294A)
                              ]
                            : [
                                const Color(0xFFE3F2FD),
                                const Color(0xFFBBDEFB)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_shipping,
                              color: Colors.blue, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: dark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                sourceRole == 'seller'
                                    ? '🛒 From Seller'
                                    : '🔧 From Mechanic',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                              ),
                              Text(
                                'Earnings: Rs. $earnings',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Route map
                  const SizedBox(height: 24),
                  Text('Live Map',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 220,
                      child: () {
                        // Try to get pickup / drop coordinates from doc
                        final driverLoc =
                            _data?['driverLocation'] as Map<String, dynamic>?;
                        final pickupLat =
                            (_data?['pickupLat'] as num?)?.toDouble();
                        final pickupLng =
                            (_data?['pickupLng'] as num?)?.toDouble();
                        final dropLat =
                            (_data?['dropLat'] as num?)?.toDouble();
                        final dropLng =
                            (_data?['dropLng'] as num?)?.toDouble();

                        final driverPos = driverLoc != null
                            ? LatLng(
                                (driverLoc['lat'] as num).toDouble(),
                                (driverLoc['lng'] as num).toDouble())
                            : null;

                        final pickupPos = (pickupLat != null && pickupLng != null)
                            ? LatLng(pickupLat, pickupLng)
                            : null;
                        final dropPos = (dropLat != null && dropLng != null)
                            ? LatLng(dropLat, dropLng)
                            : null;

                        // Default to Colombo if no coords available
                        final center = driverPos ??
                            pickupPos ??
                            dropPos ??
                            const LatLng(6.9271, 79.8612);

                        final markers = <Marker>[
                          if (driverPos != null)
                            Marker(
                              point: driverPos,
                              width: 44,
                              height: 44,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.delivery_dining,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          if (pickupPos != null)
                            Marker(
                              point: pickupPos,
                              width: 44,
                              height: 44,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.store,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          if (dropPos != null)
                            Marker(
                              point: dropPos,
                              width: 44,
                              height: 44,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.location_on,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                        ];

                        final polyline = [
                          if (pickupPos != null) pickupPos,
                          if (driverPos != null) driverPos,
                          if (dropPos != null) dropPos,
                        ];

                        return OsmMapWidget(
                          center: center,
                          zoom: 13,
                          markers: markers,
                          polylinePoints:
                              polyline.length >= 2 ? polyline : null,
                          polylineColor: Colors.blue,
                          showLocateButton: false,
                        );
                      }(),
                    ),
                  ),

                  // Route info
                  Text('Route',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: dark ? Colors.grey[800]! : Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _routeRow(Icons.circle, Colors.green, 'Pickup', pickup,
                            subColor, titleColor),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            children: List.generate(
                                3,
                                (_) => Container(
                                      width: 2,
                                      height: 8,
                                      margin:
                                          const EdgeInsets.symmetric(vertical: 2),
                                      color: Colors.grey[400],
                                    )),
                          ),
                        ),
                        _routeRow(Icons.location_on, Colors.red, 'Drop-off', drop,
                            subColor, titleColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status stepper
                  Text('Delivery Status',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: titleColor)),
                  const SizedBox(height: 12),
                  _stepRow('Job Accepted', true, dark),
                  _stepRow('Picked Up / En Route', status == 'en_route' || status == 'delivered', dark),
                  _stepRow('Delivered ✓', status == 'delivered', dark),
                  const SizedBox(height: 32),

                  // Action button
                  if (nextStatus.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isUpdating ? null : () => _updateStatus(nextStatus),
                        icon: _isUpdating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Icon(nextIcon, size: 20),
                        label: Text(nextStatusLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nextColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String label, String address,
      Color subColor, Color titleColor) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: subColor,
                      fontWeight: FontWeight.w500)),
              Text(address,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepRow(String label, bool done, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? Colors.green
                  : (dark ? Colors.grey[800] : Colors.grey[200]),
            ),
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
              color: done
                  ? Colors.green
                  : (dark ? Colors.grey[500] : Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}
