import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifies the phone number. Handles reCAPTCHA automatically on Web.
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    int? resendToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: kIsWeb ? null : resendToken,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: (FirebaseAuthException e) {
          // Log specific errors for debugging
          print("Firebase Auth Error [${e.code}]: ${e.message}");
          if (e.code == 'too-many-requests') {
            print("Action blocked due to unusual activity. Wait or use a test number.");
          }
          onVerificationFailed(e);
        },
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      print("Error in verifyPhone: $e");
      rethrow;
    }
  }

  /// Verifies the OTP and signs in.
  Future<User?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Error in verifyOtp: $e");
      rethrow;
    }
  }

  /// Fetches user data from Firestore.
  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc : null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }
}
