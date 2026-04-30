import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';

/// Guards admin routes. Requires the user to be:
///   1. Signed in via Firebase Auth
///   2. Have `roles.admin` in their Firestore user document
class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _AdminLoader();
        }

        if (authSnap.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/admin/login');
            }
          });
          return const _AdminLoader();
        }

        return FutureBuilder<bool>(
          future: AdminService.isCurrentUserAdmin(),
          builder: (context, snap) {
            if (!snap.hasData) return const _AdminLoader();
            if (snap.data == true) return child;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/admin/login');
              }
            });
            return const _AdminLoader();
          },
        );
      },
    );
  }
}

class _AdminLoader extends StatelessWidget {
  const _AdminLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0B1120),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1A4DBE)),
            SizedBox(height: 16),
            Text(
              'FixOnGo Admin',
              style: TextStyle(color: Colors.white38, fontSize: 13,
                  letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
