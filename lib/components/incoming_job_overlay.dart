import 'package:flutter/material.dart';
import '../theme_provider.dart';

class IncomingJobOverlay extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingJobOverlay({
    super.key,
    required this.requestData,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<IncomingJobOverlay> createState() => _IncomingJobOverlayState();
}

class _IncomingJobOverlayState extends State<IncomingJobOverlay> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final userAddress = widget.requestData['userAddress'] ?? 'Nearby User';

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_active, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'NEW JOB REQUEST',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 16),
            
            // User Details
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: dark ? Colors.grey[800] : Colors.grey[200],
                  backgroundImage: (widget.requestData['userPhotoUrl'] != null && widget.requestData['userPhotoUrl'].toString().isNotEmpty)
                      ? NetworkImage(widget.requestData['userPhotoUrl'])
                      : null,
                  child: (widget.requestData['userPhotoUrl'] == null || widget.requestData['userPhotoUrl'].toString().isEmpty)
                      ? Icon(Icons.person, color: Colors.grey[400], size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.requestData['userName'] ?? 'Unknown User',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Customer',
                      style: TextStyle(
                        fontSize: 12,
                        color: dark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: dark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onReject,
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: dark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'DECLINE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: widget.onAccept,
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.brandYellow, Color(0xFFFFD700)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandYellow.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'ACCEPT JOB',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
