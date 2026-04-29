import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_provider.dart';
import '../services/location_service.dart';
import 'package:latlong2/latlong.dart';

class BrowseShopsScreen extends StatefulWidget {
  const BrowseShopsScreen({super.key});

  @override
  State<BrowseShopsScreen> createState() => _BrowseShopsScreenState();
}

class _BrowseShopsScreenState extends State<BrowseShopsScreen> {
  LatLng? _userLatLng;
  bool _isLoading = true;
  bool _isUIReady = false;
  String _searchQuery = "";
  String _selectedCategory = "All";

  final List<String> _categories = ["All", "Tools", "Parts", "Accessories", "Oils"];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    // Delay heavy UI logic to avoid Flutter Web assertion loops
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _isUIReady = true);
    });
  }

  Future<void> _fetchLocation() async {
    try {
      final pos = await LocationService.instance.getCurrentLatLng();
      if (mounted) {
        setState(() {
          _userLatLng = pos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF8FAFF);
    final titleColor = dark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Browse Shops',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search shops or items...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: dark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Categories
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (s) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (dark ? Colors.grey[400] : Colors.grey[700]),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: dark ? AppColors.darkSurface : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Shop List
          Expanded(
            child: _isLoading || !_isUIReady
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('roles', isNotEqualTo: null)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final users = snapshot.data?.docs ?? [];
                      final shops = <Map<String, dynamic>>[];

                      for (var doc in users) {
                        final data = doc.data() as Map<String, dynamic>?;
                        if (data == null) continue;

                        final roles = data['roles'] as Map<String, dynamic>? ?? {};
                        
                        Map<String, dynamic>? shopData;
                        String roleName = "";
                        
                        // Check seller role first
                        if (roles.containsKey('seller')) {
                          shopData = roles['seller'] as Map<String, dynamic>?;
                          roleName = "Seller";
                        } 
                        // If not seller, check mechanic
                        if (shopData == null && roles.containsKey('mechanic')) {
                          shopData = roles['mechanic'] as Map<String, dynamic>?;
                          roleName = "Mechanic";
                        }

                        if (shopData != null && shopData['shopName'] != null) {
                          final name = shopData['shopName'].toString().toLowerCase();
                          if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) continue;

                          shops.add({
                            'id': doc.id,
                            'name': shopData['shopName'] ?? 'Unknown Shop',
                            'role': roleName,
                            'rating': shopData['rating'] ?? 4.8,
                            'location': shopData['location'],
                            'photoUrl': data['photoUrl'],
                            'address': shopData['address'] ?? 'Nearby Store',
                          });
                        }
                      }

                      if (shops.isEmpty) {
                        return _emptyState(dark);
                      }

                      // Sort by distance if location is available
                      if (_userLatLng != null) {
                        final distance = const Distance();
                        for (var s in shops) {
                          final loc = s['location'] as Map<String, dynamic>?;
                          if (loc != null) {
                            s['dist'] = distance.as(LengthUnit.Meter, _userLatLng!, LatLng(loc['lat'], loc['lng']));
                          } else {
                            s['dist'] = 999999.0;
                          }
                        }
                        shops.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: shops.length,
                        itemBuilder: (context, index) {
                          return _shopCard(shops[index], dark);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _shopCard(Map<String, dynamic> shop, bool dark) {
    final distKm = shop['dist'] != null ? (shop['dist'] / 1000).toStringAsFixed(1) : "?";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.pushNamed(context, '/user-shop-view', arguments: {
            'mechanicId': shop['id'],
            'mechanicName': shop['name'],
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Shop Image
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 80,
                  height: 80,
                  color: dark ? Colors.grey[800] : Colors.grey[100],
                  child: shop['photoUrl'] != null && shop['photoUrl'].toString().isNotEmpty
                      ? Image.network(shop['photoUrl'], fit: BoxFit.cover)
                      : Icon(Icons.store, color: Colors.grey[400], size: 32),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  (shop['name']?.toString().isNotEmpty == true) ? shop['name'] : '${shop['role'] ?? 'Seller'} Shop',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: dark ? Colors.white : Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 14),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                shop['rating'].toString(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (shop['address']?.toString().isNotEmpty == true) ? shop['address'] : 'Location hidden',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.red[400]),
                        const SizedBox(width: 4),
                        Text(
                          '$distKm km away',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 12, color: Colors.green[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Open Now',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[400]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool dark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: dark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No shops found nearby',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Try searching for something else.', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
