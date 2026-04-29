import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:latlong2/latlong.dart';
import 'location_service.dart';

/// Centralized service that manages:
/// - Provider online/available status
/// - Location publishing to Firestore
/// - Request creation with correct targetRole + assignedProviderId
class ProviderService {
  ProviderService._();
  static final ProviderService instance = ProviderService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────────────────────
  //  ONLINE STATUS MANAGEMENT
  // ─────────────────────────────────────────────────────────────

  /// Called when a provider opens the app — sets isOnline + isAvailable = true
  /// and pushes current location.
  Future<void> goOnline(String role) async {
    final user = _auth.currentUser;
    if (user == null) return;

    LatLng? loc;
    try {
      loc = await LocationService.instance.getCurrentLatLng();
    } catch (_) {}

    final Map<String, dynamic> updates = {
      'roles.${role.toLowerCase()}.isOnline': true,
      'roles.${role.toLowerCase()}.isAvailable': true, // Reset to available when going online
      'roles.${role.toLowerCase()}.lastSeen': FieldValue.serverTimestamp(),
    };

    if (loc != null) {
      updates['roles.${role.toLowerCase()}.location'] = {
        'lat': loc.latitude,
        'lng': loc.longitude,
      };
    }

    debugPrint('[ProviderService] goOnline uid=${user.uid} role=$role loc=$loc');
    await _db.collection('users').doc(user.uid).update(updates);
  }

  /// Called when provider accepts a job — marks them as unavailable.
  Future<void> setUnavailable(String role) async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('[ProviderService] setUnavailable uid=${user.uid} role=$role');
    await _db.collection('users').doc(user.uid).update({
      'roles.${role.toLowerCase()}.isAvailable': false,
    });
  }

  /// Called when provider completes a job — marks them available again.
  Future<void> setAvailable(String role) async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('[ProviderService] setAvailable uid=${user.uid} role=$role');
    await _db.collection('users').doc(user.uid).update({
      'roles.${role.toLowerCase()}.isAvailable': true,
    });
  }

  /// Push updated location for a provider role.
  Future<void> updateLocation(String role, LatLng loc) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'roles.${role.toLowerCase()}.location': {
        'lat': loc.latitude,
        'lng': loc.longitude,
      },
      'roles.${role.toLowerCase()}.lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  REAL-TIME LISTENER STREAMS (CORE RULE)
  //  All listeners use: targetRole + assignedProviderId + status == 'pending'
  // ─────────────────────────────────────────────────────────────

  /// Stream of pending requests assigned to this provider.
  Stream<List<Map<String, dynamic>>> pendingRequestsStream({
    required String targetRole,   // e.g. 'mechanic'
    required String providerUid,  // Firebase UID
  }) {
    debugPrint('[ProviderService] pendingRequestsStream targetRole=$targetRole mechanic UID=$providerUid');
    return _db
        .collection('requests')
        .where('targetRole', isEqualTo: targetRole.toLowerCase())
        .where('assignedProviderId', isEqualTo: providerUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          debugPrint('[ProviderService] pendingRequestsStream mechanic UID=$providerUid result count=${snap.docs.length}');
          return snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList();
        });
  }

  /// Stream of pending deliveries assigned to this delivery driver.
  Stream<List<Map<String, dynamic>>> pendingDeliveriesStream({
    required String providerUid,
  }) {
    debugPrint('[ProviderService] pendingDeliveriesStream uid=$providerUid');
    return _db
        .collection('deliveries')
        .where('assignedProviderId', isEqualTo: providerUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          debugPrint('[ProviderService] pendingDeliveriesStream got ${snap.docs.length} docs');
          return snap.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList();
        });
  }

  // ─────────────────────────────────────────────────────────────
  //  REQUEST CREATION
  // ─────────────────────────────────────────────────────────────

  /// Create a mechanic request with proper targetRole + assignedProviderId.
  Future<String> createMechanicRequest({
    required String mechanicUid,
    required String mechanicName,
    required String userName,
    String? userPhotoUrl,
    required String userId,
    required Map<String, double> userLocation,
    required String serviceType,
    int basePrice = 2000,
  }) async {
    debugPrint('[ProviderService] createMechanicRequest '
        'assignedProviderId=$mechanicUid userId=$userId');

    final ref = await _db.collection('requests').add({
      'targetRole': 'mechanic',
      'assignedProviderId': mechanicUid,
      'mechanicId': mechanicUid,       // keep legacy field for backward compat
      'mechanicName': mechanicName,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'userLocation': userLocation,
      'serviceType': serviceType,
      'status': 'pending',
      'basePrice': basePrice,
      'totalPrice': basePrice,
      'tools': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[ProviderService] createMechanicRequest id=${ref.id}');
    return ref.id;
  }

  /// Create a tow request assigned to the nearest tow provider.
  Future<String> createTowRequest({
    required String towProviderUid,
    required String towProviderName,
    required String userName,
    String? userPhotoUrl,
    required String userId,
    required Map<String, double> userLocation,
    Map<String, double>? dropoffLocation,
    String? dropoffAddress,
    int basePrice = 2500,
  }) async {
    debugPrint('[ProviderService] createTowRequest '
        'assignedProviderId=$towProviderUid userId=$userId');

    final ref = await _db.collection('requests').add({
      'targetRole': 'tow',
      'assignedProviderId': towProviderUid,
      'mechanicId': towProviderUid,    // keep legacy
      'mechanicName': towProviderName,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'userLocation': userLocation,
      'dropoffLocation': dropoffLocation,
      'dropoffAddress': dropoffAddress,
      'type': 'towing',
      'status': 'pending',
      'basePrice': basePrice,
      'totalPrice': basePrice,
      'tools': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[ProviderService] createTowRequest id=${ref.id}');
    return ref.id;
  }

  /// Accept a request: update status + set provider unavailable.
  Future<void> acceptRequest({
    required String requestId,
    required String providerUid,
    required String providerName,
    required String role,
  }) async {
    debugPrint('[ProviderService] acceptRequest requestId=$requestId mechanic UID=$providerUid role=$role');

    await _db.collection('requests').doc(requestId).update({
      'status': 'accepted',
      'mechanicId': providerUid,
      'mechanicName': providerName,
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    await setUnavailable(role);
  }

  /// Complete a request: set provider available again.
  Future<void> completeRequest({
    required String requestId,
    required String role,
    required String providerUid,
  }) async {
    debugPrint('[ProviderService] completeRequest id=$requestId role=$role');

    await _db.collection('requests').doc(requestId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    await setAvailable(role);
  }

  // ─────────────────────────────────────────────────────────────
  //  DELIVERY LOGIC
  // ─────────────────────────────────────────────────────────────

  /// Find the nearest available and online delivery driver.
  Future<Map<String, dynamic>?> findNearestAvailableDriver(LatLng pickupLoc) async {
    debugPrint('[ProviderService] findNearestAvailableDriver pickup=$pickupLoc');
    
    try {
      final snap = await _db
          .collection('users')
          .where('roles.delivery', isNotEqualTo: null)
          .get();

      Map<String, dynamic>? nearest;
      double minDistance = double.infinity;

      final distance = const Distance();

      for (var doc in snap.docs) {
        final data = doc.data();
        final deliv = data['roles']?['delivery'] as Map<String, dynamic>?;
        
        if (deliv == null) continue;
        
        final isOnline = deliv['isOnline'] as bool? ?? true;
        final isAvailable = deliv['isAvailable'] as bool? ?? true;
        
        if (!isOnline || !isAvailable) continue;

        final loc = deliv['location'] as Map<String, dynamic>?;
        if (loc == null) continue;

        final driverLoc = LatLng(loc['lat'], loc['lng']);
        final d = distance.as(LengthUnit.Meter, pickupLoc, driverLoc);

        if (d < minDistance) {
          minDistance = d;
          nearest = {
            'uid': doc.id,
            'name': deliv['fullName'] ?? data['fullName'] ?? 'Driver',
            'location': loc,
            'distance': d,
          };
        }
      }

      return nearest;
    } catch (e) {
      debugPrint('[ProviderService] Error finding driver: $e');
      return null;
    }
  }

  /// Create a delivery request and assign it to a driver.
  Future<String> createDeliveryRequest({
    required String sourceRole, // 'seller' or 'mechanic'
    required String senderId,
    required String senderName,
    required String? driverId,
    required String? driverName,
    required String itemName,
    required String itemCategory,
    required double itemPrice,
    required String pickupAddress,
    required String dropAddress,
    required Map<String, double> pickupLocation,
    required Map<String, double> dropLocation,
    String? notes,
    num earnings = 350,
    String? orderId,
  }) async {
    debugPrint('[ProviderService] createDeliveryRequest sender=$senderName driver=$driverName');

    final ref = await _db.collection('deliveries').add({
      'sourceRole': sourceRole,
      'targetRole': 'delivery',
      'senderId': senderId,
      'senderName': senderName,
      'assignedProviderId': driverId, // The UID of the driver
      'driverId': driverId,
      'driverName': driverName,
      'itemName': itemName,
      'itemCategory': itemCategory,
      'itemPrice': itemPrice,
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'pickupLat': pickupLocation['lat'],
      'pickupLng': pickupLocation['lng'],
      'dropLat': dropLocation['lat'],
      'dropLng': dropLocation['lng'],
      'notes': notes,
      'status': 'pending',
      'earnings': earnings,
      'orderId': orderId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }
}
