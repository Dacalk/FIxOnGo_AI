import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme_provider.dart';
import 'models/towing_service.dart';
import 'widgets/service_card.dart';
import 'dart:async';
import '../../services/map_service.dart';
import '../../../components/osm_map_widget.dart';

class TowingBookingScreen extends StatefulWidget {
  const TowingBookingScreen({super.key});

  @override
  State<TowingBookingScreen> createState() => _TowingBookingScreenState();
}

class _TowingBookingScreenState extends State<TowingBookingScreen> {
  final List<TowingService> _services = TowingService.getMockServices();
  String _selectedServiceId = 'emergency_tow';

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
  bool _isLoadingVehicle = true;
  bool _showMapPicker = false;
  bool _mapReady = false;

  // Map picker state
  LatLng _mapPickerCenter = const LatLng(6.9271, 79.8612);
  final MapController _mapPickerController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserVehicle();
  }

  /// Load user's primary vehicle from Firestore and auto-fill
  Future<void> _loadUserVehicle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingVehicle = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final roles = doc.data()?['roles'] as Map<String, dynamic>? ?? {};
        // Try user role first, then mechanic for fallback
        final userRole = roles['user'] as Map<String, dynamic>? ??
            roles['mechanic'] as Map<String, dynamic>? ??
            {};

        setState(() {
          final type = userRole['vehicleType']?.toString() ?? '';
          final plate = userRole['plate']?.toString() ?? '';
          final color = userRole['color']?.toString() ?? '';

          if (type.isNotEmpty) _makeModelController.text = type;
          if (plate.isNotEmpty) _plateController.text = plate;
          if (color.isNotEmpty) _colorController.text = color;
          _isLoadingVehicle = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingVehicle = false);
      }
    } catch (e) {
      debugPrint('[TowingBooking] Error loading vehicle: $e');
      if (mounted) setState(() => _isLoadingVehicle = false);
    }
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
      final coords = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _pickupCoords = coords;
          _pickupController.text = "Fetching address...";
        });
      }

      // Reverse geocode to get address name
      try {
        final address = await MapService.instance.reverseGeocode(coords);
        if (mounted) {
          setState(() {
            _pickupController.text = address;
          });
        }
      } catch (e) {
        debugPrint('[TowingBooking] Reverse geocode error: $e');
        if (mounted) {
          setState(() {
            _pickupController.text = "Current Location";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pickupController.text = "Error fetching location";
        });
      }
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

  /// Open a full-screen map picker to select drop-off location by tapping
  void _openMapPicker() {
    setState(() {
      _showMapPicker = true;
      _mapReady = false;
      // Start at pickup location or default
      _mapPickerCenter = _pickupCoords ?? const LatLng(6.9271, 79.8612);
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _mapReady = true);
    });
  }

  /// Confirm pin location from map and reverse geocode
  Future<void> _confirmMapLocation(LatLng point) async {
    setState(() {
      _destinationCoords = point;
      _destinationController.text = "Fetching address...";
      _showMapPicker = false;
    });

    try {
      final address = await MapService.instance.reverseGeocode(point);
      if (mounted) {
        setState(() {
          _destinationController.text = address;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _destinationController.text = "Selected Location (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})";
        });
      }
    }
    _calculateDistance();
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
    _mapPickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF8F9FE);

    // If map picker is open, show it full-screen
    if (_showMapPicker) {
      return _buildMapPickerView(dark);
    }

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

            // Drop-off: text search + map picker button
            Row(
              children: [
                Expanded(
                  child: _buildLocationInput(
                    controller: _destinationController,
                    label: "Drop-off Location",
                    icon: Icons.location_on,
                    hint: "Search or pick on map",
                    dark: dark,
                    onChanged: _onDestinationChanged,
                  ),
                ),
                const SizedBox(width: 8),
                // Map picker button
                GestureDetector(
                  onTap: _openMapPicker,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergencyRed.withAlpha(76),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.map_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            
            // Suggestions List
            if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10)],
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
                child: Row(
                  children: [
                    const Icon(Icons.straighten, size: 16, color: AppColors.emergencyRed),
                    const SizedBox(width: 6),
                    Text(
                      "Estimated Distance: ${_estimatedDistance!.toStringAsFixed(1)} km",
                      style: const TextStyle(
                        color: AppColors.emergencyRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Vehicle Details section with auto-fill indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("Vehicle Details", dark),
                if (!_isLoadingVehicle && _makeModelController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "Auto-filled",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Pre-filled from your primary vehicle. You can edit if needed.",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
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
                onPressed: () {
                  // Navigate to SearchingTowsScreen with booking details
                  Navigator.pushNamed(
                    context,
                    '/searching-tows',
                    arguments: {
                      'serviceType': _services.firstWhere((s) => s.id == _selectedServiceId).title,
                      'basePrice': _services.firstWhere((s) => s.id == _selectedServiceId).basePrice,
                      'pickupCoords': _pickupCoords != null
                          ? {'lat': _pickupCoords!.latitude, 'lng': _pickupCoords!.longitude}
                          : null,
                      'destinationCoords': _destinationCoords != null
                          ? {'lat': _destinationCoords!.latitude, 'lng': _destinationCoords!.longitude}
                          : null,
                      'destinationAddress': _destinationController.text,
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
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.emergencyRed.withAlpha(102),
                ),
                child: const Text(
                      "FIND NEARBY TOW TRUCKS",
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

  // ─── MAP PICKER VIEW ──────────────────────────────────────────────
  Widget _buildMapPickerView(bool dark) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          Positioned.fill(
            child: _mapReady
                ? OsmMapWidget(
                    center: _mapPickerCenter,
                    zoom: 15,
                    mapController: _mapPickerController,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _mapPickerCenter = point;
                      });
                    },
                    markers: [
                      // Pin at selected location
                      Marker(
                        point: _mapPickerCenter,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.emergencyRed,
                          size: 50,
                        ),
                      ),
                      // User location
                      if (_pickupCoords != null)
                        Marker(
                          point: _pickupCoords!,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                    showLocateButton: false,
                  )
                : Container(
                    color: dark ? AppColors.darkBackground : const Color(0xFFE8E8E8),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
          ),

          // Instruction card at top
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showMapPicker = false),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: dark ? Colors.grey[800] : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back, size: 18,
                          color: dark ? Colors.white : Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Drop-off Location",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: dark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          "Tap on the map to place your pin",
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confirm button at bottom
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () => _confirmMapLocation(_mapPickerCenter),
              icon: const Icon(Icons.check_circle, size: 22),
              label: const Text(
                "CONFIRM LOCATION",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                shadowColor: AppColors.emergencyRed.withAlpha(102),
              ),
            ),
          ),
        ],
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
