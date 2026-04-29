import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme_provider.dart';
import '../../../components/osm_map_widget.dart';
import '../../../services/location_service.dart';
import '../../../services/provider_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'towing_status_screen.dart';

/// "Searching for nearby tow trucks" screen.
/// Mirrors the SearchingMechanicsScreen but queries tow providers instead.
class SearchingTowsScreen extends StatefulWidget {
  const SearchingTowsScreen({super.key});

  @override
  State<SearchingTowsScreen> createState() => _SearchingTowsScreenState();
}

class _SearchingTowsScreenState extends State<SearchingTowsScreen> {
  final MapController _mapController = MapController();

  LatLng? _userLatLng;

  // Real data
  List<Map<String, dynamic>> _towProviders = [];
  Map<String, dynamic>? _selectedProvider;
  StreamSubscription? _providerSub;
  StreamSubscription? _requestSub;
  String? _currentRequestId;
  bool _isRequesting = false;
  bool _isNavigating = false;
  bool _mapReady = false;
  String? _userName;

  // Booking details passed from TowingBookingScreen
  Map<String, dynamic> _bookingArgs = {};

  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _listenToTowProviders();
    _initUserData();
    // Delay map render to avoid Flutter Web assertion loop
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _mapReady = true);
    });
  }

  Future<void> _initUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get booking args
    Future.microtask(() {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        if (mounted) {
          setState(() {
            _bookingArgs = args;
          });
        }
      }
    });

    // Fetch user name
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _userName = doc.data()?['fullName'] ?? user.displayName ?? 'User';
      });
    }
  }

  void _listenToTowProviders() {
    _providerSub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snap) {
      final list = <Map<String, dynamic>>[];
      debugPrint('[SearchingTows] tow provider snapshot docs=${snap.docs.length}');
      for (var doc in snap.docs) {
        final data = doc.data();
        final t = data['roles']?['tow'] as Map<String, dynamic>?;
        if (t != null) {
          final isActive = t['isActive'] ?? true;
          if (!isActive) continue;

          final isOnline = t['isOnline'] as bool? ?? true;
          final isAvailable = t['isAvailable'] as bool? ?? true;
          if (!isOnline || !isAvailable) {
            debugPrint('[SearchingTows] Skipping tow ${doc.id} isOnline=$isOnline isAvailable=$isAvailable');
            continue;
          }

          final loc = t['location'] as Map<String, dynamic>?;
          if (loc != null) {
            list.add({
              'id': doc.id,
              'name': t['fullName'] ?? 'Tow Driver',
              'truckModel': t['truckModel'] ?? 'Tow Truck',
              'plate': t['plate'] ?? '',
              'towingCapacity': t['towingCapacity'] ?? '',
              'rating': t['rating'] ?? 4.5,
              'reviews': t['reviews'] ?? 0,
              'lat': loc['lat'],
              'lng': loc['lng'],
              'lastSeen': t['lastSeen'],
              'photoUrl': data['photoUrl'],
            });
          } else {
            debugPrint('[SearchingTows] Tow ${doc.id} has no location — skipping');
          }
        }
      }

      // Sort by lastSeen descending
      list.sort((a, b) {
        final aTime = a['lastSeen'] as Timestamp?;
        final bTime = b['lastSeen'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        _uiUpdateTimer?.cancel();
        _uiUpdateTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _towProviders = list;
              if (_selectedProvider == null && list.isNotEmpty) {
                _selectedProvider = list.first;
              }
            });
          }
        });
      }
    });
  }

  Future<void> _sendRequest() async {
    if (_selectedProvider == null || _userLatLng == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final towUid = _selectedProvider!['id'] as String;
    debugPrint('[SearchingTows] _sendRequest '
        'userId=${user.uid} '
        'tow UID=$towUid '
        'assignedProviderId=$towUid');

    if (mounted) {
      setState(() => _isRequesting = true);
    }

    try {
      // Build request data using ProviderService
      final pickupCoords = _bookingArgs['pickupCoords'] as Map<String, double>?;
      final destCoords = _bookingArgs['destinationCoords'] as Map<String, double>?;

      _currentRequestId = await ProviderService.instance.createTowRequest(
        towProviderUid: towUid,
        towProviderName: _selectedProvider!['name'],
        userName: _userName ?? user.displayName ?? 'User',
        userPhotoUrl: user.photoURL,
        userId: user.uid,
        userLocation: pickupCoords ?? {
          'lat': _userLatLng!.latitude,
          'lng': _userLatLng!.longitude,
        },
        dropoffLocation: destCoords,
        dropoffAddress: _bookingArgs['destinationAddress'] as String?,
        basePrice: (_bookingArgs['basePrice'] as num?)?.toInt() ?? 2500,
      );

      // Also update with extra booking details
      if (_currentRequestId != null) {
        final Map<String, dynamic> extra = {};
        if (_bookingArgs['serviceType'] != null) {
          extra['serviceType'] = _bookingArgs['serviceType'];
        }
        if (_bookingArgs['vehicleDetails'] != null) {
          extra['vehicleDetails'] = _bookingArgs['vehicleDetails'];
        }
        if (_bookingArgs['notes'] != null) {
          extra['notes'] = _bookingArgs['notes'];
        }
        if (_bookingArgs['estimatedDistance'] != null) {
          extra['estimatedDistance'] = _bookingArgs['estimatedDistance'];
        }
        if (_bookingArgs['userAddress'] != null) {
          extra['userAddress'] = _bookingArgs['userAddress'];
        }
        if (_bookingArgs['destination'] != null) {
          extra['destination'] = _bookingArgs['destination'];
        }

        if (extra.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('requests')
              .doc(_currentRequestId)
              .update(extra);
        }
      }
    } catch (e) {
      debugPrint('[SearchingTows] Failed to create request: $e');
      if (mounted) {
        setState(() => _isRequesting = false);
      }
      return;
    }

    debugPrint('[SearchingTows] Request created '
        'requestId=$_currentRequestId '
        'assignedProviderId=$towUid tow UID=$towUid');

    // Listen for acceptance
    final ref = FirebaseFirestore.instance.collection('requests').doc(_currentRequestId);
    _requestSub = ref.snapshots().listen((snap) {
      if (snap.exists) {
        final status = snap.data()?['status'];
        final assignedId = snap.data()?['assignedProviderId'];
        debugPrint('[SearchingTows] status listener: '
            'status=$status assignedProviderId=$assignedId tow UID=$towUid result count=1');
        if (status == 'accepted') {
          if (_isNavigating) return;
          _isNavigating = true;
          _requestSub?.cancel();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TowingStatusScreen(requestId: _currentRequestId),
              ),
            );
          }
        } else if (status == 'rejected') {
          debugPrint('[SearchingTows] Request rejected by tow UID=$towUid');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Request rejected by tow driver.")),
            );
            setState(() {
              _isRequesting = false;
              _currentRequestId = null;
            });
            _requestSub?.cancel();
          }
        }
      }
    });
  }

  Future<void> _fetchLocation() async {
    try {
      final latLng = await LocationService.instance.getCurrentLatLng();
      if (!mounted) return;
      setState(() => _userLatLng = latLng);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          try {
            _mapController.move(latLng, 14);
          } catch (_) {}
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _userLatLng = const LatLng(6.9271, 79.8612));
    }
  }

  List<Marker> _buildMarkers(bool dark) {
    final markers = <Marker>[];

    // User marker
    if (_userLatLng != null) {
      markers.add(Marker(
        point: _userLatLng!,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.emergencyRed,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
      ));
    }

    // Tow provider markers
    for (final tow in _towProviders) {
      final isSelected = _selectedProvider?['id'] == tow['id'];
      markers.add(
        Marker(
          point: LatLng(tow['lat'], tow['lng']),
          width: isSelected ? 50 : 40,
          height: isSelected ? 50 : 40,
          child: GestureDetector(
            onTap: () => setState(() => _selectedProvider = tow),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.emergencyRed : Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected
                    ? [const BoxShadow(color: Colors.black26, blurRadius: 8)]
                    : null,
              ),
              child: Icon(
                Icons.local_shipping,
                color: isSelected ? Colors.white : Colors.white,
                size: isSelected ? 24 : 18,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  void dispose() {
    _providerSub?.cancel();
    _requestSub?.cancel();
    _uiUpdateTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final sheetBg = dark ? AppColors.darkBackground : Colors.white;
    final center = _userLatLng ?? const LatLng(6.9271, 79.8612);

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen Map ──
          Positioned.fill(
            child: _mapReady
                ? OsmMapWidget(
                    center: center,
                    zoom: 14,
                    mapController: _mapController,
                    markers: _buildMarkers(dark),
                    showLocateButton: false,
                  )
                : Container(
                    color: dark ? AppColors.darkBackground : const Color(0xFFE8E8E8),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
          ),

          // ── Back Button ──
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
                      color: Colors.black.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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

          // ── Cancel Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkSurface : const Color(0xFF2C3E50),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Sheet (Tow Provider Selection) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(38),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: dark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Tow Truck',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: dark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (_isRequesting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.emergencyRed),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _filterChip('Recommended', true, dark),
                          _filterChip('Nearest', false, dark),
                          _filterChip('Top Rated', false, dark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tow Provider List
                    if (_towProviders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                                color: AppColors.emergencyRed),
                            const SizedBox(height: 12),
                            Text(
                              'Finding nearby tow trucks...',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _towProviders.length,
                          itemBuilder: (context, index) {
                            final tow = _towProviders[index];
                            final isSelected =
                                _selectedProvider?['id'] == tow['id'];
                            return _towCard(tow, isSelected, dark);
                          },
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Action Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ElevatedButton(
                        onPressed: (_selectedProvider == null || _isRequesting)
                            ? null
                            : _sendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emergencyRed,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isRequesting
                              ? 'Requesting...'
                              : (_selectedProvider != null
                                  ? 'Request This Tow Truck'
                                  : 'Select a Tow Truck'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, bool dark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.emergencyRed
            : (dark ? const Color(0xFF1E3350) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active
              ? Colors.white
              : (dark ? Colors.grey[400] : Colors.grey[600]),
          fontSize: 13,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _towCard(Map<String, dynamic> tow, bool selected, bool dark) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedProvider = tow);
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            try {
              _mapController.move(LatLng(tow['lat'], tow['lng']), 14);
            } catch (_) {}
          }
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.81,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E3350) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.emergencyRed
                : (dark ? Colors.grey[800]! : Colors.grey[200]!),
            width: 2,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.emergencyRed.withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Profile Pic / Truck Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: dark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image: (tow['photoUrl'] != null && tow['photoUrl'].toString().isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(tow['photoUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (tow['photoUrl'] == null || tow['photoUrl'].toString().isEmpty)
                  ? const Icon(Icons.local_shipping, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tow['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: dark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tow['plate'].toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRed.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tow['plate'],
                            style: const TextStyle(
                              color: AppColors.emergencyRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    tow['truckModel'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppColors.brandYellow, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${tow['rating']} (${tow['reviews']})',
                        style: TextStyle(
                          fontSize: 12,
                          color: dark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (tow['towingCapacity'].toString().isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.straighten,
                                color: Colors.grey[400], size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${tow['towingCapacity']} Tons',
                              style: TextStyle(
                                fontSize: 12,
                                color: dark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
