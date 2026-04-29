import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/osm_map_widget.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';

/// A nearby place suggestion chip data model.
class NearbyPlace {
  final String name;
  final String subtitle;

  const NearbyPlace({required this.name, required this.subtitle});
}

/// Location screen showing the user's current location on a real OSM map,
/// with a location info card, nearby place chips, and a Request Service button.
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final MapController _mapController = MapController();

  /// User's current position (null until GPS fires).
  LatLng? _currentLatLng;

  /// Reverse-geocoded address string.
  String _addressTitle = 'Fetching location…';
  String _addressSubtitle = 'Waiting for GPS signal';

  bool _loading = true;

  static const List<NearbyPlace> _nearbyPlaces = [
    NearbyPlace(
      name: 'Little Adams Peak Ella',
      subtitle: 'Ella Road Wellawaya',
    ),
    NearbyPlace(name: 'Nine Arch Bridge', subtitle: 'Ella Road Wellawaya'),
    NearbyPlace(name: 'Ella Rock Trailhead', subtitle: 'Ella Town Center'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final latLng = await LocationService.instance.getCurrentLatLng();
      if (!mounted) return;

      // Reverse-geocode for a nice address
      String address;
      try {
        address = await MapService.instance.reverseGeocode(latLng);
      } catch (_) {
        address = '${latLng.latitude.toStringAsFixed(4)}, '
            '${latLng.longitude.toStringAsFixed(4)}';
      }

      setState(() {
        _currentLatLng = latLng;
        _addressTitle = address;
        _addressSubtitle = 'GPS location accurately fetched';
        _loading = false;
      });

      _mapController.move(latLng, 15);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addressTitle = 'Location unavailable';
        _addressSubtitle = e.toString();
        _loading = false;
      });
    }
  }

  void _onLocateMe() {
    if (_currentLatLng != null) {
      _mapController.move(_currentLatLng!, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final cardBg = dark ? const Color(0xFF12233D) : Colors.white;

    // Default centre (Colombo, Sri Lanka) while GPS loads.
    final center = _currentLatLng ?? const LatLng(6.9271, 79.8612);

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen Map ──
          Positioned.fill(
            child: OsmMapWidget(
              center: center,
              zoom: 15,
              mapController: _mapController,
              showLocateButton: false, // custom buttons used instead
              markers: _currentLatLng != null
                  ? [
                      Marker(
                        point: _currentLatLng!,
                        width: 50,
                        height: 50,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_pin_circle,
                              size: 40,
                              color: dark ? Colors.white : Colors.black87,
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue
                                        .withAlpha(102),
                                    blurRadius: 12,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  : [],
            ),
          ),

          // ── Loading Indicator ──
          if (_loading)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color:
                          dark ? AppColors.brandYellow : AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Finding your location…',
                      style: TextStyle(
                        color: dark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Back Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _circleButton(
              icon: Icons.arrow_back,
              dark: dark,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // ── My Location Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _circleButton(
              icon: Icons.my_location,
              dark: dark,
              onTap: _onLocateMe,
            ),
          ),

          // ── Compass / Navigate Button ──
          Positioned(
            bottom: 24,
            right: 16,
            child: GestureDetector(
              onTap: _onLocateMe,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withAlpha(76),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),

          // ── Bottom Info Panel ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Location Info Row ──
                    _buildLocationCard(dark),

                    const SizedBox(height: 14),

                    // ── Nearby Places Chips ──
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _nearbyPlaces.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return _buildPlaceChip(_nearbyPlaces[index], dark);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Request Service Button ──
                    PrimaryButton(
                      label: 'Request Service',
                      onPressed: () {
                        Navigator.pushNamed(context, '/service-request');
                      },
                      borderRadius: 15,
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

  /// Location detail card with GPS status
  Widget _buildLocationCard(bool dark) {
    final titleColor = dark ? Colors.white : Colors.black;
    final labelColor = dark ? Colors.blue[300]! : AppColors.primaryBlue;
    final subtitleColor = dark ? Colors.grey[500]! : Colors.grey[600]!;
    return Row(
      children: [
        // Blue dot indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: labelColor, width: 2),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: labelColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Text info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR LOCATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _addressTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _addressSubtitle,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ],
          ),
        ),

        // Action buttons
        IconButton(
          icon: Icon(Icons.add, color: dark ? Colors.white70 : Colors.black54),
          onPressed: () {
            Navigator.pushNamed(context, '/add-location');
          },
        ),
        IconButton(
          icon: Icon(
            Icons.favorite_border,
            color: dark ? Colors.white70 : Colors.black54,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  /// Nearby place chip
  Widget _buildPlaceChip(NearbyPlace place, bool dark) {
    final chipBg = dark ? AppColors.darkSurface : Colors.grey[100]!;
    final textColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[500]! : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: AppColors.brandYellow, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                place.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                place.subtitle,
                style: TextStyle(fontSize: 10, color: subColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Circular icon button overlay
  Widget _circleButton({
    required IconData icon,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, size: 20, color: dark ? Colors.white : Colors.black),
      ),
    );
  }
}
