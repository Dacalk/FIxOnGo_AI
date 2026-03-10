import 'package:flutter/material.dart';
import '../theme_provider.dart';

/// Message data model
class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final bool isRead;
  final bool isLocationCard;
  final String? locationTitle;
  final String? locationSubtitle;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isRead = false,
    this.isLocationCard = false,
    this.locationTitle,
    this.locationSubtitle,
  });
}

/// Chat screen for messaging the mechanic directly.
class MechanicChatScreen extends StatefulWidget {
  const MechanicChatScreen({super.key});

  @override
  State<MechanicChatScreen> createState() => _MechanicChatScreenState();
}

class _MechanicChatScreenState extends State<MechanicChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = const [
    _ChatMessage(
      text: 'How long will it take to arrive?',
      isUser: true,
      time: '14:22',
      isRead: true,
    ),
    _ChatMessage(
      text:
          "I'm near the Clock Tower, should be there in 5 mins. Please stay with your vehicle.",
      isUser: false,
      time: '14:25',
    ),
    _ChatMessage(
      text: '',
      isUser: false,
      time: '14:25',
      isLocationCard: true,
      locationTitle: "Dulan's current location",
      locationSubtitle: 'Approaching via High Street',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final inputBg = dark ? AppColors.darkSurface : Colors.grey[100]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            _buildHeader(dark),
            Divider(height: 1, color: borderColor),

            // ── Messages ──
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _messages.length + 1, // +1 for date pill
                itemBuilder: (context, index) {
                  if (index == 0) return _buildDatePill(dark);
                  return _buildMessage(_messages[index - 1], dark);
                },
              ),
            ),

            // ── Input bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  // Add button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: dark ? Colors.grey[600]! : Colors.grey[400]!,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: dark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Camera button
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 24,
                    color: dark ? Colors.white70 : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  // Text field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(
                          color: dark ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: dark ? Colors.grey[600] : Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool dark) {
    final titleColor = dark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          // Avatar with online dot
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryBlue,
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dark ? AppColors.darkBackground : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dulan Thabrew',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                Text(
                  'Online • Mobile Mechanic',
                  style: TextStyle(fontSize: 12, color: Colors.green[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePill(bool dark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'TODAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: dark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg, bool dark) {
    if (msg.isLocationCard) {
      return _buildLocationCard(msg, dark);
    }

    final userBubbleColor = AppColors.primaryBlue;
    final mechanicBubbleColor = dark
        ? AppColors.darkSurface
        : Colors.grey[200]!;
    final userTextColor = Colors.white;
    final mechanicTextColor = dark ? Colors.white : Colors.black;
    final timeColor = dark ? Colors.grey[500]! : Colors.grey[500]!;

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: msg.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: msg.isUser ? userBubbleColor : mechanicBubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                bottomRight: Radius.circular(msg.isUser ? 4 : 18),
              ),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: msg.isUser ? userTextColor : mechanicTextColor,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              msg.isRead ? '${msg.time} • Read' : msg.time,
              style: TextStyle(fontSize: 11, color: timeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(_ChatMessage msg, bool dark) {
    final cardBg = dark ? AppColors.darkSurface : Colors.grey[200]!;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.green[300]! : Colors.green[700]!;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.72,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map placeholder
            Container(
              height: 130,
              width: double.infinity,
              color: dark ? const Color(0xFF1E3350) : const Color(0xFFB8D4C8),
              child: Stack(
                children: [
                  // Simulated map
                  CustomPaint(
                    size: const Size(double.infinity, 130),
                    painter: _MiniMapPainter(dark: dark),
                  ),
                  // Pin
                  Positioned(
                    left: 120,
                    top: 30,
                    child: Icon(Icons.location_on, color: Colors.red, size: 36),
                  ),
                  // Blue dot
                  Positioned(
                    left: 140,
                    top: 70,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.locationTitle ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.locationSubtitle ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini map painter for the shared location card
class _MiniMapPainter extends CustomPainter {
  final bool dark;
  _MiniMapPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    // Background roads
    final road = Paint()
      ..color = dark
          ? Colors.grey[600]!.withValues(alpha: 0.3)
          : Colors.grey[400]!.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      road,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      road,
    );
    // Vertical roads
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      road,
    );

    // Yellow route path
    final route = Paint()
      ..color = Colors.amber.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.2,
      );
    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
