import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme_provider.dart';
import '../components/seller_bottom_nav.dart';

/// Payment History screen — shows real transactions from Firestore.
/// For sellers/mechanics: shows earnings (payments received).
/// For users/customers: shows spending (payments made).
class PaymentHistoryScreen extends StatelessWidget {
  final bool isEmbedded;
  final String? role;

  const PaymentHistoryScreen({super.key, this.isEmbedded = false, this.role});

  bool get _isEarnerRole {
    final r = role?.toLowerCase() ?? '';
    return r == 'seller' || r == 'mechanic' || r == 'tow' || r == 'tow trucker';
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF2F8FE);
    final topBarColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? const Color(0xFF222F3E) : Colors.white;
    final bannerBg = dark ? const Color(0xFF1E3A8A) : const Color(0xFFD4E6F8);
    final bannerText = dark ? Colors.white : const Color(0xFF3B7BC2);
    final bannerCircle1 = dark ? const Color(0xFF2563EB) : const Color(0xFFB3D4F3);
    final bannerCircle2 = dark ? const Color(0xFF3B82F6) : const Color(0xFFEAF2FB);

    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Build the Firestore query based on role
    // Earner roles: query where their uid is stored as sellerId / mechanicId
    // Customer roles: query where their uid is stored as userId / customerId
    final Query<Map<String, dynamic>> query = _buildQuery(uid);

    final content = StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // Sort client-side by createdAt descending
        final sorted = List.from(docs);
        sorted.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTs = aData['createdAt'] as Timestamp?;
          final bTs = bData['createdAt'] as Timestamp?;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });

        // Calculate total for this month
        final now = DateTime.now();
        double totalThisMonth = 0;
        for (final doc in sorted) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data['createdAt'] as Timestamp?;
          if (ts != null) {
            final dt = ts.toDate();
            if (dt.year == now.year && dt.month == now.month) {
              final amount = (data['amount'] as num?)?.toDouble() ?? 0;
              totalThisMonth += amount;
            }
          }
        }

        final body = Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary Banner ──
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: bannerBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          Positioned(
                            left: -30,
                            bottom: -30,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: bannerCircle1.withValues(alpha: dark ? 0.5 : 1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -40,
                            top: -40,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: bannerCircle2.withValues(alpha: dark ? 0.3 : 1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isEarnerRole
                                      ? 'TOTAL EARNED THIS MONTH'
                                      : 'TOTAL SPENT THIS MONTH',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: bannerText,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'RS. ${NumberFormat('#,##0.00').format(totalThisMonth)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: bannerText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        Text(
                          '${sorted.length} transaction${sorted.length == 1 ? '' : 's'}',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (sorted.isEmpty)
                      _buildEmptyState(dark)
                    else
                      ...sorted.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildTransactionCard(
                          data: data,
                          dark: dark,
                          cardBg: cardBg,
                          titleColor: titleColor,
                          subColor: subColor,
                        );
                      }),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (!isEmbedded) _buildBottomNav(context, dark),
          ],
        );

        if (isEmbedded) return body;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: topBarColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Payment History',
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
          body: body,
        );
      },
    );

    if (isEmbedded) return content;

    return Scaffold(
      backgroundColor: bgColor,
      body: content,
    );
  }

  /// Build a Firestore query. No composite index needed — single where clause.
  Query<Map<String, dynamic>> _buildQuery(String? uid) {
    if (uid == null) {
      return FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: '__none__');
    }

    if (_isEarnerRole) {
      final field = role?.toLowerCase() == 'seller' ? 'sellerId' : 'mechanicId';
      return FirebaseFirestore.instance
          .collection('payments')
          .where(field, isEqualTo: uid);
    } else {
      return FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: uid);
    }
  }

  Widget _buildTransactionCard({
    required Map<String, dynamic> data,
    required bool dark,
    required Color cardBg,
    required Color titleColor,
    required Color subColor,
  }) {
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('dd MMM, hh:mm a').format(ts.toDate())
        : 'N/A';
    final monthLabel = ts != null
        ? DateFormat('MMMM yyyy').format(ts.toDate())
        : '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final title = data['productName'] as String? ??
        data['serviceName'] as String? ??
        data['type'] as String? ??
        (_isEarnerRole ? 'Payment Received' : 'Service Payment');
    final status = (data['status'] as String? ?? 'completed').toUpperCase();
    final description = data['vehicleModel'] as String? ??
        data['description'] as String? ??
        '';

    final amountColor = _isEarnerRole ? Colors.green : const Color(0xFF1E61D8);
    final amountStr = _isEarnerRole
        ? '+ RS.${NumberFormat('#,##0').format(amount)}'
        : '- RS.${NumberFormat('#,##0').format(amount)}';
    final amountColorDark = _isEarnerRole
        ? Colors.greenAccent
        : const Color(0xFF4B89D7);

    final statusBg = dark ? const Color(0xFF163E2B) : const Color(0xFFD1F2DD);
    final statusTextColor = dark ? const Color(0xFF4DB07B) : const Color(0xFF23A05B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (monthLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              monthLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: dark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (dark ? amountColorDark : amountColor)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEarnerRole
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: dark ? amountColorDark : amountColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              amountStr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: dark ? amountColorDark : amountColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: subColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              Text('•', style: TextStyle(fontSize: 10, color: subColor)),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: subColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: statusTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded,
                size: 72,
                color: dark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 16,
                color: dark ? Colors.grey[500] : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isEarnerRole
                  ? 'Your earnings will appear here'
                  : 'Your payment history will appear here',
              style: TextStyle(
                fontSize: 13,
                color: dark ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool dark) {
    if (role?.toLowerCase() == 'seller') {
      return SellerBottomNav(currentIndex: -1, role: role);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A2432) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, Icons.home_rounded, 'Dashboard', false, dark, '/dashboard'),
            _navItem(
              context,
              role?.toLowerCase() == 'mechanic' ? Icons.shopping_bag : Icons.history_rounded,
              role?.toLowerCase() == 'mechanic' ? 'Shop' : 'Activities',
              false,
              dark,
              role?.toLowerCase() == 'mechanic' ? '/mechanic-shop' : '/job-history',
            ),
            _navItem(context, Icons.garage_rounded, 'Vehicles', false, dark, '/garage'),
            _navItem(context, Icons.person_rounded, 'Profile', false, dark, '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    bool dark,
    String routeName,
  ) {
    final color = isActive
        ? AppColors.primaryBlue
        : (dark ? Colors.grey[500]! : Colors.grey[400]!);

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
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
