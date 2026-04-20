import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Singleton service that wraps the geolocator package for GPS operations.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // ─── Permission Handling ───────────────────────────────────────────

  /// Check whether location services are enabled and permissions granted.
  /// Returns `true` if everything is ready, otherwise throws a descriptive
  /// error string.
  Future<bool> checkAndRequestPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable GPS.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions were denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied. '
          'Please enable them in Settings.';
    }

    return true;
  }

  // ─── Current Position ──────────────────────────────────────────────

  /// Returns the device's current position as a [LatLng].
  Future<LatLng> getCurrentLatLng() async {
    await checkAndRequestPermissions();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }

  /// Returns the raw [Position] (includes altitude, speed, heading, etc.).
  Future<Position> getCurrentPosition() async {
    await checkAndRequestPermissions();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // ─── Position Stream (real-time tracking) ──────────────────────────

  /// Returns a stream of position updates.
  /// [distanceFilter] — minimum distance (in metres) before an update fires.
  Stream<Position> getPositionStream({int distanceFilter = 10}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  // ─── Utilities ─────────────────────────────────────────────────────

  /// Distance between two points in metres.
  double getDistanceBetween(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }
}
