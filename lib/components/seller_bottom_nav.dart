import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Shared bottom navigation bar for all Seller-role screens.
///
/// Tabs:
///   0 – Dashboard
///   1 – Shop
///   2 – Messages
///   3 – Profile
///
/// Pass [currentIndex] to highlight the active tab.
/// Pass [role] if you want to carry it forward when navigating.
class SellerBottomNav extends StatelessWidget {
  final int currentIndex;
  final String? role;

  const SellerBottomNav({
    super.key,
    required this.currentIndex,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111D35) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(((dark ? 0.3 : 0.08) * 255).toInt()),
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
          currentIndex: currentIndex < 0 ? 0 : currentIndex,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          onTap: (i) => _onTap(context, i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: dark ? const Color(0xFF111D35) : Colors.white,
          selectedItemColor:
              dark ? AppColors.brandYellow : AppColors.primaryBlue,
          unselectedItemColor:
              dark ? Colors.grey[600] : Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_rounded),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded),
              label: 'Messages',
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

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return; // Already here

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard',
            arguments: role ?? 'seller');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/mechanic-shop');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/seller-inbox');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile',
            arguments: role ?? 'seller');
        break;
    }
  }
}
