import 'package:flutter/material.dart';
import 'components/admin_guard.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/admin/admin_dashboard_page.dart';
import 'screens/admin/admin_users_page.dart';
import 'screens/admin/admin_mechanics_page.dart';
import 'screens/admin/admin_sellers_page.dart';
import 'screens/admin/admin_delivers_page.dart';
import 'screens/admin/admin_requests_page.dart';
import 'screens/admin/admin_payments_page.dart';
import 'screens/admin/admin_settings_page.dart';
import 'screens/admin/admin_audit_page.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FixOnGo Admin',
      theme: _adminTheme(),
      initialRoute: '/admin/login',
      routes: {
        '/admin/login': (_) => const AdminLoginScreen(),
        '/admin': (_) => AdminGuard(
              child: AdminShell(
                activeRoute: '/admin',
                child: const AdminDashboardPage(),
              ),
            ),
        '/admin/users': (_) => AdminGuard(
              child: AdminShell(
                activeRoute: '/admin/users',
                child: const AdminUsersPage(),
              ),
            ),
        '/admin/mechanics': (_) => AdminGuard(
              child: AdminShell(
                activeRoute: '/admin/mechanics',
                child: const AdminMechanicsPage(),
              ),
            ),
        '/admin/sellers': (_) => AdminGuard(
              child: AdminShell(
                activeRoute: '/admin/sellers',
                child: const AdminSellersPage(),
              ),
            ),
        '/admin/delivers': (_) => AdminGuard(
              child: AdminShell(
                activeRoute: '/admin/delivers',
                child: const AdminDeliversPage(),
              ),
            ),
        '/admin/requests': (_) => AdminGuard(
              child: AdminShell(
                activeRoute: '/admin/requests',
                child: const AdminRequestsPage(),
              ),
            ),
        '/admin/payments': (_) => AdminGuard(
              child: AdminShell(
                activeRoute: '/admin/payments',
                child: const AdminPaymentsPage(),
              ),
            ),
        '/admin/settings': (_) => AdminGuard(
              child: AdminShell(
                activeRoute: '/admin/settings',
                child: const AdminSettingsPage(),
              ),
            ),
        '/admin/audit': (_) => AdminGuard(
              child: AdminShell(
                activeRoute: '/admin/audit',
                child: const AdminAuditPage(),
              ),
            ),
      },
    );
  }

  ThemeData _adminTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1A4DBE),
        secondary: Color(0xFFFFC107),
        surface: Color(0xFF111D35),
        error: Color(0xFFEF5350),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1626),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111D35),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111D35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1A4DBE), width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }
}
