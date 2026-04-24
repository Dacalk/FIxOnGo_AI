import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_provider.dart';

class JobHistoryScreen extends StatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  State<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends State<JobHistoryScreen> {
  Future<Map<String, dynamic>> _fetchJobHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'rating': 0.0, 'jobs': []};

    // Fetch user doc for rating
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    double rating = 0.0;
    if (userDoc.exists) {
      final data = userDoc.data()!;
      if (data['roles'] != null && data['roles']['mechanic'] != null) {
        rating = (data['roles']['mechanic']['rating'] ?? 0.0).toDouble();
      }
    }

    // Fetch all completed jobs
    final requestsSnap = await FirebaseFirestore.instance
        .collection('requests')
        .where('mechanicId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'completed')
        .get();

    // Fetch all reviews
    final reviewsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reviews')
        .get();

    final reviewsMap = <String, Map<String, dynamic>>{};
    for (var doc in reviewsSnap.docs) {
      final data = doc.data();
      if (data['requestId'] != null) {
        reviewsMap[data['requestId']] = data;
      }
    }

    final jobs = requestsSnap.docs.map((doc) {
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Job History',
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchJobHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading job history", style: TextStyle(color: titleColor)));
          }

          final data = snapshot.data;
          final double overallRating = data?['rating'] ?? 0.0;
          final List<dynamic> jobs = data?['jobs'] ?? [];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Performance Banner ──
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

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Jobs',
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
                                  'All Time',
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
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (jobs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40.0),
                          child: Center(
                            child: Text(
                              "No completed jobs yet.",
                              style: TextStyle(color: subColor, fontSize: 16),
                            ),
                          ),
                        )
                      else
                        ..._buildJobList(jobs, dark, cardBg, titleColor, subColor),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
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
      final clientName = job['userName'] ?? 'Unknown Client';
      final serviceType = job['serviceType'] ?? 'General Service';
      final rating = (review?['rating'] ?? 0.0).toDouble();
      final comment = review?['comment'] ?? 'No feedback provided.';

      list.add(
        _buildJobCard(
          clientName: clientName,
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
    required String clientName,
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
                  color: Colors.black.withValues(alpha: 0.03),
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
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                child: Text(
                  clientName.isNotEmpty ? clientName[0].toUpperCase() : 'U',
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
                      clientName,
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
              if (rating > 0)
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
          if (rating > 0) ...[
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
}
