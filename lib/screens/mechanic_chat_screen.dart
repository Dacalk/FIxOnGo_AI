import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_provider.dart';

/// Real-time chat screen between a user and a mechanic/seller.
///
/// Parameters passed via [RouteSettings.arguments]:
///   Map&lt;String, String&gt; {
///     'conversationId': String,   // Firestore conversation doc ID
///     'otherUserId':   String,    // UID of the other chat participant
///     'otherUserName': String,    // Display name of the other participant
///     'otherUserRole': String,    // e.g. 'Mechanic', 'Seller'
///   }
///
/// Firestore structure:
///   conversations/{conversationId}/messages/{msgId}  {
///     senderId: String,
///     text: String,
///     timestamp: Timestamp,
///   }
class MechanicChatScreen extends StatefulWidget {
  /// Optional direct constructor args (used when pushed via MaterialPageRoute).
  final String? conversationId;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserRole;

  const MechanicChatScreen({
    super.key,
    this.conversationId,
    this.otherUserId,
    this.otherUserName,
    this.otherUserRole,
  });

  @override
  State<MechanicChatScreen> createState() => _MechanicChatScreenState();
}

class _MechanicChatScreenState extends State<MechanicChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Resolved from constructor or route args
  late String _conversationId;
  late String _otherUserName;
  late String _otherUserRole;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _conversationId = args['conversationId'] as String? ??
          widget.conversationId ??
          '';
      _otherUserName = args['otherUserName'] as String? ??
          widget.otherUserName ??
          'Mechanic';
      _otherUserRole = args['otherUserRole'] as String? ??
          widget.otherUserRole ??
          'Mechanic';
    } else {
      _conversationId = widget.conversationId ?? '';
      _otherUserName = widget.otherUserName ?? 'Mechanic';
      _otherUserRole = widget.otherUserRole ?? 'Mechanic';
    }
  }

  CollectionReference get _messages => FirebaseFirestore.instance
      .collection('conversations')
      .doc(_conversationId)
      .collection('messages');

  DocumentReference get _convoDoc => FirebaseFirestore.instance
      .collection('conversations')
      .doc(_conversationId);

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversationId.isEmpty) return;
    _messageController.clear();

    final now = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();

    final msgRef = _messages.doc();
    batch.set(msgRef, {
      'senderId': _uid,
      'text': text,
      'timestamp': Timestamp.fromDate(now),
    });

    batch.update(_convoDoc, {
      'lastMessage': text,
      'lastMessageTime': Timestamp.fromDate(now),
      // increment unread on the other side
      'unreadBySeller': FieldValue.increment(1),
    });

    await batch.commit();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

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

    // Show a placeholder when no conversationId is provided
    if (_conversationId.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(dark),
              Divider(height: 1, color: borderColor),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Unable to open chat.\nNo conversation ID provided.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: dark ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
              child: StreamBuilder<QuerySnapshot>(
                stream: _messages
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load messages.',
                        style: TextStyle(
                            color: dark ? Colors.grey[500] : Colors.grey[500]),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No messages yet.\nSay hello to $_otherUserName!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                dark ? Colors.grey[500] : Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  // Auto-scroll to newest message
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildDatePill(dark);
                      final data =
                          docs[index - 1].data() as Map<String, dynamic>;
                      final isMe = (data['senderId'] as String?) == _uid;
                      final text = data['text'] as String? ?? '';
                      final ts = data['timestamp'] as Timestamp?;
                      final time = _formatTime(ts?.toDate());
                      return _buildBubble(
                        text: text,
                        isMe: isMe,
                        time: time,
                        dark: dark,
                      );
                    },
                  );
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
                        color: dark
                            ? Colors.grey[600]!
                            : Colors.grey[400]!,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: dark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 24,
                    color: dark ? Colors.white70 : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  // Text field
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          color: dark ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: dark
                                ? Colors.grey[600]
                                : Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.send, size: 18, color: Colors.white),
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
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: dark ? Colors.white : Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    AppColors.primaryBlue.withAlpha(38),
                child: Text(
                  _otherUserName.isNotEmpty
                      ? _otherUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
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
                      color: dark
                          ? AppColors.darkBackground
                          : Colors.white,
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
                  _otherUserName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                Text(
                  'Online • $_otherUserRole',
                  style: TextStyle(
                      fontSize: 12, color: Colors.green[400]),
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

  Widget _buildBubble({
    required String text,
    required bool isMe,
    required String time,
    required bool dark,
  }) {
    final bubbleColor = isMe
        ? AppColors.primaryBlue
        : (dark ? AppColors.darkSurface : Colors.grey[200]!);
    final textColor = isMe
        ? Colors.white
        : (dark ? Colors.white : Colors.black87);
    final timeColor = dark ? Colors.grey[500]! : Colors.grey[500]!;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 14, color: textColor, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              time,
              style: TextStyle(fontSize: 11, color: timeColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
