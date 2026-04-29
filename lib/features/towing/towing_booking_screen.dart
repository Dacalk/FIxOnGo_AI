import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme_provider.dart';
import 'models/towing_service.dart';
import 'widgets/service_card.dart';
import 'towing_status_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../services/map_service.dart';

class TowingBookingScreen extends StatefulWidget {
  const TowingBookingScreen({super.key});

  @override
  State<TowingBookingScreen> createState() => _TowingBookingScreenState();
}

class _TowingBookingScreenState extends State<TowingBookingScreen> {
  final List<TowingService> _services = TowingService.getMockServices();
  String _selectedServiceId = 'emergency_tow';
  bool _isSubmitting = false;

  final TextEditingController _pickupController = TextEditingController(text: "Fetching current location...");
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _makeModelController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  LatLng? _pickupCoords;
  LatLng? _destinationCoords;
  double? _estimatedDistance;
  
  List<GeocodedPlace> _suggestions = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _pickupCoords = LatLng(position.latitude, position.longitude);
        _pickupController.text = "Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})";
      });
    } catch (e) {
      setState(() {
        _pickupController.text = "Error fetching location";
      });
    }
  }

  void _calculateDistance() {
    if (_pickupCoords != null && _destinationCoords != null) {
      final Distance distance = const Distance();
      final double meter = distance.as(LengthUnit.Meter, _pickupCoords!, _destinationCoords!);
      setState(() {
        _estimatedDistance = meter / 1000;
      });
    }
  }

  // Real-time destination search
  void _onDestinationChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() => _suggestions = []);
        return;
      }

      setState(() => _isSearching = true);
      try {
        final results = await MapService.instance.geocodeAddress(query);
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      } catch (e) {
        setState(() => _isSearching = false);
      }
    });
  }

  void _selectSuggestion(GeocodedPlace place) {
    setState(() {
      _destinationCoords = place.latLng;
      _destinationController.text = place.displayName;
      _suggestions = [];
      _calculateDistance();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupController.dispose();
    _destinationController.dispose();
    _makeModelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: dark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Towing & Roadside",
          style: TextStyle(
            color: dark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Select Service", dark),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return ServiceCard(
                    service: service,
                    isSelected: _selectedServiceId == service.id,
                    onTap: () => setState(() => _selectedServiceId = service.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle("Trip Details", dark),
            const SizedBox(height: 16),
            _buildLocationInput(
              controller: _pickupController,
              label: "Pickup Location",
              icon: Icons.my_location,
              isReadOnly: true,
              dark: dark,
            ),
            const SizedBox(height: 16),
            _buildLocationInput(
              controller: _destinationController,
              label: "Drop-off Location",
              icon: Icons.location_on,
              hint: "Where to? (e.g. Home, Repair Shop)",
              dark: dark,
              onChanged: _onDestinationChanged,
            ),
            
            // Suggestions List
            if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                ),
                child: Column(
                  children: _suggestions.map((p) => ListTile(
                    leading: const Icon(Icons.place, color: AppColors.emergencyRed, size: 20),
                    title: Text(p.displayName, style: TextStyle(fontSize: 14, color: dark ? Colors.white : Colors.black87)),
                    onTap: () => _selectSuggestion(p),
                  )).toList(),
                ),
              ),
            if (_estimatedDistance != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  "Estimated Distance: ${_estimatedDistance!.toStringAsFixed(1)} km",
                  style: const TextStyle(
                    color: AppColors.emergencyRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            _buildSectionTitle("Vehicle Details", dark),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInput(
                    controller: _makeModelController,
                    label: "Make/Model",
                    hint: "e.g. Toyota Camry",
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInput(
                    controller: _colorController,
                    label: "Color",
                    hint: "e.g. Silver",
                    dark: dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInput(
              controller: _plateController,
              label: "License Plate",
              hint: "ABC-1234",
              dark: dark,
            ),
            const SizedBox(height: 16),
            _buildInput(
              controller: _notesController,
              label: "Instructions/Notes",
              hint: "e.g. Keys are in the exhaust pipe",
              maxLines: 3,
              dark: dark,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  setState(() => _isSubmitting = true);

                  try {
                    // ── Find nearest available tow provider ──────────────
                    String? nearestTowUid;
                    String? nearestTowName;

                    final towSnap = await FirebaseFirestore.instance
                        .collection('users')
                        .where('roles.tow', isNotEqualTo: null)
                        .get();

                    double minDist = double.infinity;
                    for (final doc in towSnap.docs) {
                      final roles = doc.data()['roles'] as Map<String, dynamic>? ?? {};
                      final towData = roles['tow'] as Map<String, dynamic>? ?? {};
                      final isAvailable = towData['isAvailable'] as bool? ?? true;
                      final isOnline = towData['isOnline'] as bool? ?? true;
                      if (!isAvailable || !isOnline) continue;

                      final loc = towData['location'] as Map<String, dynamic>?;
                      if (loc == null) continue;

                      if (_pickupCoords != null) {
                        final d = Geolocator.distanceBetween(
                          _pickupCoords!.latitude, _pickupCoords!.longitude,
                          (loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble(),
                        );
                        if (d < minDist) {
                          minDist = d;
                          nearestTowUid = doc.id;
                          nearestTowName = towData['fullName'] as String? ?? 'Tow Driver';
                        }
                      }
                    }

                    debugPrint('[TowingBooking] userId=${user.uid} '
                        'nearest tow UID=$nearestTowUid dist=$minDist');

                    // Guard: if no tow provider found, show error and stop
                    if (nearestTowUid == null) {
                      debugPrint('[TowingBooking] No available tow provider found — aborting booking');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No tow driver available right now. Please try again shortly.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    final Map<String, dynamic> requestData = {
                      'targetRole': 'tow',
                      'assignedProviderId': nearestTowUid,
                      'mechanicId': nearestTowUid,
                      'mechanicName': nearestTowName,
                      'userId': user.uid,
                      'userName': user.displayName ?? 'User',
                      'type': 'towing',
                      'serviceType': _services.firstWhere((s) => s.id == _selectedServiceId).title,
                      'status': 'pending',
                      'userLocation': {
                        'lat': _pickupCoords?.latitude ?? 0,
                        'lng': _pickupCoords?.longitude ?? 0,
                      },
                      'userAddress': _pickupController.text,
                      'destination': {
                        'lat': _destinationCoords?.latitude ?? 0,
                        'lng': _destinationCoords?.longitude ?? 0,
                        'address': _destinationController.text,
                      },
                      'vehicleDetails': {
                        'makeModel': _makeModelController.text,
                        'color': _colorController.text,
                        'plate': _plateController.text,
                      },
                      'notes': _notesController.text,
                      'estimatedDistance': _estimatedDistance ?? 0,
                      'basePrice': _services.firstWhere((s) => s.id == _selectedServiceId).basePrice,
                      'createdAt': FieldValue.serverTimestamp(),
                    };

                    debugPrint('[TowingBooking] Creating request: '
                        'assignedProviderId=${requestData['assignedProviderId']} '
                        'tow UID=$nearestTowUid '
                        'targetRole=${requestData['targetRole']} '
                        'status=${requestData['status']}');

                    final ref = await FirebaseFirestore.instance
                        .collection('requests')
                        .add(requestData);

                    debugPrint('[TowingBooking] request created requestId=${ref.id} tow UID=$nearestTowUid');

                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TowingStatusScreen(requestId: ref.id),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('[TowingBooking] Error: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.emergencyRed.withValues(alpha: 0.4),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "CONFIRM BOOKING",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
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

  Widget _buildSectionTitle(String title, bool dark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: dark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isReadOnly = false,
    required bool dark,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? Colors.grey[800]! : Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        onTap: onTap,
        onChanged: onChanged,
        style: TextStyle(color: dark ? Colors.white : Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.emergencyRed),
          suffixIcon: (label == "Drop-off Location" && _isSearching) 
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emergencyRed)),
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    required bool dark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? Colors.grey[800]! : Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: dark ? Colors.white : Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
