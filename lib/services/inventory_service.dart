import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/inventory_item.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Gets a stream of inventory items for a specific mechanic.
  Stream<List<InventoryItem>> getInventory(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Adds a new item to the mechanic's inventory.
  Future<void> addItem(String userId, InventoryItem item) async {
    final docRef = _db.collection('users').doc(userId).collection('inventory').doc();
    final newItem = item.copyWith(id: docRef.id, userId: userId);
    await docRef.set(newItem.toMap());
  }

  /// Updates an existing inventory item.
  Future<void> updateItem(String userId, InventoryItem item) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .doc(item.id)
        .update(item.toMap());
  }

  /// Deletes an item from inventory.
  Future<void> deleteItem(String userId, String itemId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .doc(itemId)
        .delete();
  }

  /// Adjusts quantity (e.g., after a sale).
  Future<void> adjustQuantity(String userId, String itemId, int adjustment) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('inventory')
        .doc(itemId)
        .update({
      'quantity': FieldValue.increment(adjustment),
    });
  }

  /// Uploads an item image to Firebase Storage and returns the URL.
  Future<String> uploadItemImage(String userId, String fileName, Uint8List fileBytes) async {
    try {
      print("Inventory Debug: Starting upload (Base64 method)...");
      final ref = _storage.ref().child('users/$userId/inventory/$fileName');
      
      final String base64String = base64Encode(fileBytes);
      final String dataUrl = 'data:image/jpeg;base64,$base64String';
      
      final uploadTask = ref.putString(
        dataUrl,
        format: PutStringFormat.dataUrl,
        metadata: SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask.timeout(const Duration(seconds: 30), onTimeout: () {
        print("Inventory Debug: TIMEOUT");
        throw Exception("Upload timed out. This is usually caused by missing CORS configuration in Firebase Storage.");
      });
      
      final url = await snapshot.ref.getDownloadURL();
      print("Inventory Debug: SUCCESS. URL: $url");
      return url;
    } catch (e) {
      print("Inventory Debug: ERROR: $e");
      rethrow;
    }
  }
}
