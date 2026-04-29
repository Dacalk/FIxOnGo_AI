import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Utility service for fetching and updating user profile data.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────────────────────
  //  PROFILE
  // ─────────────────────────────────────────────────────────────

  /// Fetch the current user's Firestore document.
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  /// Update arbitrary fields on the current user's document.
  Future<void> updateCurrentUser(Map<String, dynamic> fields) async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('[UserService] updateCurrentUser uid=${user.uid} fields=$fields');
    await _db.collection('users').doc(user.uid).update(fields);
  }

  /// Stream of the current user's document (real-time).
  Stream<Map<String, dynamic>?> currentUserStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snap) => snap.exists ? {'id': snap.id, ...snap.data()!} : null);
  }

  // ─────────────────────────────────────────────────────────────
  //  ROLE HELPERS
  // ─────────────────────────────────────────────────────────────

  /// Fetch role-specific data for the current user.
  Future<Map<String, dynamic>> getRoleData(String role) async {
    final data = await getCurrentUserData();
    if (data == null) return {};
    final roles = data['roles'] as Map<String, dynamic>? ?? {};
    return roles[role.toLowerCase()] as Map<String, dynamic>? ?? {};
  }

  /// Update a field nested inside a role map using dot notation.
  Future<void> updateRoleField(String role, String field, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint('[UserService] updateRoleField uid=${user.uid} role=$role field=$field');
    await _db.collection('users').doc(user.uid).update({
      'roles.${role.toLowerCase()}.$field': value,
    });
  }
}
