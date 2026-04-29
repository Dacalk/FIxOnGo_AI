import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await AdminService.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      final isAdmin = await AdminService.isCurrentUserAdmin();
      if (!mounted) return;
      if (isAdmin) {
        Navigator.of(context).pushReplacementNamed('/admin');
      } else {
        await AdminService.signOut();
        setState(() => _error = 'Access denied. This account does not have admin privileges.');
      }
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', '').replaceAll('[firebase_auth/', '').replaceAll(']', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Row(
        children: [
          // ── Left branding panel ──
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D1626), Color(0xFF0B1120)],
                ),
              ),
              child: Stack(
                children: [
                  // Background grid pattern
                  Positioned.fill(
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A4DBE),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A4DBE).withAlpha(102),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shield_rounded,
                              color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'FixOnGo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A4DBE).withAlpha(51),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF1A4DBE).withAlpha(102)),
                          ),
                          child: const Text(
                            'ADMIN CONSOLE',
                            style: TextStyle(
                              color: Color(0xFF90CAF9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        _InfoRow(Icons.people_rounded, 'Manage all users & roles'),
                        const SizedBox(height: 12),
                        _InfoRow(Icons.assignment_rounded, 'Monitor service requests'),
                        const SizedBox(height: 12),
                        _InfoRow(Icons.payments_rounded, 'Track payments & revenue'),
                        const SizedBox(height: 12),
                        _InfoRow(Icons.shield_rounded, 'Privacy-protected operations'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right login panel ──
          Container(
            width: 420,
            color: const Color(0xFF111D35),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to access the admin console',
                        style: TextStyle(
                          color: Colors.white.withAlpha(127),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email
                      Text('Email', style: TextStyle(color: Colors.white.withAlpha(178), fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'admin@fixongo.app',
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.white38, size: 20),
                        ),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      Text('Password', style: TextStyle(color: Colors.white.withAlpha(178), fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: const TextStyle(color: Colors.white),
                        onFieldSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white38, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),

                      // Error
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF5350).withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF5350).withAlpha(76)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFEF9A9A), size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 13))),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _loading ? null : _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1A4DBE),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'FixOnGo Admin Console v1.0',
                          style: TextStyle(color: Colors.white.withAlpha(51), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF1A4DBE), size: 18),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(7)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
