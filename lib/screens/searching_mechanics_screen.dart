import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme_provider.dart';
import '../components/osm_map_widget.dart';
import '../services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// "Searching for nearby mechanics" screen.
/// Shown after a user requests a service — displays a real OSM map with
/// mechanic pins and an animated bottom sheet indicating the search is
/// in progress.
class SearchingMechanicsScreen extends StatefulWidget {
  const SearchingMechanicsScreen({super.key});

  @override
  State<SearchingMechanicsScreen> createState() =>
      _SearchingMechanicsScreenState();
}

class _SearchingMechanicsScreenState extends State<SearchingMechanicsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  final MapController _mapController = MapController();

  LatLng? _userLatLng;

  // Real data
  List<Map<String, dynamic>> _mechanics = [];
  Map<String, dynamic>? _selectedMechanic;
  StreamSubscription? _mechanicSub;
  StreamSubscription? _requestSub;
  String? _currentRequestId;
  bool _isRequesting = false;
  bool _isNavigating = false; // Guard for double-navigation
  String? _serviceType;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _fetchLocation();
    _listenToMechanics();
    _initUserData();
  }

  Future<void> _initUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Try to get service info from arguments
    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _serviceType = args['serviceType'];
        });
      }
    });

    // Fetch user name from document if displayName is null
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

  void _listenToMechanics() {
    _mechanicSub = FirebaseFirestore.instance
        .collection('users')
        .where('roles.mechanic', isNotEqualTo: null)
        .snapshots()
        .listen((snap) {
      final list = <Map<String, dynamic>>[];
      for (var doc in snap.docs) {
        final data = doc.data();
        final m = data['roles']['mechanic'] as Map<String, dynamic>?;
        if (m != null) {
          final isActive = m['isActive'] ?? true;
          if (!isActive) continue;

          final loc = m['location'] as Map<String, dynamic>?;
          if (loc != null) {
            list.add({
              'id': doc.id,
              'name': m['fullName'] ?? 'Mechanic',
              'specialty': m['vehicleType'] ?? 'General Mechanic',
              'price': m['priceBase'] ?? 2500,
              'rating': m['rating'] ?? 4.5,
              'reviews': m['reviews'] ?? 0,
              'lat': loc['lat'],
              'lng': loc['lng'],
              'lastSeen': m['lastSeen'],
            });
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
        // Debounce UI update to once every 500ms to prevent engine crashes
        _uiUpdateTimer?.cancel();
        _uiUpdateTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _mechanics = list;
              if (_selectedMechanic == null && list.isNotEmpty) {
                _selectedMechanic = list.first;
              }
            });
          }
        });
      }
    });
  }

  Timer? _uiUpdateTimer;

  Future<void> _sendRequest() async {
    if (_selectedMechanic == null || _userLatLng == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isRequesting = true);

    final ref = await FirebaseFirestore.instance.collection('requests').add({
      'userId': user.uid,
      'userName': _userName ?? user.displayName ?? 'User',
      'userLocation': {
        'lat': _userLatLng!.latitude,
        'lng': _userLatLng!.longitude
      },
      'mechanicId': _selectedMechanic!['id'],
      'mechanicName': _selectedMechanic!['name'],
      'serviceType': _serviceType ?? 'General Service',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _currentRequestId = ref.id;

    // Listen for acceptance
    _requestSub = ref.snapshots().listen((snap) {
      if (snap.exists) {
        final status = snap.data()?['status'];
        if (status == 'accepted') {
          if (_isNavigating) return;
          _isNavigating = true;
          _requestSub?.cancel();

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/mechanic-accepted',
                arguments: _currentRequestId);
          }
        } else if (status == 'rejected') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Request rejected by mechanic.")),
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
      _mapController.move(latLng, 14);
    } catch (_) {
      // Fallback to Colombo
      if (!mounted) return;
      setState(() => _userLatLng = const LatLng(6.9271, 79.8612));
    }
  }

  List<Marker> _buildMarkers(bool dark) {
    final markers = <Marker>[];
    if (_userLatLng == null) return markers;

    // User marker
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

    // Mechanic pins
    for (final mech in _mechanics) {
      final mechLatLng = LatLng(mech['lat'], mech['lng']);
      final isSelected = _selectedMechanic?['id'] == mech['id'];

      markers.add(
        Marker(
          point: mechLatLng,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedMechanic = mech);
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandYellow
                    : (dark
                        ? const Color(0xFF1E3350)
                        : const Color(0xFF2C3E50)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : (dark ? Colors.grey[700]! : Colors.white),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.black26, blurRadius: 8)]
                    : null,
              ),
              child: Icon(
                Icons.person,
                color: isSelected ? Colors.black : Colors.white,
                size: isSelected ? 20 : 16,
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
    _dotController.dispose();
    _mechanicSub?.cancel();
    _requestSub?.cancel();
    _uiUpdateTimer?.cancel();
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
            child: OsmMapWidget(
              center: center,
              zoom: 14,
              mapController: _mapController,
              markers: _buildMarkers(dark),
              showLocateButton: false,
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
                      color: Colors.black.withValues(alpha: 0.1),
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

          // ── Bottom Sheet (Mechanic Selection) ──
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
                    color: Colors.black.withValues(alpha: 0.15),
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
                            'Select Mechanic',
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
                                    AppColors.primaryBlue),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filters (Simulated)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _filterChip('Recommended', true, dark),
                          _filterChip('Nearest', false, dark),
                          _filterChip('Lowest Price', false, dark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mechanic List
                    if (_mechanics.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                                color: AppColors.primaryBlue),
                            const SizedBox(height: 12),
                            Text(
                              'Finding professionals...',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 140, // Slightly more compact
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _mechanics.length,
                          itemBuilder: (context, index) {
                            final mech = _mechanics[index];
                            final isSelected =
                                _selectedMechanic?['id'] == mech['id'];
                            return _mechanicCard(mech, isSelected, dark);
                          },
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Action Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ElevatedButton(
                        onPressed: (_selectedMechanic == null || _isRequesting)
                            ? null
                            : _sendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isRequesting
                              ? 'Requesting...'
                              : (_selectedMechanic != null
                                  ? 'Confirm Request'
                                  : 'Select a Mechanic'),
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
            ? AppColors.primaryBlue
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

  Widget _mechanicCard(Map<String, dynamic> mech, bool selected, bool dark) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMechanic = mech);
        _mapController.move(LatLng(mech['lat'], mech['lng']), 14);
      },
      child: Container(
        width: MediaQuery.of(context).size.width *
            0.81, // Show a hint of the next card
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E3350) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primaryBlue
                : (dark ? Colors.grey[800]! : Colors.grey[200]!),
            width: 2,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Profile Pic
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: dark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, color: Colors.grey),
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
                          mech['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: dark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Rs. ${mech['price']}',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    mech['specialty'],
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
                        '${mech['rating']} (${mech['reviews']})',
                        style: TextStyle(
                          fontSize: 12,
                          color: dark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const Spacer(), // Push distance to the end
                      Icon(Icons.location_on,
                          color: Colors.grey[400], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '2.5 km',
                        style: TextStyle(
                          fontSize: 12,
                          color: dark ? Colors.grey[400] : Colors.grey[600],
                        ),
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
