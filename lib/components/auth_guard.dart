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
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While checking auth state, show a loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is authenticated, render the child widget
        if (snapshot.hasData) {
          return child;
        }

        // If not authenticated, redirect to login
        // We use addPostFrameCallback to avoid navigation during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        });

        // Show loading while redirecting
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
