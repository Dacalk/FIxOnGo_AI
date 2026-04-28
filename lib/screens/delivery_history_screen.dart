import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_provider.dart';

/// Shows the delivery driver's completed deliveries history.
/// Supports isEmbedded mode for use inside DashboardScreen's IndexedStack.
class DeliveryHistoryScreen extends StatefulWidget {
  final bool isEmbedded;
  const DeliveryHistoryScreen({super.key, this.isEmbedded = false});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  String _filter = 'All Time';
  final List<String> _filters = ['All Time', 'Today', 'Last 7 Days', 'Last 30 Days'];

  Stream<QuerySnapshot> _buildStream(String uid) {
    var query = FirebaseFirestore.instance
        .collection('deliveries')
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'delivered')
        .orderBy('deliveredAt', descending: true);

    final now = DateTime.now();
    if (_filter == 'Today') {
      final start = DateTime(now.year, now.month, now.day);
      query = query.where('deliveredAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    } else if (_filter == 'Last 7 Days') {
      query = query.where('deliveredAt',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(now.subtract(const Duration(days: 7))));
    } else if (_filter == 'Last 30 Days') {
      query = query.where('deliveredAt',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(now.subtract(const Duration(days: 30))));
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF5F8FF);
    final titleColor = dark ? Colors.white : Colors.black87;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final selected = f == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    backgroundColor: dark ? AppColors.darkSurface : Colors.grey[200],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildStream(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];

              // Summary bar
              final totalEarnings = docs.fold<num>(
                  0,
                  (sum, doc) =>
                      sum +
                      ((doc.data() as Map<String, dynamic>)['earnings'] ?? 0));

              return Column(
                children: [
                  // Summary card
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: dark
                              ? [
                                  const Color(0xFF1A3A5C),
                                  const Color(0xFF112240)
                                ]
                              : [
                                  const Color(0xFF1A4DBE),
                                  const Color(0xFF2E7DFF)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _summaryItem('${docs.length}', 'Deliveries',
                              Icons.delivery_dining),
                          _summaryItem('Rs. ${totalEarnings.toStringAsFixed(0)}',
                              'Total Earned', Icons.account_balance_wallet),
                        ],
                      ),
                    ),
                  ),

                  // Delivery list
                  Expanded(
                    child: docs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 64,
                                    color: dark
                                        ? Colors.grey[700]
                                        : Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'No deliveries for this period',
                                  style: TextStyle(
                                      color: dark
                                          ? Colors.grey[500]
                                          : Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final d = docs[i].data() as Map<String, dynamic>;
                              final source = d['sourceRole'] ?? 'seller';
                              final accent = source == 'seller'
                                  ? Colors.orange
                                  : Colors.blue;
                              final badge =
                                  source == 'seller' ? '🛒 Seller' : '🔧 Mechanic';
                              final ts = d['deliveredAt'] as Timestamp?;
                              final date = ts != null
                                  ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                                  : '–';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: dark
                                      ? AppColors.darkSurface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: dark
                                        ? Colors.grey[800]!
                                        : Colors.grey[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.check_circle,
                                          color: Colors.green, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d['itemName'] ?? 'Item',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: dark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '$badge • $date',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            d['dropAddress'] ?? '',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: dark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[500],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${d['earnings'] ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
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
          'Delivery History',
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

  Widget _summaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
