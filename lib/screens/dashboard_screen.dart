import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../components/dashboard_header.dart';
import '../components/stat_card.dart';
import '../components/quick_action_card.dart';

/// Main dashboard screen with bottom navigation.
/// Renders role-specific content based on the user's role.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'User';
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF5F8FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardContent(role, dark),
          _buildPlaceholderTab('Garage', Icons.garage, dark),
          _buildPlaceholderTab('Payment', Icons.payment, dark),
          _buildPlaceholderTab('Profile', Icons.person, dark),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(dark),
    );
  }

  // ─────────────────────────────────────────────
  //  BOTTOM NAVIGATION BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomNav(bool dark) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111D35) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() {
              _currentIndex = i;
            });
            // Handle navigation based on index
            switch (i) {
              case 0:
                // Dashboard is already handled by IndexedStack
                break;
              case 1:
                Navigator.pushReplacementNamed(context, '/garage');
                break;
              case 2:
                Navigator.pushReplacementNamed(context, '/payment-history');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/profile');
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: dark ? const Color(0xFF111D35) : Colors.white,
          selectedItemColor: dark
              ? AppColors.brandYellow
              : AppColors.primaryBlue,
          unselectedItemColor: dark ? Colors.grey[600] : Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.garage_rounded),
              label: 'Garage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Payment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ROLE ROUTER
  // ─────────────────────────────────────────────
  Widget _buildDashboardContent(String role, bool dark) {
    switch (role) {
      case 'Mechanic':
        return _mechanicDashboard(dark);
      case 'Tow':
        return _towDashboard(dark);
      case 'Seller':
        return _sellerDashboard(dark);
      case 'Driver':
        return _driverDashboard(dark);
      default:
        return _userDashboard(dark);
    }
  }

  // ═════════════════════════════════════════════
  //  1. USER DASHBOARD (default)
  // ═════════════════════════════════════════════
  Widget _userDashboard(bool dark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const DashboardHeader(
            userName: 'Anna',
            role: 'User',
            vehicleInfo: 'Ford F-150',
          ),
          const SizedBox(height: 16),

          // Quick service pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _servicePill(Icons.local_shipping, 'Towing', dark),
                const SizedBox(width: 10),
                _servicePill(Icons.bolt, 'Jump Start', dark),
                const SizedBox(width: 10),
                _servicePill(Icons.tire_repair, 'Flat Tire', dark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Map placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: 48,
                      color: dark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nearby Services Map',
                      style: TextStyle(
                        color: dark ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Report Breakdown header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkSurface : Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '24/7 ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: dark
                          ? AppColors.brandYellow
                          : AppColors.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action cards grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.smart_toy,
                        subtitle: 'VIRTUAL AID',
                        title: 'AI Assistant',
                        color: const Color(0xFF2E7D32),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.build,
                        subtitle: 'ON-SITE REPAIR',
                        title: 'Mechanic',
                        color: const Color(0xFFE65100),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.handyman,
                        subtitle: 'DIY SUPPORT',
                        title: 'Get Tools',
                        color: const Color(0xFF1B5E20),
                        onTap: () {
                          Navigator.pushNamed(context, '/request-tools');
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.phone_in_talk,
                        subtitle: 'LIVE SUPPORT',
                        title: 'Call Support',
                        color: const Color(0xFF1A2940),
                        onTap: () {
                          Navigator.pushNamed(context, '/call-support');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  2. MECHANIC DASHBOARD
  // ═════════════════════════════════════════════
  Widget _mechanicDashboard(bool dark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardHeader(
            userName: 'Anna',
            role: 'Mechanic',
            vehicleInfo: 'AutoFix Pro',
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                StatCard(
                  icon: Icons.work_history,
                  value: '5',
                  label: "Today's Jobs",
                  accentColor: Colors.orange,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.star,
                  value: '4.8',
                  label: 'Rating',
                  accentColor: AppColors.brandYellow,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.account_balance_wallet,
                  value: 'LKR 12K',
                  label: 'Earnings',
                  accentColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Availability toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are Online',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    'ACCEPTING JOBS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section header
          _sectionTitle('Incoming Requests', dark),
          const SizedBox(height: 12),

          // Job request cards
          _jobRequestCard(
            'Engine Won\'t Start',
            'Toyota Corolla • 2.3 km away',
            Icons.car_repair,
            Colors.orange,
            dark,
          ),
          _jobRequestCard(
            'Flat Tire Replacement',
            'Honda Civic • 1.1 km away',
            Icons.tire_repair,
            Colors.blue,
            dark,
          ),
          _jobRequestCard(
            'Battery Jump Start',
            'Suzuki Alto • 3.5 km away',
            Icons.battery_alert,
            Colors.red,
            dark,
          ),
          const SizedBox(height: 20),

          // Quick actions
          _sectionTitle('Quick Actions', dark),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.check_circle,
                    subtitle: 'MANAGE',
                    title: 'Accept Jobs',
                    color: const Color(0xFF2E7D32),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.history,
                    subtitle: 'VIEW',
                    title: 'Job History',
                    color: const Color(0xFF1565C0),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  3. TOW DASHBOARD
  // ═════════════════════════════════════════════
  Widget _towDashboard(bool dark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardHeader(
            userName: 'Anna',
            role: 'Tow',
            vehicleInfo: 'Hino 300',
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                StatCard(
                  icon: Icons.local_shipping,
                  value: '3',
                  label: 'Active Tows',
                  accentColor: Colors.orange,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.route,
                  value: '48 km',
                  label: 'Distance',
                  accentColor: Colors.blue,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.account_balance_wallet,
                  value: 'LKR 18K',
                  label: 'Earnings',
                  accentColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Map placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 40,
                      color: dark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Live Tracking Map',
                      style: TextStyle(
                        color: dark ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pending requests
          _sectionTitle('Pending Tow Requests', dark),
          const SizedBox(height: 12),

          _jobRequestCard(
            'Vehicle Breakdown',
            'Colombo 07 • Sedan • 4.2 km',
            Icons.car_crash,
            Colors.red,
            dark,
          ),
          _jobRequestCard(
            'Accident Recovery',
            'Nugegoda • SUV • 6.1 km',
            Icons.warning_amber,
            Colors.orange,
            dark,
          ),
          const SizedBox(height: 20),

          // Quick actions
          _sectionTitle('Quick Actions', dark),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.play_circle_fill,
                    subtitle: 'NAVIGATE',
                    title: 'Start Tow',
                    color: const Color(0xFFE65100),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.support_agent,
                    subtitle: 'HELP',
                    title: 'Support',
                    color: const Color(0xFF1A2940),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  4. SELLER DASHBOARD
  // ═════════════════════════════════════════════
  Widget _sellerDashboard(bool dark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardHeader(
            userName: 'Anna',
            role: 'Seller',
            vehicleInfo: 'Auto Parts LK',
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                StatCard(
                  icon: Icons.shopping_bag,
                  value: '12',
                  label: "Today's Orders",
                  accentColor: Colors.orange,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.inventory_2,
                  value: '156',
                  label: 'Products',
                  accentColor: Colors.blue,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.trending_up,
                  value: 'LKR 45K',
                  label: 'Revenue',
                  accentColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent orders
          _sectionTitle('Recent Orders', dark),
          const SizedBox(height: 12),

          _orderCard(
            'Brake Pads Set',
            'Order #1042 • Colombo 05',
            'Processing',
            Colors.orange,
            dark,
          ),
          _orderCard(
            'Engine Oil 5W-30',
            'Order #1041 • Dehiwala',
            'Shipped',
            Colors.blue,
            dark,
          ),
          _orderCard(
            'Air Filter – Toyota',
            'Order #1040 • Kandy',
            'Delivered',
            Colors.green,
            dark,
          ),
          const SizedBox(height: 20),

          // Quick actions
          _sectionTitle('Quick Actions', dark),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.add_box,
                        subtitle: 'INVENTORY',
                        title: 'Add Product',
                        color: const Color(0xFF2E7D32),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.list_alt,
                        subtitle: 'MANAGE',
                        title: 'View Orders',
                        color: const Color(0xFF1565C0),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.analytics,
                        subtitle: 'INSIGHTS',
                        title: 'Analytics',
                        color: const Color(0xFF6A1B9A),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.chat_bubble,
                        subtitle: 'CUSTOMERS',
                        title: 'Messages',
                        color: const Color(0xFFE65100),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  5. DRIVER DASHBOARD
  // ═════════════════════════════════════════════
  Widget _driverDashboard(bool dark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardHeader(
            userName: 'Anna',
            role: 'Driver',
            vehicleInfo: 'Colombo Zone',
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                StatCard(
                  icon: Icons.delivery_dining,
                  value: '8',
                  label: 'Deliveries',
                  accentColor: Colors.orange,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.route,
                  value: '32 km',
                  label: 'Distance',
                  accentColor: Colors.blue,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.account_balance_wallet,
                  value: 'LKR 8K',
                  label: 'Earnings',
                  accentColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Current delivery
          _sectionTitle('Active Delivery', dark),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dark
                      ? [const Color(0xFF1E3A5F), const Color(0xFF15294A)]
                      : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.blue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Brake Pads – Toyota',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: dark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Deliver to: Colombo 07 • 3.2 km',
                              style: TextStyle(
                                color: dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 6,
                      backgroundColor: dark
                          ? Colors.grey[800]
                          : Colors.blue.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'En Route • ETA 12 min',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[300],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pending deliveries
          _sectionTitle('Pending Deliveries', dark),
          const SizedBox(height: 12),

          _jobRequestCard(
            'Engine Oil 5W-30',
            'Dehiwala • 5.4 km away',
            Icons.oil_barrel,
            Colors.amber,
            dark,
          ),
          _jobRequestCard(
            'Air Filter Set',
            'Mount Lavinia • 8.1 km away',
            Icons.filter_alt,
            Colors.teal,
            dark,
          ),
          const SizedBox(height: 20),

          // Quick actions
          _sectionTitle('Quick Actions', dark),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.check_circle,
                    subtitle: 'ACCEPT',
                    title: 'New Delivery',
                    color: const Color(0xFF2E7D32),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.map,
                    subtitle: 'NAVIGATE',
                    title: 'View Route',
                    color: const Color(0xFF1565C0),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  SHARED HELPER WIDGETS
  // ═════════════════════════════════════════════

  /// Service pill chip (User dashboard)
  Widget _servicePill(IconData icon, String label, bool dark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: dark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section title with left padding
  Widget _sectionTitle(String text, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: dark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  /// Job / request card (Mechanic, Tow, Driver dashboards)
  Widget _jobRequestCard(
    String title,
    String subtitle,
    IconData icon,
    Color accent,
    bool dark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: dark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: dark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  /// Order card (Seller dashboard)
  Widget _orderCard(
    String title,
    String subtitle,
    String status,
    Color statusColor,
    bool dark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: dark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shopping_bag, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder tab for non-dashboard tabs
  Widget _buildPlaceholderTab(String label, IconData icon, bool dark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 60,
            color: dark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 13,
              color: dark ? Colors.grey[700] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
