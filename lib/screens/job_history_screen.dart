import 'package:flutter/material.dart';
import '../theme_provider.dart';

class JobHistoryScreen extends StatelessWidget {
  const JobHistoryScreen({super.key});

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
      body: Column(
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
                                    '4.8',
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

                  _buildMonthHeader('February 2026', titleColor),
                  _buildJobCard(
                    clientName: 'Sarah Jenkins',
                    date: '12 Feb, 10:30 AM',
                    vehicle: 'Toyota Hybrid - Engine Issue',
                    rating: 5.0,
                    review: 'Excellent service! The mechanic arrived quickly and fixed the hybrid engine without any issues. Highly recommend.',
                    dark: dark,
                    cardBg: cardBg,
                    titleColor: titleColor,
                    subColor: subColor,
                  ),

                  const SizedBox(height: 16),

                  _buildMonthHeader('January 2026', titleColor),
                  _buildJobCard(
                    clientName: 'Michael Rossi',
                    date: '28 Jan, 02:15 PM',
                    vehicle: 'Honda Civic - Battery replacement',
                    rating: 4.5,
                    review: 'Very professional, brought the exact battery needed. A little late due to traffic, but overall great job.',
                    dark: dark,
                    cardBg: cardBg,
                    titleColor: titleColor,
                    subColor: subColor,
                  ),

                  const SizedBox(height: 16),
                  
                  _buildJobCard(
                    clientName: 'David Lee',
                    date: '15 Jan, 09:00 AM',
                    vehicle: 'Nissan Leaf - Electrical Check',
                    rating: 5.0,
                    review: 'Fixed the dashboard warning light in minutes. Friendly and knowledgeable.',
                    dark: dark,
                    cardBg: cardBg,
                    titleColor: titleColor,
                    subColor: subColor,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
                  clientName[0],
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
      ),
    );
  }
}
