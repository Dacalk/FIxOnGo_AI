import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme_provider.dart';

/// Reusable OpenStreetMap widget used across all map screens.
///
/// Wraps [FlutterMap] with consistent theming and convenient helpers.
class OsmMapWidget extends StatelessWidget {
  /// Centre of the map when first displayed.
  final LatLng center;

  /// Initial zoom level (default 15).
  final double zoom;

  /// Markers to display on the map.
  final List<Marker> markers;

  /// Optional route polyline points.
  final List<LatLng>? polylinePoints;

  /// Colour of the route polyline (defaults to brand blue).
  final Color? polylineColor;

  /// Called when the user taps on the map.
  final void Function(TapPosition, LatLng)? onTap;

  /// Optional external map controller.
  final MapController? mapController;

  /// Whether to show the "locate me" button (default true).
  final bool showLocateButton;

  /// Called when the locate-me button is pressed.
  final VoidCallback? onLocateMe;

  const OsmMapWidget({
    super.key,
    required this.center,
    this.zoom = 15,
    this.markers = const [],
    this.polylinePoints,
    this.polylineColor,
    this.onTap,
    this.mapController,
    this.showLocateButton = true,
    this.onLocateMe,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final routeColor =
        polylineColor ?? (dark ? AppColors.brandYellow : AppColors.primaryBlue);

    final tileUrl = dark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final subdomains = dark ? ['a', 'b', 'c', 'd'] : <String>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: zoom,
                  onTap: onTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: tileUrl,
                    subdomains: subdomains,
                    userAgentPackageName: 'com.fixongo.app',
                  ),
                  if (polylinePoints != null && polylinePoints!.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polylinePoints!,
                          strokeWidth: 4.0,
                          color: routeColor,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
            if (showLocateButton)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'locateMe',
                  backgroundColor: dark ? AppColors.darkSurface : Colors.white,
                  onPressed: onLocateMe,
                  child: Icon(
                    Icons.my_location,
                    color: dark ? AppColors.brandYellow : AppColors.primaryBlue,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
