import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';

class VehicleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Gets a stream of vehicles for a specific user.
  Stream<List<Vehicle>> getVehicles(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Vehicle.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Adds a new vehicle to the user's garage.
  Future<void> addVehicle(String userId, Vehicle vehicle) async {
    final docRef = _db.collection('users').doc(userId).collection('vehicles').doc();
    final newVehicle = vehicle.copyWith(id: docRef.id, userId: userId);
    
    // If this is the first vehicle, make it primary
    final existing = await _db.collection('users').doc(userId).collection('vehicles').get();
    final isFirst = existing.docs.isEmpty;
    
    await docRef.set(newVehicle.copyWith(isPrimary: isFirst).toMap());
  }

  /// Deletes a vehicle from the user's garage.
  Future<void> deleteVehicle(String userId, String vehicleId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicleId)
        .delete();
  }

  /// Sets a vehicle as primary and unsets all others.
  Future<void> setPrimaryVehicle(String userId, String vehicleId) async {
    final batch = _db.batch();
    final vehiclesRef = _db.collection('users').doc(userId).collection('vehicles');
    
    final allVehicles = await vehiclesRef.get();
    for (var doc in allVehicles.docs) {
      batch.update(doc.reference, {'isPrimary': doc.id == vehicleId});
    }
    
    await batch.commit();
  }

  /// Updates an existing vehicle.
  Future<void> updateVehicle(String userId, Vehicle vehicle) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicle.id)
        .update(vehicle.toMap());
  }
}
