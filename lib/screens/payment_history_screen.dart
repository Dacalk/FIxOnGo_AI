import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_provider.dart';

/// Payment History screen — view past transactions.
/// Linked from the Bottom Navigation Bar 'Payment' tab.
class PaymentHistoryScreen extends StatefulWidget {
  final bool isEmbedded;
  final bool isProviderView;
  final String? filterType;

  const PaymentHistoryScreen({
    super.key,
    this.isEmbedded = false,
    this.isProviderView = false,
    this.filterType,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _selectedFilter = 'Last 4 Month';

  // Resolved once in didChangeDependencies after route is available
  bool _resolvedProviderView = false;
  String? _resolvedFilterType;
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
        final args = ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>?;
        if (args != null) {
          if (args.containsKey('isProviderView'))
            providerView = args['isProviderView'] as bool? ?? false;
          if (args.containsKey('filterType'))
            typeFilter = args['filterType'] as String?;
        }
      }

      _resolvedProviderView = providerView;
      _resolvedFilterType = typeFilter;
      _paymentsStream = _buildStream(providerView, typeFilter);
    }
  }

  bool get _isProviderViewResolved => _resolvedProviderView;

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[date.month - 1];
    final day = date.day;
    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$day $month, $hour:$minute $period';
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Stream<List<Map<String, dynamic>>> _buildStream(bool providerView, String? typeFilter) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    Query query = FirebaseFirestore.instance
        .collection('payments')
        .where(providerView ? 'mechanicId' : 'userId', isEqualTo: user.uid);

    if (typeFilter != null) {
      query = query.where('type', isEqualTo: typeFilter);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  @override
  Widget build(BuildContext context) {

    final dark = isDarkMode(context);
    final bgColor = dark
        ? AppColors.darkBackground
        : const Color(0xFFF2F8FE);
    final topBarColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? const Color(0xFF222F3E) : Colors.white;

    final bannerBg = dark ? const Color(0xFFBAD5F0) : const Color(0xFFD4E6F8);
    final bannerText = dark ? const Color(0xFF2466A8) : const Color(0xFF3B7BC2);
    final bannerCircle1 = dark ? const Color(0xFF98C1EA) : const Color(0xFFB3D4F3);
    final bannerCircle2 = dark ? const Color(0xFFDDEBFA) : const Color(0xFFEAF2FB);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _paymentsStream ?? Stream.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data ?? [];
        final totalAmount = payments.fold<num>(0, (sum, p) => sum + (p['amount'] ?? 0));

        final content = Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Total Spent/Earnings Banner ──
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
                                  _isProviderViewResolved ? 'TOTAL EARNINGS' : 'TOTAL SPENT THIS MONTH',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: bannerText,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'RS. ${totalAmount.toStringAsFixed(2)}',
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: dark ? AppColors.brandYellow : Colors.grey[300],
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
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
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
                          child: Text(
                            "No transaction history found.",
                            style: TextStyle(color: subColor, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ..._buildTransactionList(payments, dark, cardBg, titleColor, subColor),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (!widget.isEmbedded)
              _buildBottomNav(context, dark),
          ],
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
      },
    );
  }

  List<Widget> _buildTransactionList(List<Map<String, dynamic>> payments, bool dark, Color cardBg, Color titleColor, Color subColor) {
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

      final amount = p['amount'] ?? 0;
      final type = p['type'] ?? 'service';
      final isTowing = type.toString().toLowerCase() == 'towing';

      list.add(
        _buildTransactionCard(
          icon: isTowing ? Icons.local_shipping : Icons.build,
          title: isTowing ? 'Towing Request' : 'Mechanic Request',
          date: _formatDate(date),
          vehicle: 'Transaction ID: ${p['id'].toString().substring(0, 8).toUpperCase()}',
          amount: 'RS. $amount',
          status: 'COMPLETED',
          cardLogo: 'PAID',
          cardTail: 'Direct Payment',
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
    required String cardLogo,
    required String cardTail,
    required bool dark,
    required Color cardBg,
    required Color titleColor,
    required Color subColor,
  }) {
    final statusBg = dark ? const Color(0xFF163E2B) : const Color(0xFFD1F2DD);
    final statusText = dark ? const Color(0xFF4DB07B) : const Color(0xFF23A05B);
    final amountColor = dark ? const Color(0xFF4B89D7) : const Color(0xFF1E61D8);
    final iconColor = dark ? Colors.grey[400] : Colors.black;
    final cardInfoBg = dark ? Colors.grey[800] : Colors.grey[200];

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
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 36, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                      runSpacing: 6,
                      children: [
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 10,
                            color: subColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('•', style: TextStyle(fontSize: 10, color: subColor)),
                        Text(
                          vehicle,
                          style: TextStyle(
                            fontSize: 10,
                            color: subColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardInfoBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      cardLogo,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    cardTail,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View Receipt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 14, color: amountColor),
                  ],
                ),
              ),
            ],
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
                _isProviderViewResolved
                    ? Icons.history_rounded
                    : Icons.garage_rounded,
                _isProviderViewResolved ? 'Activity' : 'Garage',
                false,
                dark,
                _isProviderViewResolved ? '/job-history' : '/garage'),
            _navItem(context, Icons.payments_rounded, 'Payment', true, dark, '/payment-history'),
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
              if (routeName == '/dashboard') {
                // When going to dashboard, we might need the role, but dashboard handles its own load
                Navigator.pushReplacementNamed(context, routeName);
              } else if (routeName == '/profile') {
                Navigator.pushReplacementNamed(context, routeName);
              } else if (routeName == '/payment-history') {
                Navigator.pushReplacementNamed(
                  context,
                  routeName,
                  arguments: {
                    'isProviderView': _isProviderViewResolved,
                    'filterType': widget.filterType,
                  },
                );
              } else {
                Navigator.pushReplacementNamed(context, routeName);
              }
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
