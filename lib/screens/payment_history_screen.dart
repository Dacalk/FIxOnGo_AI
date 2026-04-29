import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme_provider.dart';
import '../components/seller_bottom_nav.dart';

/// Payment History screen — view past transactions.
/// Linked from the Bottom Navigation Bar 'Payment' tab.
class PaymentHistoryScreen extends StatefulWidget {
  final bool isEmbedded;
  final bool isProviderView;
  final String? filterType;
  final String? role;

  const PaymentHistoryScreen({
    super.key,
    this.isEmbedded = false,
    this.isProviderView = false,
    this.filterType,
    this.role,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final String _selectedFilter = 'Last 4 Month';

  // Resolved once in didChangeDependencies after route is available
  bool _resolvedProviderView = false;
  bool _argsResolved = false;
  Stream<List<Map<String, dynamic>>>? _paymentsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only resolve once — ModalRoute is available here (not in initState)
    if (!_argsResolved) {
      _argsResolved = true;
      bool providerView = widget.isProviderView;
      String? typeFilter = widget.filterType;

      if (!widget.isEmbedded) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          if (args.containsKey('isProviderView')) {
            providerView = args['isProviderView'] as bool? ?? false;
          }
          if (args.containsKey('filterType')) {
            typeFilter = args['filterType'] as String?;
          }
        }
      }

      _resolvedProviderView = providerView;
      _paymentsStream = _buildStream(providerView, typeFilter);
    }
  }

  bool get _isProviderViewResolved => _resolvedProviderView;

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  String _getMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  Stream<List<Map<String, dynamic>>> _buildStream(
      bool providerView, String? typeFilter) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    // Simple query without .orderBy to avoid needing a composite index
    Query query = FirebaseFirestore.instance
        .collection('payments')
        .where(providerView ? 'mechanicId' : 'userId', isEqualTo: user.uid);

    // NOTE: typeFilter removed — payment docs don't always have a 'type' field,
    // and adding a second .where() would require yet another composite index.

    return query.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by createdAt in memory (newest first)
      list.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF2F8FE);
    final topBarColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? const Color(0xFF222F3E) : Colors.white;

    // Banner styling
    final bannerBg = dark ? const Color(0xFF1E3A8A) : const Color(0xFFD4E6F8);
    final bannerText = dark ? Colors.white : const Color(0xFF3B7BC2);
    final bannerCircle1 = dark
        ? const Color(0xFF2563EB).withValues(alpha: 0.5)
        : const Color(0xFFB3D4F3);
    final bannerCircle2 = dark
        ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
        : const Color(0xFFEAF2FB);

    final content = StreamBuilder<List<Map<String, dynamic>>>(
      stream: _paymentsStream ?? Stream.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data ?? [];
        final totalAmount = payments.fold<double>(
            0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));

        return Column(
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
                                color: bannerCircle1,
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
                                color: bannerCircle2,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isProviderViewResolved
                                      ? 'TOTAL EARNINGS'
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
                                  'RS. ${NumberFormat('#,##0.00').format(totalAmount)}',
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

                    // ── Filters & Headers ──
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                dark ? AppColors.brandYellow : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedFilter,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: dark ? Colors.black : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down,
                                  size: 16, color: Colors.black),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (payments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.history_toggle_off_rounded,
                                  size: 64,
                                  color: subColor.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text(
                                "No transaction history found.",
                                style: TextStyle(color: subColor, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._buildTransactionList(
                          payments, dark, cardBg, titleColor, subColor),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (!widget.isEmbedded) _buildBottomNav(context, dark),
          ],
        );
      },
    );

    if (widget.isEmbedded) return content;

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
      body: content,
    );
  }

  List<Widget> _buildTransactionList(List<Map<String, dynamic>> payments,
      bool dark, Color cardBg, Color titleColor, Color subColor) {
    List<Widget> list = [];
    String? currentMonth;

    for (var p in payments) {
      final createdAt = p['createdAt'] as Timestamp?;
      if (createdAt == null) continue;
      final date = createdAt.toDate();
      final monthStr = _getMonthYear(date);

      if (currentMonth != monthStr) {
        currentMonth = monthStr;
        list.add(_buildMonthHeader(monthStr, titleColor));
      }

      final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
      final type = p['type'] ?? 'service';
      final isTowing = type.toString().toLowerCase() == 'towing';

      list.add(
        _buildTransactionCard(
          icon: isTowing ? Icons.local_shipping : Icons.build,
          title: isTowing ? 'Towing Request' : 'Mechanic Request',
          date: _formatDate(date),
          vehicle:
              'Transaction ID: ${p['id'].toString().substring(0, 8).toUpperCase()}',
          amount:
              '${_isProviderViewResolved ? "+" : "-"} RS. ${NumberFormat('#,##0').format(amount)}',
          status: 'COMPLETED',
          dark: dark,
          cardBg: cardBg,
          titleColor: titleColor,
          subColor: subColor,
        ),
      );
      list.add(const SizedBox(height: 16));
    }

    return list;
  }

  Widget _buildMonthHeader(String month, Color titleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        month,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: titleColor,
        ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required IconData icon,
    required String title,
    required String date,
    required String vehicle,
    required String amount,
    required String status,
    required bool dark,
    required Color cardBg,
    required Color titleColor,
    required Color subColor,
  }) {
    final statusBg = dark ? const Color(0xFF163E2B) : const Color(0xFFD1F2DD);
    final statusText = dark ? const Color(0xFF4DB07B) : const Color(0xFF23A05B);
    final amountColor = _isProviderViewResolved
        ? Colors.green
        : (dark ? const Color(0xFF4B89D7) : const Color(0xFF1E61D8));
    final iconColor = dark ? Colors.grey[400] : Colors.black;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor?.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
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
                      date,
                      style: TextStyle(
                        fontSize: 11,
                        color: subColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text('•', style: TextStyle(fontSize: 10, color: subColor)),
                    Text(
                      vehicle,
                      style: TextStyle(
                        fontSize: 11,
                        color: subColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                          color: statusText,
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
    );
  }

  Widget _buildBottomNav(BuildContext context, bool dark) {
    if (widget.role?.toLowerCase() == 'seller') {
      return SellerBottomNav(currentIndex: -1, role: widget.role);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111D35) : Colors.white,
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
            _navItem(context, Icons.home_rounded, 'Dashboard', false, dark,
                '/dashboard'),
            _navItem(
                context,
                (_isProviderViewResolved)
                    ? Icons.history_rounded
                    : Icons.history_rounded, // Activities for others too
                (_isProviderViewResolved) ? 'Activity' : 'Activities',
                false,
                dark,
                '/job-history'),
            _navItem(context, Icons.payments_rounded, 'Payment', true, dark,
                '/payment-history'),
            _navItem(context, Icons.person_rounded, 'Profile', false, dark,
                '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label,
      bool isActive, bool dark, String routeName) {
    final color = isActive
        ? (dark ? AppColors.brandYellow : AppColors.primaryBlue)
        : (dark ? Colors.grey[600]! : Colors.grey[400]!);

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          if (routeName == '/dashboard') {
            Navigator.pushReplacementNamed(context, routeName,
                arguments: widget.role);
          } else {
            Navigator.pushReplacementNamed(context, routeName);
          }
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
