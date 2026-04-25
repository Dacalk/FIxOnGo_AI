import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme_provider.dart';
import 'models/towing_service.dart';
import 'widgets/service_card.dart';
import 'towing_status_screen.dart';

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

  // Mock destination search
  void _setMockDestination() {
    // Just pick a point ~5km away for demo
    if (_pickupCoords != null) {
      setState(() {
        _destinationCoords = LatLng(_pickupCoords!.latitude + 0.04, _pickupCoords!.longitude + 0.04);
        _destinationController.text = "Mock Repair Shop (5.6 km away)";
        _calculateDistance();
      });
    }
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
              onTap: _setMockDestination, // Mock behavior for demo
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
                onPressed: () {
                  // In a real app, we'd validate and save to DB
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TowingStatusScreen(),
                    ),
                  );
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
                child: const Text(
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
        style: TextStyle(color: dark ? Colors.white : Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500]),
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.emergencyRed),
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
