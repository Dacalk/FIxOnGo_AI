import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_provider.dart';

class MechanicDetailsScreen extends StatefulWidget {
  const MechanicDetailsScreen({super.key});

  @override
  State<MechanicDetailsScreen> createState() => _MechanicDetailsScreenState();
}

class _MechanicDetailsScreenState extends State<MechanicDetailsScreen> {
  String? _mechanicId;
  Map<String, dynamic>? _mechanicData;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() => _mechanicId = args);
        _fetchData();
      } else if (args is Map<String, dynamic>) {
        setState(() {
          _mechanicId = args['id'];
        });
        _fetchData();
      }
    });
  }

  Future<void> _fetchData() async {
    if (_mechanicId == null) return;

    try {
      final mechDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_mechanicId)
          .get();

      final reviewsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_mechanicId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _mechanicData = mechDoc.data();
          _reviews = reviewsSnap.docs.map((doc) => doc.data()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching mechanic details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final m = _mechanicData?['roles']?['mechanic'] as Map<String, dynamic>?;
    final name = m?['fullName'] ?? 'Mechanic';
    final specialty = m?['vehicleType'] ?? 'General Mechanic';
    final rating = m?['rating'] ?? 0.0;
    final reviewsCount = m?['reviews'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanic Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Info
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              specialty,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${rating.toStringAsFixed(1)} ($reviewsCount Reviews)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Reviews List
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Feedbacks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No reviews yet.',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return _reviewCard(review, dark);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review, bool dark) {
    final rating = review['rating'] ?? 0;
    final comment = review['comment'] ?? '';
    final userName = review['userName'] ?? 'Anonymous';
    final date = (review['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (comment.isNotEmpty)
            Text(
              comment,
              style:
                  TextStyle(color: dark ? Colors.grey[300] : Colors.grey[700]),
            ),
          if (date != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${date.day}/${date.month}/${date.year}',
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
