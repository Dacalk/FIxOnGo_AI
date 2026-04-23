import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../theme_provider.dart';
import '../components/osm_map_widget.dart';
import '../components/primary_button.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import 'dart:async';

class MechanicNavToUserScreen extends StatefulWidget {
  const MechanicNavToUserScreen({super.key});

  @override
  State<MechanicNavToUserScreen> createState() =>
      _MechanicNavToUserScreenState();
}

class _MechanicNavToUserScreenState extends State<MechanicNavToUserScreen> {
  String? _requestId;
  Map<String, dynamic>? _requestData;
  StreamSubscription? _requestSub;

  LatLng? _mechanicLatLng;
  LatLng? _userLatLng;
  List<LatLng> _routePoints = [];
  String _eta = "Fetching...";
  bool _isArrived = false;
  bool _isProcessing = false;
  String _paymentStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _requestSub?.cancel();
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

    // Fetch initial location immediately for ETA calculation
    try {
      final pos = await LocationService.instance.getCurrentLatLng();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _mechanicLatLng = pos;
          });
          _updateRoute();
        }
      });
    } catch (e) {
      debugPrint("Initial location error: $e");
    }

    // Start local location tracking for the mechanic
    LocationService.instance.getPositionStream(distanceFilter: 5).listen((pos) {
      if (mounted) {
        setState(() {
          _mechanicLatLng = LatLng(pos.latitude, pos.longitude);
        });
        _updateRoute();
        _updateMechanicLocationInFirestore();
      }
    });
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
        setState(() {
          _requestData = data;
          final uLoc = data['userLocation'] as Map<String, dynamic>;
          _userLatLng = LatLng(uLoc['lat'], uLoc['lng']);
          _isArrived = data['status'] == 'arrived';
          _paymentStatus = data['paymentStatus'] ?? 'pending';
        });
        _updateRoute();
      }
    });
  }

  Future<void> _updateMechanicLocationInFirestore() async {
    if (_requestId == null || _mechanicLatLng == null) return;
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(_requestId)
        .update({
      'mechanicLocation': {
        'lat': _mechanicLatLng!.latitude,
        'lng': _mechanicLatLng!.longitude,
      },
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateRoute() async {
    if (_mechanicLatLng == null || _userLatLng == null) return;

    try {
      final route = await MapService.instance.getDirections(
        _mechanicLatLng!,
        _userLatLng!,
      );
      if (mounted) {
        setState(() {
          _routePoints = route.points;
          _eta = route.summary;
        });
      }
    } catch (e) {
      debugPrint("Route error: $e");
    }
  }

  Future<void> _handleArrived() async {
    if (_requestId == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(_requestId)
        .update({'status': 'arrived'});

    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _handleComplete() async {
    if (_requestId == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(_requestId)
        .update({'status': 'completed'});

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pushReplacementNamed(
        context,
        '/payment-successful',
        arguments: {'role': 'mechanic'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final userName = _requestData?['userName'] ?? 'Client';
    final serviceType = _requestData?['serviceType'] ?? 'Emergency Service';

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Map
          if (_userLatLng != null)
            OsmMapWidget(
              center: _mechanicLatLng ?? _userLatLng!,
              zoom: 15,
              polylinePoints: _routePoints,
              markers: [
                if (_mechanicLatLng != null)
                  Marker(
                    point: _mechanicLatLng!,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.navigation,
                        color: Colors.blue, size: 40),
                  ),
                Marker(
                  point: _userLatLng!,
                  width: 50,
                  height: 50,
                  child: const Icon(Icons.location_on,
                      color: Colors.red, size: 40),
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          // 2. Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. User Detail Card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.1),
                            child: const Icon(Icons.person,
                                color: AppColors.primaryBlue, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  serviceType,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _eta,
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: _isArrived
                            ? (_paymentStatus == 'paid'
                                ? 'COMPLETE JOB'
                                : 'AWAITING PAYMENT')
                            : 'I HAVE ARRIVED',
                        isLoading: _isProcessing,
                        onPressed: (_isArrived && _paymentStatus == 'paid')
                            ? _handleComplete
                            : (!_isArrived ? _handleArrived : null),
                        color: (_isArrived && _paymentStatus != 'paid')
                            ? Colors.grey
                            : AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _paymentStatus == 'paid'
                                ? 'Payment: Completed'
                                : 'Payment: Awaiting User Payment',
                            style: TextStyle(
                                color: _paymentStatus == 'paid'
                                    ? Colors.green[600]
                                    : Colors.orange[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
