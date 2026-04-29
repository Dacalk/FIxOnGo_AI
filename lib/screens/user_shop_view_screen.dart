import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_provider.dart';
import '../services/provider_service.dart';
import '../services/location_service.dart';
import 'package:latlong2/latlong.dart';

class UserShopViewScreen extends StatefulWidget {
  const UserShopViewScreen({super.key});

  @override
  State<UserShopViewScreen> createState() => _UserShopViewScreenState();
}

class _UserShopViewScreenState extends State<UserShopViewScreen> {
  String? _mechanicId;
  String? _mechanicName;
  String? _requestId;
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _mechanicId = args['mechanicId'];
      _mechanicName = args['mechanicName'];
      _requestId = args['requestId'];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mechanicId == null) {
      return const Scaffold(
          body: Center(child: Text("Invalid mechanic selection.")));
    }

    final dark = isDarkMode(context);

    return Scaffold(
      backgroundColor:
          dark ? AppColors.darkBackground : const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text('${_mechanicName ?? "Mechanic"}\'s Shop',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? Colors.white : Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_mechanicId)
            .collection('products')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState(dark);
          }

          // Filter out out-of-stock items if we only want to show available products
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final stock = data['stockCount'] ?? 0;
            return stock > 0;
          }).toList();

          if (docs.isEmpty) {
            return _emptyState(dark);
          }
          return Column(
            children: [
              // Shop Header
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: dark
                        ? [const Color(0xFF1E3A5F), const Color(0xFF15294A)]
                        : [AppColors.primaryBlue, const Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withAlpha(76),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withAlpha(51),
                      child: const Icon(Icons.store, color: Colors.white, size: 35),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _mechanicName ?? "Shop",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: Colors.cyanAccent, size: 18),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                "4.8 (120+ reviews)",
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "AUTHORIZED DEALER",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      "Available Inventory",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final id = docs[index].id;
                    final product = docs[index].data() as Map<String, dynamic>;
                    return _productCard(id, product, dark);
                  },
                ),
              ),
            ],
          );
        },
      ),
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
            'No tools available',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: dark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('This mechanic hasn\'t listed any tools yet.',
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _productCard(String id, Map<String, dynamic> p, bool dark) {
    final name = p['name'] ?? 'Product';
    final price = p['price'] ?? 0.0;
    final image = p['imageUrl'] as String?;
    final stock = p['stockCount'] ?? 0;
    final hasStock = stock > 0;

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: dark ? Colors.grey[800] : Colors.grey[100],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: image != null && image.isNotEmpty
                  ? ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(image, fit: BoxFit.cover),
                    )
                  : Icon(Icons.handyman_outlined,
                      color: Colors.grey[400], size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: dark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${price.toString()}',
                  style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  hasStock ? 'Stock: $stock' : 'Out of Stock',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasStock ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (hasStock && !_isProcessing)
                            ? () {
                                if (_requestId != null) {
                                  _handleRequestTool(id, name, price);
                                } else {
                                  Navigator.pushNamed(context, '/checkout', arguments: {
                                    'productId': id,
                                    'itemName': name,
                                    'itemPrice': price,
                                    'mechanicId': _mechanicId,
                                    'mechanicName': _mechanicName,
                                  });
                                }
                              }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(_requestId == null ? 'Buy Now' : 'Request',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRequestTool(
      String productId, String name, dynamic price) async {
    if (_requestId == null || _mechanicId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isProcessing = true);
      }
    });

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final productRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_mechanicId)
            .collection('products')
            .doc(productId);

        final requestRef =
            FirebaseFirestore.instance.collection('requests').doc(_requestId);

        final pSnap = await transaction.get(productRef);
        final rSnap = await transaction.get(requestRef);

        if (!pSnap.exists || !rSnap.exists) {
          throw Exception("Product or Request no longer available.");
        }

        final currentStock = pSnap.data()?['stockCount'] ?? 0;
        if (currentStock <= 0) {
          throw Exception("Out of stock.");
        }

        // 1. Decrement Stock
        transaction.update(productRef, {'stockCount': currentStock - 1});

        // 2. Update Request Tools & Price
        final requestData = rSnap.data() as Map<String, dynamic>;
        final currentPrice = (requestData['totalPrice'] ?? 2000).toDouble();
        final List<dynamic> currentTools = requestData['tools'] ?? [];

        final num priceVal =
            (price is num) ? price : (double.tryParse(price.toString()) ?? 0.0);

        transaction.update(requestRef, {
          'totalPrice': currentPrice + priceVal.toDouble(),
          'tools': [
            ...currentTools,
            {
              'productId': productId,
              'name': name,
              'price': priceVal.toDouble(),
              'requestedAt': Timestamp.now(),
            }
          ],
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully requested $name!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        });
      }
    }
  }

}
