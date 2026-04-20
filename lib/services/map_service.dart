import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Data class for a geocode search result.
class GeocodedPlace {
  final String displayName;
  final LatLng latLng;

  const GeocodedPlace({required this.displayName, required this.latLng});
}

/// Data class for a route/directions result.
class RouteResult {
  /// Ordered list of coordinates forming the route polyline.
  final List<LatLng> points;

  /// Total distance in metres.
  final double distanceMetres;

  /// Estimated duration in seconds.
  final double durationSeconds;

  /// Human-readable summary, e.g. "3.2 km  •  7 min".
  String get summary {
    final km = (distanceMetres / 1000).toStringAsFixed(1);
    final mins = (durationSeconds / 60).ceil();
    return '$km km  •  $mins min';
  }

  const RouteResult({
    required this.points,
    required this.distanceMetres,
    required this.durationSeconds,
  });
}

/// Service wrapping the free OpenRouteService REST API.
///
/// Requires an API key stored in `.env` as `ORS_API_KEY`.
/// Free tier: 2 000 directions/day, 1 000 geocode/day.
class MapService {
  MapService._();
  static final MapService instance = MapService._();

  static const String _baseUrl = 'https://api.openrouteservice.org';

  String get _apiKey => dotenv.env['ORS_API_KEY'] ?? '';

  // ─── Directions ────────────────────────────────────────────────────

  /// Fetch driving directions between [origin] and [destination].
  /// Returns a [RouteResult] with polyline points and metadata.
  Future<RouteResult> getDirections(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      '$_baseUrl/v2/directions/driving-car'
      '?api_key=$_apiKey'
      '&start=${origin.longitude},${origin.latitude}'
      '&end=${destination.longitude},${destination.latitude}',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw 'Directions request failed (${response.statusCode}): '
          '${response.body}';
    }

    final data = jsonDecode(response.body);
    final feature = data['features'][0];
    final geometry = feature['geometry']['coordinates'] as List;
    final props = feature['properties']['summary'];

    final points = geometry
        .map<LatLng>(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    return RouteResult(
      points: points,
      distanceMetres: (props['distance'] as num).toDouble(),
      durationSeconds: (props['duration'] as num).toDouble(),
    );
  }

  // ─── Geocode (search address → LatLng) ─────────────────────────────

  /// Search for places matching [query]. Returns up to 5 results.
  Future<List<GeocodedPlace>> geocodeAddress(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      '$_baseUrl/geocode/search'
      '?api_key=$_apiKey'
      '&text=${Uri.encodeComponent(query)}'
      '&size=5',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw 'Geocode request failed (${response.statusCode})';
    }

    final data = jsonDecode(response.body);
    final features = data['features'] as List;

    return features.map<GeocodedPlace>((f) {
      final coords = f['geometry']['coordinates'];
      return GeocodedPlace(
        displayName: f['properties']['label'] ?? '',
        latLng: LatLng(
          (coords[1] as num).toDouble(),
          (coords[0] as num).toDouble(),
        ),
      );
    }).toList();
  }

  // ─── Reverse Geocode (LatLng → address) ─────────────────────────────

  /// Get a human-readable address for a coordinate.
  Future<String> reverseGeocode(LatLng point) async {
    final url = Uri.parse(
      '$_baseUrl/geocode/reverse'
      '?api_key=$_apiKey'
      '&point.lon=${point.longitude}'
      '&point.lat=${point.latitude}'
      '&size=1',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw 'Reverse geocode failed (${response.statusCode})';
    }

    final data = jsonDecode(response.body);
    final features = data['features'] as List;
    if (features.isEmpty) return 'Unknown location';

    return features[0]['properties']['label'] ?? 'Unknown location';
  }
}
