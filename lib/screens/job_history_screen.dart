import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_provider.dart';
import '../components/seller_bottom_nav.dart';

class JobHistoryScreen extends StatefulWidget {
  final bool isEmbedded;
  final bool isMechanicView;
  final String? role;

  const JobHistoryScreen({
    super.key,
    this.isEmbedded = false,
    this.isMechanicView = true,
    this.role,
  });

  @override
  State<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends State<JobHistoryScreen> {
  String _selectedFilter = 'All Time';
  
  bool get isProviderView => widget.isMechanicView || 
      (widget.role != null && ['mechanic', 'seller', 'delivery'].contains(widget.role!.toLowerCase()));

  Future<Map<String, dynamic>> _fetchJobHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'rating': 0.0, 'jobs': []};

    final role = (widget.role ?? '').toLowerCase();
    final isProvider = widget.isMechanicView || role == 'mechanic' || role == 'seller' || role == 'delivery';

    double rating = 0.0;

    try {
      // Fetch user doc for rating (only relevant for mechanics/providers)
      if (isProvider) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final rData = data['roles']?[role == 'seller' ? 'seller' : (role == 'delivery' ? 'delivery' : 'mechanic')];
          if (rData != null) {
            rating = (rData['rating'] ?? 0.0).toDouble();
          }
        }
      }

      // Determine the ID field based on role
      String idField = 'userId';
      if (isProvider) {
        if (role == 'seller') {
          idField = 'sellerId';
        } else if (role == 'delivery') {
          idField = 'driverId';
        } else {
          idField = 'mechanicId';
        }
      }

      final requestsSnap = await FirebaseFirestore.instance
          .collection('requests')
          .where(idField, isEqualTo: user.uid)
          .get();

      // Filter completed client-side (include all shop_orders, or non-pending normal requests)
      final completedDocs = requestsSnap.docs.where((d) {
        final data = d.data();
        final status = data['status'] ?? '';
        final type = data['type'] ?? '';
        
        if (type == 'shop_order') {
          return true; // Show all shop orders in history for now, or maybe only delivered/completed
        }
        return status == 'completed' || status == 'delivered';
      }).toList();

      // Fetch all reviews (only for mechanic view)
      final reviewsMap = <String, Map<String, dynamic>>{};
      if (widget.isMechanicView) {
        final reviewsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reviews')
            .get();

        for (var doc in reviewsSnap.docs) {
          final data = doc.data();
          if (data['requestId'] != null) {
            reviewsMap[data['requestId']] = data;
          }
        }
      }

      final jobs = completedDocs.map((doc) {
        final req = doc.data();
        req['id'] = doc.id;
        final review = reviewsMap[doc.id];
        if (review != null) {
          req['review'] = review;
        }
        return req;
      }).toList();

      // Sort jobs by date
      jobs.sort((a, b) {
        final dateA = _getDate(a);
        final dateB = _getDate(b);
        return dateB.compareTo(dateA); // Descending
      });

      return {'rating': rating, 'jobs': jobs};
    } catch (e) {
      return {'rating': rating, 'jobs': [], 'error': e.toString()};
    }
  }

  DateTime _getDate(Map<String, dynamic> req) {
    if (req['lastUpdated'] != null) {
      return (req['lastUpdated'] as Timestamp).toDate();
    }
    if (req['createdAt'] != null) {
      return (req['createdAt'] as Timestamp).toDate();
    }
    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$day $month $year, $hour:$minute $period';
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
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

    Widget content = FutureBuilder<Map<String, dynamic>>(
      future: _fetchJobHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data?['error'] != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[500]),
                const SizedBox(height: 16),
                Text("No history found.", style: TextStyle(color: subColor, fontSize: 16)),
              ],
            ),
          );
        }

        final data = snapshot.data;
        final double overallRating = data?['rating'] ?? 0.0;
        final List<dynamic> allJobs = data?['jobs'] ?? [];

        final now = DateTime.now();
        final List<dynamic> jobs = allJobs.where((job) {
          if (_selectedFilter == 'All Time') return true;
          final date = _getDate(job);
          if (_selectedFilter == 'Last 30 Days') {
            return now.difference(date).inDays <= 30;
          }
          if (_selectedFilter == 'Last 6 Months') {
            return now.difference(date).inDays <= 180;
          }
          if (_selectedFilter == 'This Year') {
            return date.year == now.year;
          }
          return true;
        }).toList();

        return Column(
          children: [
            if (widget.isEmbedded)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isProviderView ? 'Job History' : 'Activities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isMechanicView)
                      // ── Performance Banner ──
                      Container(
                        width: double.infinity,
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 24),
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
                                    'OVERALL RATING',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: bannerText,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        overallRating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: bannerText,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.star, color: Colors.orange, size: 28),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!widget.isMechanicView)
                      // ── User Activities Banner ──
                      Container(
                        width: double.infinity,
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF163E2B) : const Color(0xFFD1F2DD),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'TOTAL COMPLETED SERVICES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: dark ? const Color(0xFF4DB07B) : const Color(0xFF23A05B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${jobs.length}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: dark ? const Color(0xFF4DB07B) : const Color(0xFF23A05B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isProviderView ? 'Recent Jobs' : 'Recent Services',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        PopupMenuButton<String>(
                          initialValue: _selectedFilter,
                          onSelected: (val) {
                            setState(() {
                              _selectedFilter = val;
                            });
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'All Time', child: Text('All Time')),
                            const PopupMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
                            const PopupMenuItem(value: 'Last 6 Months', child: Text('Last 6 Months')),
                            const PopupMenuItem(value: 'This Year', child: Text('This Year')),
                          ],
                          child: Container(
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
                                Icon(Icons.keyboard_arrow_down, size: 16, color: dark ? Colors.black : Colors.grey[700]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (jobs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Center(
                          child: Text(
                            "No history found.",
                            style: TextStyle(color: subColor, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ..._buildJobList(jobs, dark, cardBg, titleColor, subColor),

                    const SizedBox(height: 10), // less padding when bottom nav acts as safe area
                  ],
                ),
              ),
            ),
            if (!widget.isEmbedded)
              _buildBottomNav(context, dark),
          ],
        );
      }
    );

    if (widget.isEmbedded) {
      return Container(
        color: bgColor,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isProviderView ? 'Job History' : 'Activities',
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

  List<Widget> _buildJobList(List<dynamic> jobs, bool dark, Color cardBg, Color titleColor, Color subColor) {
    List<Widget> list = [];
    String? currentMonth;

    for (var job in jobs) {
      final date = _getDate(job);
      final monthStr = _getMonthYear(date);

      if (currentMonth != monthStr) {
        currentMonth = monthStr;
        list.add(_buildMonthHeader(monthStr, titleColor));
      }

      final review = job['review'];
      
      // For user view, display mechanic name if available.
      // For mechanic view, display user name.
      String personName = 'Unknown';
      if (isProviderView) {
        personName = job['userName'] ?? 'Unknown Client';
      } else {
        personName = job['mechanicName'] ?? 'Mechanic';
      }

      final serviceType = job['serviceType'] ?? 'General Service';
      final rating = (review?['rating'] ?? 0.0).toDouble();
      final comment = review?['comment'] ?? 'No feedback provided.';

      list.add(
        _buildJobCard(
          personName: personName,
          date: _formatDate(date),
          vehicle: serviceType,
          rating: rating,
          review: comment,
          dark: dark,
          cardBg: cardBg,
          titleColor: titleColor,
          subColor: subColor,
        )
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

  Widget _buildJobCard({
    required String personName,
    required String date,
    required String vehicle,
    required double rating,
    required String review,
    required bool dark,
    required Color cardBg,
    required Color titleColor,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(7),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryBlue.withAlpha(51),
                child: Text(
                  personName.isNotEmpty ? personName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 11,
                        color: subColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (rating > 0 && isProviderView) // Usually users don't need to see the rating they left prominently, or they can
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating.floor() ? Icons.star : (index < rating ? Icons.star_half : Icons.star_border),
                      size: 16,
                      color: Colors.orange,
                    );
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: dark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car, size: 14, color: subColor),
                const SizedBox(width: 6),
                Text(
                  vehicle,
                  style: TextStyle(
                    fontSize: 11,
                    color: dark ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (rating > 0 && isProviderView) ...[
            const SizedBox(height: 12),
            Text(
              '"$review"',
              style: TextStyle(
                fontSize: 13,
                color: titleColor,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool dark) {
    // Seller: use the shared 4-tab nav
    if (widget.role?.toLowerCase() == 'seller') {
      return SellerBottomNav(currentIndex: -1, role: widget.role);
    }

    // Other roles
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A2432) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
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
                widget.role?.toLowerCase() == 'mechanic'
                    ? Icons.shopping_bag
                    : Icons.history_rounded,
                widget.role?.toLowerCase() == 'mechanic'
                    ? 'Shop'
                    : 'Activities',
                true,
                dark,
                widget.role?.toLowerCase() == 'mechanic'
                    ? '/mechanic-shop'
                    : '/job-history'),
            _navItem(context, Icons.garage_rounded, 'Vehicles', false, dark,
                '/garage'),
            _navItem(context, Icons.person_rounded, 'Profile', false, dark,
                '/profile'),
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
