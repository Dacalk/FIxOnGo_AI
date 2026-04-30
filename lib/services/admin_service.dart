import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Central service for all admin operations.
/// Every destructive action writes an entry to [audit_logs].
class AdminService {
  AdminService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Auth ────────────────────────────────────────────────────────

  static Future<bool> isCurrentUserAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final roles = doc.data()?['roles'];
      return roles != null && roles is Map && roles.containsKey('admin');
    } catch (_) {
      return false;
    }
  }

  static Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  static Future<void> signOut() => _auth.signOut();

  // ── Audit Log ───────────────────────────────────────────────────

  static Future<void> logAction(
    String action,
    String targetId,
    Map<String, dynamic> details,
  ) async {
    try {
      await _db.collection('audit_logs').add({
        'adminUid': _auth.currentUser?.uid,
        'adminEmail': _auth.currentUser?.email,
        'action': action,
        'targetId': targetId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'web_admin',
      });
    } catch (_) {}
  }

  // ── User Management ─────────────────────────────────────────────

  static Future<void> setBanStatus(String uid, bool banned) async {
    await _db.collection('users').doc(uid).update({'isBanned': banned});
    await logAction(banned ? 'ban_user' : 'unban_user', uid, {});
  }

  static Future<void> grantAdminRole(String uid) async {
    await _db.collection('users').doc(uid).update({
      'roles.admin': {
        'grantedAt': FieldValue.serverTimestamp(),
        'grantedBy': _auth.currentUser?.uid,
      }
    });
    await logAction('grant_admin', uid, {});
  }

  static Future<void> revokeAdminRole(String uid) async {
    await _db.collection('users').doc(uid).update({
      'roles.admin': FieldValue.delete(),
    });
    await logAction('revoke_admin', uid, {});
  }

  static Future<void> deleteUserDocument(String uid) async {
    await _db.collection('users').doc(uid).delete();
    await logAction('delete_user', uid, {});
  }

  // ── Mechanic Management ─────────────────────────────────────────

  static Future<void> setMechanicActive(String uid, bool active) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({'roles.mechanic.isActive': active});
    await logAction('set_mechanic_active', uid, {'isActive': active});
  }

  // ── Seller Management ───────────────────────────────────────────

  static Future<void> setSellerActive(String uid, bool active) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({'roles.seller.isActive': active});
    await logAction('set_seller_active', uid, {'isActive': active});
  }

  static Future<void> approveSellerApplication(String uid) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({'roles.seller.isApproved': true});
    await logAction('approve_seller', uid, {});
  }

  // ── Deliver Management ──────────────────────────────────────────

  static Future<void> setDeliverAvailable(String uid, bool available) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({'roles.deliver.isAvailable': available});
    await logAction('set_deliver_available', uid, {'isAvailable': available});
  }

  // ── Request Management ──────────────────────────────────────────

  static Future<void> cancelRequest(String requestId, String reason) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'cancelled',
      'cancelledBy': 'admin',
      'cancelReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
    await logAction('cancel_request', requestId, {'reason': reason});
  }

  static Future<void> setRequestDisputed(
      String requestId, bool disputed) async {
    await _db.collection('requests').doc(requestId).update(
        {'status': disputed ? 'disputed' : 'completed'});
    await logAction(
        disputed ? 'dispute_request' : 'resolve_dispute', requestId, {});
  }

  // ── App Settings ────────────────────────────────────────────────

  static const Map<String, dynamic> defaultSettings = {
    'maintenanceMode': false,
    'aiChatEnabled': true,
    'maxMechanicRadiusKm': 20,
    'serviceFeePercent': 10.0,
    'minimumFare': 500,
    'supportPhone': '+94 11 234 5678',
    'sellerApprovalRequired': true,
    'deliverApprovalRequired': true,
  };

  static Future<Map<String, dynamic>> getAppSettings() async {
    final doc = await _db.collection('app_settings').doc('global').get();
    return doc.data() ?? defaultSettings;
  }

  static Future<void> updateAppSettings(
      Map<String, dynamic> settings) async {
    await _db
        .collection('app_settings')
        .doc('global')
        .set(settings, SetOptions(merge: true));
    await logAction('update_settings', 'global', settings);
  }

  // ── Streams ─────────────────────────────────────────────────────

  static Stream<QuerySnapshot> usersStream() =>
      _db.collection('users').snapshots();

  static Stream<QuerySnapshot> requestsStream({String? status}) {
    Query q = _db
        .collection('requests')
        .orderBy('createdAt', descending: true);
    if (status != null && status != 'all') {
      q = q.where('status', isEqualTo: status);
    }
    return q.snapshots();
  }

  static Stream<QuerySnapshot> paymentsStream() => _db
      .collection('payments')
      .orderBy('createdAt', descending: true)
      .snapshots();

  static Stream<QuerySnapshot> auditLogsStream() => _db
      .collection('audit_logs')
      .orderBy('timestamp', descending: true)
      .limit(200)
      .snapshots();

  static Stream<QuerySnapshot> appSettingsStream() =>
      _db.collection('app_settings').snapshots();
}
