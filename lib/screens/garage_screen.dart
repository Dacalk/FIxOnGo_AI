import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_provider.dart';
import '../models/vehicle.dart';
import '../models/inventory_item.dart';
import '../services/vehicle_service.dart';
import '../services/inventory_service.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  String? _role;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final roles = doc.data()?['roles'] as Map<String, dynamic>? ?? {};
        print("Garage Debug: User roles map: $roles");
        if (roles.containsKey('mechanic')) {
          _role = 'mechanic';
        } else {
          _role = 'user';
        }
        print("Garage Debug: Detected role: $_role");
      } else {
        print("Garage Debug: User document does not exist");
      }
    } catch (e) {
      print("Error fetching role: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF8F9FA);
    final topBarColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;

    if (_isLoadingRole) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isMechanic = _role == 'mechanic';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isMechanic ? 'Inventory Management' : 'My Garage',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: dark ? AppColors.darkSurface : Colors.grey[100],
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 18,
                color: dark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: isMechanic ? _buildInventoryContent(dark, titleColor) : _buildGarageContent(dark, titleColor),
      bottomNavigationBar: _buildBottomNav(context, dark),
    );
  }

  Widget _buildGarageContent(bool dark, Color titleColor) {
    final vehicleService = VehicleService();
    final user = FirebaseAuth.instance.currentUser!;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? const Color(0xFF1E2836) : Colors.white;
    final borderColor = dark ? Colors.transparent : Colors.grey[200]!;

    return StreamBuilder<List<Vehicle>>(
      stream: vehicleService.getVehicles(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final vehicles = snapshot.data ?? [];
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview', style: TextStyle(fontSize: 13, color: titleColor)),
              const SizedBox(height: 6),
              Text('Total Vehicles : ${vehicles.length.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
              const SizedBox(height: 24),
              _buildAddButton(dark, 'Add New Vehicle', () => Navigator.pushNamed(context, '/add-vehicle')),
              const SizedBox(height: 32),
              if (vehicles.isEmpty) _buildEmptyState(subColor, "No vehicles added yet.")
              else ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return _buildVehicleCard(context, vehicle, dark, cardBg, borderColor, titleColor, subColor);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryContent(bool dark, Color titleColor) {
    final inventoryService = InventoryService();
    final user = FirebaseAuth.instance.currentUser!;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? const Color(0xFF1E2836) : Colors.white;
    final borderColor = dark ? Colors.transparent : Colors.grey[200]!;

    return StreamBuilder<List<InventoryItem>>(
      stream: inventoryService.getInventory(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final items = snapshot.data ?? [];
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shop Statistics', style: TextStyle(fontSize: 13, color: titleColor)),
              const SizedBox(height: 6),
              Text('Total Products : ${items.length.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
              const SizedBox(height: 24),
              _buildAddButton(dark, 'Add New Product', () => Navigator.pushNamed(context, '/add-inventory-item')),
              const SizedBox(height: 32),
              if (items.isEmpty) _buildEmptyState(subColor, "Your shop is empty.")
              else ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildInventoryCard(context, item, dark, cardBg, borderColor, titleColor, subColor);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddButton(bool dark, String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? AppColors.brandYellow : AppColors.primaryBlue,
          foregroundColor: dark ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color color, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle, bool dark, Color cardBg, Color borderColor, Color titleColor, Color subColor) {
    return _buildCardBase(
      dark: dark,
      cardBg: cardBg,
      borderColor: borderColor,
      icon: Icons.directions_car,
      title: '${vehicle.make} ${vehicle.model}',
      subtitle: '${vehicle.year} • ${vehicle.plateNumber}',
      badgeText: vehicle.isPrimary ? 'PRIMARY' : 'ACTIVE',
      badgeColor: vehicle.isPrimary ? AppColors.brandYellow : Colors.green,
      actions: [
        _buildAction(Icons.edit, 'Edit', () => Navigator.pushNamed(context, '/add-vehicle', arguments: vehicle), dark),
        const SizedBox(width: 12),
        _buildAction(null, 'Remove', () => _showDeleteDialog(context, 'vehicle', vehicle.id), dark, isDanger: true),
      ],
      titleColor: titleColor,
      subColor: subColor,
    );
  }

  Widget _buildInventoryCard(BuildContext context, InventoryItem item, bool dark, Color cardBg, Color borderColor, Color titleColor, Color subColor) {
    return _buildCardBase(
      dark: dark,
      cardBg: cardBg,
      borderColor: borderColor,
      icon: Icons.inventory_2,
      imageUrl: item.imageUrl,
      title: item.name,
      subtitle: 'Qty: ${item.quantity} • Rs. ${item.price}',
      badgeText: item.quantity > 0 ? 'IN STOCK' : 'OUT OF STOCK',
      badgeColor: item.quantity > 0 ? Colors.green : Colors.red,
      actions: [
        _buildAction(Icons.edit, 'Edit', () => Navigator.pushNamed(context, '/add-inventory-item', arguments: item), dark),
        const SizedBox(width: 12),
        _buildAction(null, 'Remove', () => _showDeleteDialog(context, 'item', item.id), dark, isDanger: true),
      ],
      titleColor: titleColor,
      subColor: subColor,
    );
  }

  Widget _buildCardBase({
    required bool dark,
    required Color cardBg,
    required Color borderColor,
    required IconData icon,
    String? imageUrl,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required List<Widget> actions,
    required Color titleColor,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: dark ? null : Border.all(color: borderColor),
        boxShadow: dark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1E3350) : Colors.grey[300], 
              borderRadius: BorderRadius.circular(12),
              image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
            ),
            child: imageUrl == null ? Icon(icon, size: 40, color: dark ? Colors.white54 : Colors.grey[500]) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor, height: 1.2))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text(badgeText, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subColor)),
                const SizedBox(height: 12),
                Row(children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(IconData? icon, String text, VoidCallback onTap, bool dark, {bool isDanger = false}) {
    final bgColor = dark ? const Color(0xFF2A3A50) : Colors.grey[200]!;
    final textColor = isDanger ? Colors.red[400]! : (dark ? Colors.white : Colors.black87);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 12, color: textColor), const SizedBox(width: 4)],
            Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String type, String id) {
    final user = FirebaseAuth.instance.currentUser!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Remove $type"),
        content: Text("Are you sure you want to remove this $type?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (type == 'vehicle') VehicleService().deleteVehicle(user.uid, id);
              else InventoryService().deleteItem(user.uid, id);
              Navigator.pop(context);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A2432) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, Icons.home_rounded, 'Dashboard', false, dark, '/dashboard'),
            _navItem(context, Icons.garage_rounded, _role == 'mechanic' ? 'Inventory' : 'Garage', true, dark, '/garage'),
            _navItem(context, Icons.payments_rounded, 'Payment', false, dark, '/payment-history'),
            _navItem(context, Icons.person_rounded, 'Profile', false, dark, '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool isActive, bool dark, String routeName) {
    final color = isActive ? AppColors.primaryBlue : (dark ? Colors.grey[500]! : Colors.grey[400]!);
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, routeName);
            }
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
