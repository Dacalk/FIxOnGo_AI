import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../theme_provider.dart';
import '../../../components/osm_map_widget.dart';
import '../../../components/primary_button.dart';
import '../../../services/location_service.dart';
import '../../../services/map_service.dart';
import '../../../services/provider_service.dart';
import 'dart:async';

class TowNavToUserScreen extends StatefulWidget {
  const TowNavToUserScreen({super.key});

  @override
  State<TowNavToUserScreen> createState() => _TowNavToUserScreenState();
}

class _TowNavToUserScreenState extends State<TowNavToUserScreen> {
  String? _requestId;
  Map<String, dynamic>? _requestData;
  StreamSubscription? _requestSub;

  LatLng? _driverLatLng;
  LatLng? _userLatLng;
  LatLng? _destinationLatLng;
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
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _requestId = args is String ? args : null);
        if (_requestId != null) _listenToRequest();
      });
    });

    // Tracking
    LocationService.instance.getPositionStream(distanceFilter: 5).listen((pos) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _driverLatLng = LatLng(pos.latitude, pos.longitude);
          });
          _updateRoute();
          _updateDriverLocationInFirestore();
        }
      });
    });
  }

  void _listenToRequest() {
    if (_requestId == null) return;
    final towUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('[TowNavToUser] _listenToRequest: tow UID=$towUid requestId=$_requestId');
    _requestSub = FirebaseFirestore.instance
        .collection('requests')
        .doc(_requestId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        final data = snap.data()!;
        final status = data['status'];
        final assignedId = data['assignedProviderId'];
        debugPrint('[TowNavToUser] request update: '
            'status=$status assignedProviderId=$assignedId tow UID=$towUid result count=1');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _requestData = data;
              final uLoc = data['userLocation'] as Map<String, dynamic>?;
              if (uLoc != null) {
                _userLatLng = LatLng(uLoc['lat'], uLoc['lng']);
              }
              final dLoc = data['destination'] as Map<String, dynamic>?;
              if (dLoc != null && dLoc['lat'] != 0) {
                _destinationLatLng = LatLng((dLoc['lat'] as num).toDouble(), (dLoc['lng'] as num).toDouble());
              }
              _isArrived = data['status'] == 'arrived';
              _paymentStatus = data['paymentStatus'] ?? 'pending';
            });
            _updateRoute();
          }
        });
      }
    });
  }

  Future<void> _updateDriverLocationInFirestore() async {
    if (_requestId == null || _driverLatLng == null) return;
    // For tow roles, we update the tow role location
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(_requestId)
        .update({
      'mechanicLocation': {
        'lat': _driverLatLng!.latitude,
        'lng': _driverLatLng!.longitude,
      },
    });
  }

  Future<void> _updateRoute() async {
    if (_driverLatLng == null || _userLatLng == null) return;
    try {
      final route = await MapService.instance.getDirections(_driverLatLng!, _userLatLng!);
      if (mounted) {
        setState(() {
          _routePoints = route.points;
          _eta = route.summary;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleArrived() async {
    if (_requestId == null) return;
    final towUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('[TowNavToUser] _handleArrived: tow UID=$towUid requestId=$_requestId');
    setState(() => _isProcessing = true);
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(_requestId)
        .update({'status': 'arrived'});
    setState(() => _isProcessing = false);
  }

  Future<void> _handleComplete() async {
    if (_requestId == null) return;
    final towUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('[TowNavToUser] _handleComplete: tow UID=$towUid requestId=$_requestId status=completed');
    setState(() => _isProcessing = true);

    // 1. Create payment record
    await FirebaseFirestore.instance.collection('payments').add({
      'requestId': _requestId,
      'userId': _requestData?['userId'],
      'mechanicId': _requestData?['mechanicId'],
      'amount': _requestData?['basePrice'] ?? 2000,
      'type': 'towing',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Mark request completed
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(_requestId)
        .update({'status': 'completed'});

    // 3. Mark tow driver available again for next jobs
    await ProviderService.instance.setAvailable('tow');
    debugPrint('[TowNavToUser] _handleComplete: tow UID=$towUid marked available again');

    setState(() => _isProcessing = false);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/payment-successful', arguments: {'role': 'tow'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final userName = _requestData?['userName'] ?? 'User';
    
    return Scaffold(
      body: Stack(
        children: [
          if (_userLatLng != null)
            OsmMapWidget(
              center: _driverLatLng ?? _userLatLng!,
              zoom: 15,
              polylinePoints: _routePoints,
              markers: [
                if (_driverLatLng != null)
                  Marker(point: _driverLatLng!, width: 40, height: 40, child: const Icon(Icons.local_shipping, color: Colors.blue, size: 30)),
                if (_userLatLng != null)
                  Marker(point: _userLatLng!, width: 40, height: 40, child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 30)),
                if (_destinationLatLng != null)
                  Marker(point: _destinationLatLng!, width: 40, height: 40, child: const Icon(Icons.flag, color: Colors.green, size: 30)),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: AppColors.emergencyRed.withAlpha(25), child: const Icon(Icons.person, color: AppColors.emergencyRed)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(_requestData?['serviceType'] ?? 'Towing', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          ],
                        ),
                      ),
                      Text(_eta, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: _isArrived ? (_paymentStatus == 'paid' ? 'COMPLETE TOW' : 'WAITING FOR PAYMENT') : 'I HAVE ARRIVED',
                    isLoading: _isProcessing,
                    onPressed: (_isArrived && _paymentStatus == 'paid') ? _handleComplete : (!_isArrived ? _handleArrived : null),
                    color: (_isArrived && _paymentStatus != 'paid') ? Colors.grey : AppColors.emergencyRed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
