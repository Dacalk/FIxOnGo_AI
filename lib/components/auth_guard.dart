import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A widget that protects routes by checking the authentication state.
/// If the user is not authenticated, it redirects them to the login screen.
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // userChanges is more comprehensive than authStateChanges
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        // While checking auth state, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingScreen();
        }

        final User? user = snapshot.data;

        // If user is authenticated, render the child widget
        if (user != null) {
          return child;
        }

        // If not authenticated, we redirect to login.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null &&
              (ModalRoute.of(context)?.isCurrent ?? false)) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });

        return _loadingScreen();
      },
    );
  }

  Widget _loadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1A4DBE),
        ),
      ),
    );
  }
}
