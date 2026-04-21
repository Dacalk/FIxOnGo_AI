import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? dotenv.env['GOOGLE_WEB_CLIENT_ID'] : null,
  );

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb &&
          (dotenv.env['GOOGLE_WEB_CLIENT_ID'] == null ||
              dotenv.env['GOOGLE_WEB_CLIENT_ID']!.isEmpty)) {
        throw Exception(
            "Web Client ID missing. Please add GOOGLE_WEB_CLIENT_ID to your .env file.");
      }
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // user cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      // Update Firebase Auth profile with Google photo if missing
      if (user != null && (user.photoURL == null || user.photoURL!.isEmpty)) {
        await user.updatePhotoURL(googleUser.photoUrl);
      }
      if (user != null &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(googleUser.displayName);
      }

      return user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
