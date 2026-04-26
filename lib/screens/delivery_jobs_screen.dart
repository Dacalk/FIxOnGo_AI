import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_provider.dart';

/// A dedicated Job Board for Delivery drivers to find and accept available requests.
class DeliveryJobsScreen extends StatefulWidget {
  final bool isEmbedded;
  const DeliveryJobsScreen({super.key, this.isEmbedded = false});

  @override
  State<DeliveryJobsScreen> createState() => _DeliveryJobsScreenState();
}

class _DeliveryJobsScreenState extends State<DeliveryJobsScreen> {
  late Stream<List<Map<String, dynamic>>> _availableJobsStream;
  String _filter = 'All'; // 'All', 'Seller', 'Mechanic'

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    Query query = FirebaseFirestore.instance
        .collection('deliveries')
        .where('status', isEqualTo: 'pending');

    if (_filter == 'Seller') {
      query = query.where('sourceRole', isEqualTo: 'seller');
    } else if (_filter == 'Mechanic') {
      query = query.where('sourceRole', isEqualTo: 'mechanic');
    } else {
      query = query.where('sourceRole', whereIn: ['seller', 'mechanic']);
    }

    _availableJobsStream = query.snapshots().map(
        (s) => s.docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList());
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF5F8FF);
    final titleColor = dark ? Colors.white : Colors.black87;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Description (Only if embedded, else AppBar handles it)
        if (widget.isEmbedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Jobs',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find and accept delivery requests nearby.',
                  style: TextStyle(
                    fontSize: 13,
                    color: dark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', dark, titleColor),
                const SizedBox(width: 8),
                _filterChip('Seller', dark, titleColor),
                const SizedBox(width: 8),
                _filterChip('Mechanic', dark, titleColor),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _availableJobsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final jobs = snapshot.data ?? [];

              if (jobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 64,
                          color: dark ? Colors.grey[700] : Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No available jobs right now',
                        style: TextStyle(
                          color: dark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  return _buildJobCard(jobs[index], dark, titleColor);
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.isEmbedded) return content;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Job Board',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: titleColor, fontSize: 17),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18, color: dark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: content,
    );
  }

  Widget _filterChip(String label, bool dark, Color titleColor) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filter = label;
          _initStream();
        });
      },
      selectedColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : titleColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: dark ? AppColors.darkSurface : Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, bool dark, Color titleColor) {
    final isSeller = job['sourceRole'] == 'seller';
    final cardBg = dark ? AppColors.darkSurface : Colors.white;
    final badgeColor = isSeller ? Colors.orange : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isSeller ? Icons.store : Icons.build,
                        size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      isSeller ? 'STORE PICKUP' : 'MECHANIC REQUEST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${job['earnings'] ?? 0}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            job['itemName'] ?? 'Package Delivery',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          _addressRow(Icons.my_location, Colors.orange[400]!,
              job['pickupAddress'] ?? 'Pickup location', dark),
          const SizedBox(height: 10),
          _addressRow(Icons.location_on, Colors.red[400]!,
              job['dropAddress'] ?? 'Drop-off location', dark),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;
                
                final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                final dData = doc.data() ?? {};
                final dRoles = dData['roles'] ?? {};
                final rd = dRoles['delivery'] ?? {};
                final driverName = rd['fullName'] ?? dData['fullName'] ?? 'Driver';

                await FirebaseFirestore.instance
                    .collection('deliveries')
                    .doc(job['id'])
                    .update({
                  'status': 'accepted',
                  'driverId': uid,
                  'driverName': driverName,
                  'acceptedAt': FieldValue.serverTimestamp(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text('Accept Delivery',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressRow(IconData icon, Color iconColor, String address, bool dark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            address,
            style: TextStyle(
              fontSize: 13,
              color: dark ? Colors.grey[400] : Colors.grey[600],
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
