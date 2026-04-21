import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'location_service.dart';

class TestService {
  static final TestService instance = TestService._();
  TestService._();

  /// Spawns a mock mechanic in Firestore near the user's current location.
  Future<void> spawnMockMechanic() async {
    try {
      final userPos = await LocationService.instance.getCurrentLatLng();

      // Offset slightly to be "nearby" (about 500m - 1km)
      final mockPos = LatLng(
        userPos.latitude + 0.005,
        userPos.longitude + 0.003,
      );

      const mockId = 'mock_mechanic_test';

      await FirebaseFirestore.instance.collection('users').doc(mockId).set({
        'email': 'mock@fixongo.test',
        'roles': {
          'mechanic': {
            'fullName': 'Mock Mechanic (Test)',
            'vehicleType': 'Test Van - TST 1234',
            'location': {
              'lat': mockPos.latitude,
              'lng': mockPos.longitude,
            },
            'lastSeen': FieldValue.serverTimestamp(),
            'rating': 4.8,
            'reviews': 120,
            'priceBase': 2500,
          }
        }
      });

      print('DEBUG: Spawned mock mechanic at $mockPos');
    } catch (e) {
      print('DEBUG ERROR: Failed to spawn mock mechanic: $e');
    }
  }

  /// Ensures the currently logged-in user (if email matches the mock email)
  /// has the mechanic role and is ready to receive requests.
  Future<void> makeMeMockMechanic(String uid, LatLng userPos) async {
    try {
      // Create a fixed Nearby location for testing visibility
      final mockPos = LatLng(
        userPos.latitude + 0.005,
        userPos.longitude + 0.003,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': 'mock@fixongo.test',
        'roles': {
          'mechanic': {
            'fullName': 'Mock Professional (Test)',
            'vehicleType': 'Test Service Van',
            'location': {
              'lat': mockPos.latitude,
              'lng': mockPos.longitude,
            },
            'lastSeen': FieldValue.serverTimestamp(),
            'rating': 4.9,
            'reviews': 250,
            'priceBase': 3500,
          }
        }
      }, SetOptions(merge: true));

      print('DEBUG: Current user ($uid) is now the Mock Mechanic at $mockPos');
    } catch (e) {
      print('DEBUG ERROR: Failed to update current user to mock mechanic: $e');
    }
  }

  /// Cleans up the specific hardcoded mock mechanic.
  Future<void> cleanupMocks() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc('mock_mechanic_test')
          .delete();
    } catch (e) {
      print('DEBUG: cleanupMocks suppressed: $e');
    }
  }

  /// Removes any user documents with the mock email that AREN'T the current UID.
  Future<void> removeDuplicateMocks(String currentUid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: 'mock@fixongo.test')
          .get();

      for (var doc in snap.docs) {
        if (doc.id != currentUid) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('DEBUG: removeDuplicateMocks suppressed: $e');
    }
  }
}
