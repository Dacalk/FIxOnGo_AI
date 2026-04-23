import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme_provider.dart';
import '../components/osm_map_widget.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import 'dart:async';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLatLng;
  LatLng? _mechanicLatLng;
  List<LatLng> _routePoints = [];
  String _eta = 'Calculating...';
  String? _requestId;
  Map<String, dynamic>? _requestData;
  StreamSubscription? _requestSub;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() => _requestId = args);
        _listenToRequest();
      }
    });

    try {
      final userPos = await LocationService.instance.getCurrentLatLng();
      if (mounted) setState(() => _userLatLng = userPos);
    } catch (_) {}
  }

  void _listenToRequest() {
    if (_requestId == null) return;
    _requestSub = FirebaseFirestore.instance
        .collection('requests')
        .doc(_requestId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        final data = snap.data()!;
        setState(() => _requestData = data);

        final mLoc = data['mechanicLocation'] as Map<String, dynamic>?;
        if (mLoc != null) {
          final newPos = LatLng(mLoc['lat'], mLoc['lng']);
          setState(() => _mechanicLatLng = newPos);
          _updateRoute();
        }

        // If status completed, navigate to success or show arrived notification
        if (data['status'] == 'completed') {
          Navigator.pushReplacementNamed(
            context,
            '/payment-successful',
            arguments: {
              'role': 'user',
              'requestId': _requestId,
              'mechanicId': data['mechanicId'],
              'mechanicName': data['mechanicName'],
            },
          );
        }
      }
    });
  }

  Future<void> _updateRoute() async {
    if (_userLatLng == null || _mechanicLatLng == null) return;

    try {
      final route = await MapService.instance
          .getDirections(_mechanicLatLng!, _userLatLng!);
      if (mounted) {
        setState(() {
          _routePoints = route.points;
          _eta = route.summary;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[50]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;

    final mechanicName = _requestData?['mechanicName'] ?? 'Your Mechanic';
    final status = _requestData?['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Map Area ──
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                OsmMapWidget(
                  center: _userLatLng ?? const LatLng(6.9271, 79.8612),
                  zoom: 14,
                  mapController: _mapController,
                  showLocateButton: false,
                  polylinePoints: _routePoints.isNotEmpty ? _routePoints : null,
                  markers: _buildMarkers(dark),
                ),

                // Top Badge
                if (_mechanicLatLng != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 56,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10),
                          ],
                        ),
                        child: Text(
                          '${mechanicName.toUpperCase()} IS ${status.toUpperCase()} • $_eta',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
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
                    child: CircleAvatar(
                      backgroundColor:
                          dark ? AppColors.darkSurface : Colors.white,
                      child: Icon(Icons.close,
                          color: dark ? Colors.white : Colors.black, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Info ──
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5)),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          status == 'arrived' ? 'Arrived!' : 'Heading to you',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: titleColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _eta,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Driver Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.1),
                            child: const Icon(Icons.person,
                                color: AppColors.primaryBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mechanicName,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: titleColor),
                                ),
                                Text(
                                  'Top Rated Mechanic',
                                  style:
                                      TextStyle(fontSize: 13, color: subColor),
                                ),
                              ],
                            ),
                          ),
                          _actionIcon(Icons.phone, dark),
                          const SizedBox(width: 10),
                          _actionIcon(Icons.chat_bubble_outline, dark),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Timeline
                    _timelineStep('Request Accepted',
                        'The mechanic is notified', true, false, dark),
                    _timelineStep('On the way', 'Live tracking enabled',
                        status != 'pending', false, dark),
                    _timelineStep('Arrived', 'Ready to start the job',
                        status == 'arrived', true, dark),
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
    return [
      if (_userLatLng != null)
        Marker(
          point: _userLatLng!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      if (_mechanicLatLng != null)
        Marker(
          point: _mechanicLatLng!,
          width: 50,
          height: 50,
          child: const Icon(Icons.local_shipping,
              color: AppColors.primaryBlue, size: 40),
        ),
    ];
  }

  Widget _actionIcon(IconData icon, bool dark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: dark ? Colors.grey[800] : Colors.white,
        shape: BoxShape.circle,
        border:
            Border.all(color: dark ? Colors.transparent : Colors.grey[200]!),
      ),
      child: Icon(icon, size: 20, color: AppColors.primaryBlue),
    );
  }

  Widget _timelineStep(
      String title, String sub, bool done, bool last, bool dark) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
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
            if (!last)
              Container(
                  width: 2,
                  height: 40,
                  color: done ? Colors.green : Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: done ? Colors.green : Colors.grey)),
              Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
