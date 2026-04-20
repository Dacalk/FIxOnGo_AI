import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme_provider.dart';
import '../components/osm_map_widget.dart';
import '../services/location_service.dart';

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

  /// Simulated nearby mechanic offsets (relative to user location).
  static const List<List<double>> _mechanicOffsets = [
    [0.004, 0.003],
    [-0.003, 0.005],
    [0.006, -0.002],
    [-0.005, -0.004],
    [0.002, 0.006],
  ];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _fetchLocation();
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
    for (final offset in _mechanicOffsets) {
      final mechLatLng = LatLng(
        _userLatLng!.latitude + offset[0],
        _userLatLng!.longitude + offset[1],
      );
      markers.add(
        Marker(
          point: mechLatLng,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1E3350) : const Color(0xFF2C3E50),
              shape: BoxShape.circle,
              border: Border.all(
                color: dark ? Colors.grey[700]! : Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  void dispose() {
    _dotController.dispose();
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

          // ── Bottom Sheet ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Searching for nearby\nmechanics...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Animated dots
                    AnimatedBuilder(
                      animation: _dotController,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final progress = _dotController.value;
                            final activeIndex = (progress * 5).floor() % 5;
                            final isActive = index <= activeIndex;
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? AppColors.primaryBlue
                                    : (dark
                                        ? Colors.grey[700]
                                        : Colors.grey[300]),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // Status text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sync,
                          size: 16,
                          color: dark ? Colors.grey[500] : Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Contacting service providers',
                          style: TextStyle(
                            fontSize: 14,
                            color: dark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
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
}
