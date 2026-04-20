import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme_provider.dart';
import '../components/osm_map_widget.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';

/// Order Tracking screen — shows real-time delivery status with a real map,
/// driver info, and order timeline (Confirmed → Picked Up → Delivered).
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLatLng;
  LatLng? _driverLatLng;
  List<LatLng> _routePoints = [];
  String _eta = '13 mins';

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    try {
      final userPos = await LocationService.instance.getCurrentLatLng();
      // Simulated driver position (coming from nearby)
      final driverPos = LatLng(
        userPos.latitude + 0.012,
        userPos.longitude - 0.006,
      );
      if (!mounted) return;
      setState(() {
        _userLatLng = userPos;
        _driverLatLng = driverPos;
      });

      // Fetch route from driver to user
      try {
        final route =
            await MapService.instance.getDirections(driverPos, userPos);
        if (!mounted) return;
        setState(() {
          _routePoints = route.points;
          _eta = '${(route.durationSeconds / 60).ceil()} mins';
        });
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userLatLng = const LatLng(6.9271, 79.8612);
        _driverLatLng = const LatLng(6.9391, 79.8552);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;
    final center = _userLatLng ?? const LatLng(6.9271, 79.8612);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Map Area ──
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                // Real map
                OsmMapWidget(
                  center: center,
                  zoom: 13,
                  mapController: _mapController,
                  showLocateButton: false,
                  polylinePoints: _routePoints.isNotEmpty ? _routePoints : null,
                  markers: _buildMarkers(dark),
                ),

                // "SUNIL IS ON THE WAY" badge
                if (_driverLatLng != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 56,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'SUNIL IS ON THE WAY  •  $_eta',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
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
              ],
            ),
          ),

          // ── Bottom Sheet ──
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
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
                    const SizedBox(height: 16),

                    // ── Order Picked Up header ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Picked Up',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: dark
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _eta,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sunil has collected your Battery & Fuel',
                      style: TextStyle(fontSize: 13, color: subColor),
                    ),

                    const SizedBox(height: 20),

                    // ── Driver Card ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryBlue,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sunil Perera',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'A - 5222',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '4.3',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: titleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Call & Chat
                          _actionCircle(Icons.phone, dark),
                          const SizedBox(width: 8),
                          _actionCircle(Icons.chat_bubble_outline, dark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Delivery Timeline ──
                    _timelineStep(
                      title: 'Order Confirmed',
                      subtitle: 'Your request was accepted at 10:45 AM',
                      isCompleted: true,
                      isLast: false,
                      dark: dark,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    _timelineStep(
                      title: 'Order Picked Up',
                      subtitle: 'Sunil is heading towards your location',
                      isCompleted: true,
                      isLast: false,
                      dark: dark,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),
                    _timelineStep(
                      title: 'Delivered',
                      subtitle: 'Estimated arrival in $_eta',
                      isCompleted: false,
                      isLast: true,
                      dark: dark,
                      titleColor: titleColor,
                      subColor: subColor,
                    ),

                    const SizedBox(height: 20),

                    // ── View Order Details ──
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'View Order Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(bool dark) {
    final markers = <Marker>[];

    // User destination marker
    if (_userLatLng != null) {
      markers.add(
        Marker(
          point: _userLatLng!,
          width: 36,
          height: 36,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 14),
          ),
        ),
      );
    }

    // Driver marker
    if (_driverLatLng != null) {
      markers.add(
        Marker(
          point: _driverLatLng!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _actionCircle(IconData icon, bool dark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: dark
            ? AppColors.darkSurface
            : AppColors.primaryBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: dark ? Colors.white70 : AppColors.primaryBlue,
      ),
    );
  }

  Widget _timelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLast,
    required bool dark,
    required Color titleColor,
    required Color subColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green
                    : (dark ? Colors.grey[700] : Colors.grey[300]),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.4)
                    : (dark ? Colors.grey[700] : Colors.grey[300]),
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? (dark ? Colors.green[400] : Colors.green[700])
                        : (dark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
