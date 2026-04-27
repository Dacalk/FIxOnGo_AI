import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Navigation items definition
class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}

const _navItems = [
  _NavItem(Icons.dashboard_rounded,      'Dashboard',  '/admin'),
  _NavItem(Icons.people_rounded,         'Users',      '/admin/users'),
  _NavItem(Icons.build_rounded,          'Mechanics',  '/admin/mechanics'),
  _NavItem(Icons.store_rounded,          'Sellers',    '/admin/sellers'),
  _NavItem(Icons.delivery_dining_rounded,'Delivers',   '/admin/delivers'),
  _NavItem(Icons.assignment_rounded,     'Requests',   '/admin/requests'),
  _NavItem(Icons.payments_rounded,       'Payments',   '/admin/payments'),
  _NavItem(Icons.settings_rounded,       'Settings',   '/admin/settings'),
  _NavItem(Icons.history_rounded,        'Audit Log',  '/admin/audit'),
];

/// Main shell that wraps every admin page with the sidebar and top bar.
/// On desktop (≥900px): persistent sidebar.
/// On tablet (600–899px): icon-only rail.
/// On mobile (<600px): hamburger drawer.
class AdminShell extends StatelessWidget {
  final String activeRoute;
  final Widget child;

  const AdminShell({
    super.key,
    required this.activeRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _DesktopLayout(activeRoute: activeRoute, child: child);
        } else if (constraints.maxWidth >= 600) {
          return _RailLayout(activeRoute: activeRoute, child: child);
        } else {
          return _MobileLayout(activeRoute: activeRoute, child: child);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  DESKTOP — full sidebar
// ─────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final String activeRoute;
  final Widget child;
  const _DesktopLayout({required this.activeRoute, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Row(
        children: [
          _Sidebar(activeRoute: activeRoute, expanded: true),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: _titleFor(activeRoute)),
                Expanded(
                  child: Container(
                    color: const Color(0xFF0B1120),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TABLET — icon-only rail
// ─────────────────────────────────────────────────────────
class _RailLayout extends StatelessWidget {
  final String activeRoute;
  final Widget child;
  const _RailLayout({required this.activeRoute, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Row(
        children: [
          _Sidebar(activeRoute: activeRoute, expanded: false),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: _titleFor(activeRoute)),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  MOBILE — drawer
// ─────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final String activeRoute;
  final Widget child;
  const _MobileLayout({required this.activeRoute, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0D1626),
        child: _SidebarContent(activeRoute: activeRoute, expanded: true),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1626),
        title: Text(_titleFor(activeRoute),
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [_LogoutButton()],
      ),
      body: child,
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SIDEBAR WIDGET
// ─────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final String activeRoute;
  final bool expanded;
  const _Sidebar({required this.activeRoute, required this.expanded});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? 240 : 72,
      color: const Color(0xFF0D1626),
      child: _SidebarContent(activeRoute: activeRoute, expanded: expanded),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final String activeRoute;
  final bool expanded;
  const _SidebarContent({required this.activeRoute, required this.expanded});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 0),
          alignment: expanded ? Alignment.centerLeft : Alignment.center,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A4DBE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
              ),
              if (expanded) ...[
                const SizedBox(width: 10),
                const Text('FixOnGo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ],
          ),
        ),

        // Nav items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: _navItems.map((item) => _NavTile(
              item: item,
              isActive: activeRoute == item.route,
              expanded: expanded,
            )).toList(),
          ),
        ),

        // Bottom — user info + logout
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
          ),
          child: _LogoutTile(expanded: expanded),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool expanded;
  const _NavTile({required this.item, required this.isActive, required this.expanded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Tooltip(
        message: expanded ? '' : item.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (Navigator.canPop(context)) Navigator.pop(context); // close drawer if open
            Navigator.pushReplacementNamed(context, item.route);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF1A4DBE).withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: const Color(0xFF1A4DBE).withValues(alpha: 0.5))
                  : Border.all(color: Colors.transparent),
              boxShadow: isActive ? [
                BoxShadow(
                  color: const Color(0xFF1A4DBE).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: Row(
              mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isActive ? const Color(0xFF90CAF9) : Colors.white38,
                  size: 20,
                ),
                if (expanded) ...[
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white60,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final bool expanded;
  const _LogoutTile({required this.expanded});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/admin/login');
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1A4DBE).withValues(alpha: 0.3),
              child: Text(
                (user?.email?.isNotEmpty == true)
                    ? user!.email![0].toUpperCase()
                    : 'A',
                style: const TextStyle(color: Color(0xFF90CAF9), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            if (expanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.email ?? 'Admin',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text('Administrator', style: TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.logout_rounded, color: Colors.white30, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1626).withValues(alpha: 0.95), // Slight transparency for modern feel
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const Spacer(),

          // Quick Actions (Hidden on very small screens)
          if (MediaQuery.of(context).size.width > 700) ...[
            _QuickActionButton(icon: Icons.person_add_rounded, label: 'Add User'),
            const SizedBox(width: 12),
            _QuickActionButton(icon: Icons.build_rounded, label: 'Add Mechanic'),
            const SizedBox(width: 12),
            _QuickActionButton(icon: Icons.send_rounded, label: 'Notify'),
            const SizedBox(width: 24),
          ],

          // Notification Bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 24),
                onPressed: () {},
                splashRadius: 20,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF5350), shape: BoxShape.circle),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          Container(height: 32, width: 1, color: Colors.white10),
          const SizedBox(width: 16),

          _LogoutButton(),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {}, // Future Implementation
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFEF9A9A),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/admin/login');
        }
      },
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Logout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

// Helper
String _titleFor(String route) {
  switch (route) {
    case '/admin': return 'Dashboard';
    case '/admin/users': return 'User Management';
    case '/admin/mechanics': return 'Mechanic Management';
    case '/admin/sellers': return 'Seller Management';
    case '/admin/delivers': return 'Deliver Management';
    case '/admin/requests': return 'Service Requests';
    case '/admin/payments': return 'Payments';
    case '/admin/settings': return 'App Settings';
    case '/admin/audit': return 'Audit Log';
    default: return 'Admin';
  }
}
