import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../theme_provider.dart';
import '../components/seller_bottom_nav.dart';

class MechanicShopScreen extends StatefulWidget {
  final bool isEmbedded;
  final String? role;
  const MechanicShopScreen({super.key, this.isEmbedded = false, this.role});

  @override
  State<MechanicShopScreen> createState() => _MechanicShopScreenState();
}

class _MechanicShopScreenState extends State<MechanicShopScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Not logged in")));

    final dark = isDarkMode(context);

    final content = StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(dark);
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final product = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            return _productCard(id, product, dark);
          },
        );
      },
    );

    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/add-product'),
          backgroundColor: AppColors.primaryBlue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Product',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor:
          dark ? AppColors.darkBackground : const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('My Shop Inventory',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? Colors.white : Colors.black,
      ),
      bottomNavigationBar: _bottomNav(dark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-product'),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: content,
    );
  }

  Widget _emptyState(bool dark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 80, color: dark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Your shop is empty',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: dark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            'Add tools or parts to start selling.',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add-product'),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Product',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(String id, Map<String, dynamic> p, bool dark) {
    final name = p['name'] ?? 'Product';
    final price = p['price'] ?? 0.0;
    final category = p['category'] ?? 'Tools';
    final image = p['imageUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Row(
              children: [
                // Product Image
                Container(
                  width: 100,
                  height: 100,
                  color: dark ? Colors.grey[800] : Colors.grey[100],
                  child: image != null && image.isNotEmpty
                      ? Builder(
                          builder: (context) {
                            try {
                              if (image.contains('base64,')) {
                                final b64 = image.split(',')[1];
                                final bytes = base64Decode(b64);
                                return Image.memory(bytes, fit: BoxFit.cover);
                              }
                            } catch (_) {}
                            return Image.network(image, fit: BoxFit.cover);
                          },
                        )
                      : Icon(Icons.handyman_outlined,
                          color: Colors.grey[400], size: 40),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(category,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Rs. ${price.toString()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Stock: ${p['stockCount'] ?? 0}',
                            style: TextStyle(
                              fontSize: 13,
                              color: (p['stockCount'] ?? 0) > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => Navigator.pushNamed(
                          context, '/add-product',
                          arguments: {'id': id, ...p}),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(id),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Text('Deleting product...'),
                      ],
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
              await _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .collection('products')
                  .doc(id)
                  .delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BOTTOM NAVIGATION BAR
  //  For Seller: uses the shared SellerBottomNav.
  //  For Mechanic and others: uses the custom 3-tab nav.
  // ─────────────────────────────────────────────
  Widget _bottomNav(bool dark) {
    // Sellers use the shared 4-tab component
    if (widget.role?.toLowerCase() == 'seller') {
      return SellerBottomNav(currentIndex: 1, role: widget.role);
    }

    // Mechanic / other roles: 3-tab nav (Dashboard, Shop, Vehicles, Profile)
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
          currentIndex: 1, // Shop is active
          onTap: (i) {
            switch (i) {
              case 0:
                Navigator.pushReplacementNamed(context, '/dashboard',
                    arguments: widget.role ?? 'Mechanic');
                break;
              case 1:
                break; // already here
              case 2:
                Navigator.pushReplacementNamed(context, '/garage');
                break;
              case 3:
                Navigator.pushReplacementNamed(context, '/profile',
                    arguments: widget.role ?? 'Mechanic');
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: dark ? const Color(0xFF111D35) : Colors.white,
          selectedItemColor:
              dark ? AppColors.brandYellow : AppColors.primaryBlue,
          unselectedItemColor: dark ? Colors.grey[600] : Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag), label: 'Shop'),
            BottomNavigationBarItem(
                icon: Icon(Icons.garage_rounded), label: 'Vehicles'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
