import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme_provider.dart';
import '../components/seller_bottom_nav.dart';

class MechanicShopScreen extends StatefulWidget {
  final bool isEmbedded;
  final String? role;
  const MechanicShopScreen({super.key, this.isEmbedded = false, this.role});

  @override
  State<MechanicShopScreen> createState() => _MechanicShopScreenState();
}

class _MechanicShopScreenState extends State<MechanicShopScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late TabController _tabController;

  final List<String> _categories = [
    'All',
    'Tools',
    'Parts',
    'Accessories',
    'Oils',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF5F8FF);
    final titleColor = dark ? Colors.white : Colors.black87;

    // Floating action button for adding new items
    final fab = FloatingActionButton.extended(
      heroTag: 'mechanic_shop_fab',
      onPressed: () => Navigator.pushNamed(context, '/add-product'),
      backgroundColor: AppColors.primaryBlue,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Add Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (only shown when embedded)
        if (widget.isEmbedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Workshop',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: titleColor)),
                    const SizedBox(height: 2),
                    Text('Manage your tools & parts inventory',
                        style: TextStyle(
                            fontSize: 13,
                            color: dark ? Colors.grey[400] : Colors.grey[600])),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add-product'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Category Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            dividerHeight: 0,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            labelColor: Colors.white,
            unselectedLabelColor: dark ? Colors.grey[400] : Colors.grey[600],
            tabs: _categories.map((c) => Text(c)).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Product List
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((cat) {
              Query query = _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('products')
                  .orderBy('createdAt', descending: true);
              if (cat != 'All') {
                query = query.where('category', isEqualTo: cat);
              }

              return StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return _emptyState(dark, cat);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final p = docs[i].data() as Map<String, dynamic>;
                      return _productCard(docs[i].id, p, dark, user.uid);
                    },
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Stack(
        children: [
          body,
          Positioned(
            bottom: 16,
            right: 16,
            child: fab,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('My Workshop',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? Colors.white : Colors.black,
      ),
      floatingActionButton: fab,
      body: body,
    );
  }

  Widget _emptyState(bool dark, String cat) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handyman_outlined,
              size: 72, color: dark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            cat == 'All' ? 'Your workshop is empty' : 'No $cat items yet',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: dark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap "Add Item" to add tools, parts, or accessories.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
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

  Widget _productCard(
      String id, Map<String, dynamic> p, bool dark, String uid) {
    final name = p['name'] ?? 'Product';
    final price = p['price'] ?? 0.0;
    final category = p['category'] ?? 'Tools';
    final image = p['imageUrl'] as String?;
    final stock = p['stockCount'] ?? 0;
    final description = p['description'] ?? '';

    final stockColor =
        stock > 5 ? Colors.green : (stock > 0 ? Colors.orange : Colors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(7),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        children: [
          // ── Main Info Row ──
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.pushNamed(context, '/add-product',
                arguments: {'id': id, ...p}),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Image / Icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: dark ? Colors.grey[800] : Colors.grey[100],
                      child: image != null && image.isNotEmpty
                          ? Image.network(image, fit: BoxFit.cover)
                          : Icon(
                              category == 'Tools'
                                  ? Icons.handyman
                                  : category == 'Parts'
                                      ? Icons.settings
                                      : category == 'Oils'
                                          ? Icons.opacity
                                          : Icons.inventory_2,
                              color: Colors.grey[400],
                              size: 32),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: dark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 2),
                        Text(category,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                        if (description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: dark
                                        ? Colors.grey[500]
                                        : Colors.grey[600])),
                          ),
                      ],
                    ),
                  ),
                  // Price & Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rs. ${price.toString()}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit',
                            onPressed: () => Navigator.pushNamed(
                                context, '/add-product',
                                arguments: {'id': id, ...p}),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Row: Stock + Request Delivery ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: dark ? Colors.grey[900] : Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Stock Adjuster
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stockColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (stock > 0) {
                            await _firestore
                                .collection('users')
                                .doc(uid)
                                .collection('products')
                                .doc(id)
                                .update({'stockCount': stock - 1});
                          }
                        },
                        child: Icon(Icons.remove_circle_outline,
                            size: 20, color: stockColor),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Stock: $stock',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: stockColor)),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await _firestore
                              .collection('users')
                              .doc(uid)
                              .collection('products')
                              .doc(id)
                              .update({'stockCount': stock + 1});
                        },
                        child: Icon(Icons.add_circle_outline,
                            size: 20, color: stockColor),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Request Delivery button
                ElevatedButton.icon(
                  onPressed: () => _showRequestDeliverySheet(p, uid),
                  icon: const Icon(Icons.delivery_dining, size: 14),
                  label: const Text('Request Delivery',
                      style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
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

  // ── Request Delivery Bottom Sheet ──────────────────────────────────────
  void _showRequestDeliverySheet(Map<String, dynamic> product, String uid) {
    final dark = isDarkMode(context);
    final pickupCtrl = TextEditingController();
    final dropCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delivery_dining,
                              color: Colors.orange, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Request Delivery',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                product['name'] ?? 'Item',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pickup Address
                    _sheetLabel('Pickup Address', dark),
                    TextFormField(
                      controller: pickupCtrl,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                      decoration:
                          _sheetInputDeco('Where should driver pick up?', dark),
                    ),
                    const SizedBox(height: 16),

                    // Drop-off Address
                    _sheetLabel('Drop-off Address', dark),
                    TextFormField(
                      controller: dropCtrl,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                      decoration:
                          _sheetInputDeco('Delivery destination address', dark),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    _sheetLabel('Notes (optional)', dark),
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration:
                          _sheetInputDeco('Any special instructions...', dark),
                    ),
                    const SizedBox(height: 28),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: sending
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                setSheetState(() => sending = true);

                                // ── Find nearest available delivery driver ──
                                String? nearestDriverUid;
                                String? nearestDriverName;
                                try {
                                  final driverSnap = await FirebaseFirestore.instance
                                      .collection('users')
                                      .where('roles.delivery', isNotEqualTo: null)
                                      .get();

                                  for (final doc in driverSnap.docs) {
                                    final roles = doc.data()['roles'] as Map<String, dynamic>? ?? {};
                                    final delivData = roles['delivery'] as Map<String, dynamic>? ?? {};
                                    final isAvailable = delivData['isAvailable'] as bool? ?? true;
                                    final isOnline = delivData['isOnline'] as bool? ?? true;
                                    if (!isAvailable || !isOnline) continue;
                                    nearestDriverUid = doc.id;
                                    nearestDriverName = delivData['fullName'] as String? ?? 'Driver';
                                    break; // First available is fine; could sort by distance later
                                  }
                                } catch (e) {
                                  debugPrint('[MechanicShop] Error finding driver: $e');
                                }

                                debugPrint('[MechanicShop] senderId=$uid assignedProviderId=$nearestDriverUid');

                                // Get mechanic info
                                final userDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .get();
                                final uData = userDoc.data() ?? {};
                                final rolesRaw = uData['roles'];
                                final mData = rolesRaw is Map
                                    ? (rolesRaw['mechanic'] as Map? ?? {})
                                    : <String, dynamic>{};
                                final senderName = mData['fullName'] ??
                                    uData['fullName'] ??
                                    'Mechanic';

                                debugPrint('[MechanicShop] Creating delivery request: '
                                    'assignedProviderId=$nearestDriverUid '
                                    'targetRole=delivery '
                                    'status=pending');

                                await FirebaseFirestore.instance
                                    .collection('deliveries')
                                    .add({
                                  'sourceRole': 'mechanic',
                                  'targetRole': 'delivery',
                                  'senderId': uid,
                                  'senderName': senderName,
                                  'assignedProviderId': nearestDriverUid,  // Nearest driver UID (or null)
                                  'driverName': nearestDriverName,
                                  'itemName': product['name'] ?? 'Item',
                                  'itemCategory':
                                      product['category'] ?? 'Tools',
                                  'itemPrice': product['price'] ?? 0,
                                  'pickupAddress': pickupCtrl.text.trim(),
                                  'dropAddress': dropCtrl.text.trim(),
                                  'pickupLat': 6.9271, // dummy
                                  'pickupLng': 79.8612,
                                  'dropLat': 6.8900,
                                  'dropLng': 79.8500,
                                  'notes': notesCtrl.text.trim(),
                                  'status': 'pending',
                                  'earnings': _estimateFee(
                                      pickupCtrl.text, dropCtrl.text),
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                                setSheetState(() => sending = false);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        '🚚 Delivery request sent! Nearby drivers will be notified.'),
                                    backgroundColor: Colors.green,
                                  ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: sending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Send Delivery Request',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Estimate a rough delivery fee (placeholder — replace with real distance calc)
  num _estimateFee(String pickup, String drop) {
    // Simple heuristic: 200 base + 50 per city word difference
    return 350;
  }

  Widget _sheetLabel(String label, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: dark ? Colors.grey[400] : Colors.grey[700])),
    );
  }

  InputDecoration _sheetInputDeco(String hint, bool dark) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: dark ? AppColors.darkBackground : Colors.grey[100],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
