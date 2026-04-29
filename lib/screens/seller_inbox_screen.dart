import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme_provider.dart';
import 'seller_chat_screen.dart';

/// Seller Inbox — lists all real customer conversations from Firestore.
///
/// Firestore structure used:
///   conversations/{docId}  {
///     sellerId: String,
///     customerId: String,
///     customerName: String,
///     lastMessage: String,
///     lastMessageTime: Timestamp,
///     unreadBySeller: int,
///   }
///   conversations/{docId}/messages/{msgId}  {
///     senderId: String,
///     text: String,
///     timestamp: Timestamp,
///   }
class SellerInboxScreen extends StatelessWidget {
  final bool isEmbedded;
  const SellerInboxScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF5F8FF);
    final cardColor = dark ? AppColors.darkSurface : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black87;
    final subtitleColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = dark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── Header ───
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF111D35) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withAlpha((dark ? 0.3 : 0.06 * 255).toInt()),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (!isEmbedded)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          color: dark ? Colors.white : Colors.black87,
                          size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  if (!isEmbedded) const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Messages',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        Text(
                          'Your inbox from customers',
                          style:
                              TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          AppColors.primaryBlue.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inbox_rounded,
                        color: AppColors.primaryBlue, size: 22),
                  ),
                ],
              ),
            ),

            // ─── Conversation list ───
            Expanded(
              child: uid == null
                  ? _emptyState('Not logged in', dark)
                  : StreamBuilder<QuerySnapshot>(
                      // Single where clause — no composite index required.
                      // Sort client-side by lastMessageTime.
                      stream: FirebaseFirestore.instance
                          .collection('conversations')
                          .where('sellerId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return _emptyState(
                              'No messages yet.\nCustomers who contact you will appear here.',
                              dark);
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return _emptyState(
                              'No messages yet.\nCustomers who contact you will appear here.',
                              dark);
                        }

                        // Sort client-side by lastMessageTime descending
                        final sorted = [...docs];
                        sorted.sort((a, b) {
                          final aData =
                              a.data() as Map<String, dynamic>;
                          final bData =
                              b.data() as Map<String, dynamic>;
                          final aTs =
                              aData['lastMessageTime'] as Timestamp?;
                          final bTs =
                              bData['lastMessageTime'] as Timestamp?;
                          if (aTs == null && bTs == null) return 0;
                          if (aTs == null) return 1;
                          if (bTs == null) return -1;
                          return bTs.compareTo(aTs);
                        });

                        return ListView.separated(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 76,
                            color: borderColor,
                          ),
                          itemBuilder: (context, i) {
                            final doc = sorted[i];
                            final data =
                                doc.data() as Map<String, dynamic>;
                            final convoId = doc.id;
                            final customerName =
                                data['customerName'] as String? ??
                                    'Customer';
                            final customerId =
                                data['customerId'] as String? ?? '';
                            final lastMsg =
                                data['lastMessage'] as String? ?? '';
                            final unread =
                                (data['unreadBySeller'] as int?) ?? 0;
                            final ts =
                                data['lastMessageTime'] as Timestamp?;
                            final timeLabel =
                                _formatTime(ts?.toDate());

                            return _ConversationTile(
                              name: customerName,
                              lastMessage: lastMsg,
                              time: timeLabel,
                              unreadCount: unread,
                              dark: dark,
                              cardColor: cardColor,
                              titleColor: titleColor,
                              subtitleColor: subtitleColor,
                              onTap: () async {
                                if (unread > 0) {
                                  await FirebaseFirestore.instance
                                      .collection('conversations')
                                      .doc(convoId)
                                      .update(
                                          {'unreadBySeller': 0});
                                }
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SellerChatScreen(
                                        conversationId: convoId,
                                        otherUserId: customerId,
                                        otherUserName: customerName,
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message, bool dark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_chat_unread_outlined,
              size: 72,
              color: dark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: dark ? Colors.grey[500] : Colors.grey[500],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year % 100}';
    }
  }
}

class _ConversationTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool dark;
  final Color cardColor;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.dark,
    required this.cardColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: hasUnread
            ? (dark
                ? AppColors.primaryBlue.withAlpha(15)
                : AppColors.primaryBlue.withAlpha(10))
            : cardColor,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      AppColors.primaryBlue.withAlpha(38),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 11,
                    height: 11,
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread
                              ? AppColors.primaryBlue
                              : subtitleColor,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread ? titleColor : subtitleColor,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
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
