import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../services/gemini_service.dart';
import 'package:intl/intl.dart';

/// A model representing a single chat message.
class ChatMessage {
  final String text;
  final String time;
  final bool isUser;
  final String? imagePath;

  const ChatMessage({
    required this.text,
    required this.time,
    required this.isUser,
    this.imagePath,
  });
}

/// Roadside AI Assistant chat screen.
/// Displays a conversation-style UI with AI and user message bubbles,
/// timestamps, and optional image attachments.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;

  // Initial conversation to match the design screenshot
  final List<ChatMessage> _messages = [
    const ChatMessage(
      text:
          "Hi there. I see you're having trouble starting the car. Let's troubleshoot this together.",
      time: '10:23 AM',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _geminiService.init();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      text: text,
      time: DateFormat('h:mm a').format(DateTime.now()),
      isUser: true,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final response = await _geminiService.sendMessage(text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response != null) {
          _messages.add(
            ChatMessage(
              text: response,
              time: DateFormat('h:mm a').format(DateTime.now()),
              isUser: false,
            ),
          );
        }
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final appBarBg = dark ? AppColors.darkBackground : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: dark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Bot avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roadside AI Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : Colors.black,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: dark ? Colors.green[300] : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: dark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages List ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount:
                  _messages.length +
                  (_isLoading
                      ? 2
                      : 1), // +1 for date header, +1 for loading indicator
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildDateHeader(dark);
                }
                if (index <= _messages.length) {
                  return _buildMessageBubble(_messages[index - 1], dark);
                }
                return _buildLoadingBubble(dark);
              },
            ),
          ),

          // ── Message Input ──
          _buildInputBar(dark),
        ],
      ),
    );
  }

  /// Date/time header pill at the top of the chat
  Widget _buildDateHeader(bool dark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: dark
              ? AppColors.darkSurface
              : AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'TODAY, 10:23 AM',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: dark ? Colors.grey[400] : AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  /// A single chat message bubble
  Widget _buildMessageBubble(ChatMessage message, bool dark) {
    final isUser = message.isUser;

    // Colors
    final bubbleBg = isUser
        ? AppColors.primaryBlue
        : dark
        ? AppColors.darkSurface
        : Colors.grey[100]!;
    final textColor = isUser
        ? Colors.white
        : dark
        ? Colors.white
        : Colors.black87;
    final timeColor = isUser
        ? (dark ? Colors.blue[200] : Colors.blue[300])
        : (dark ? Colors.grey[600] : Colors.grey[500]);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Text bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
              ),
            ),

            // Image attachment (if present)
            if (message.imagePath != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  message.imagePath!,
                  width: 220,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 220,
                    height: 150,
                    decoration: BoxDecoration(
                      color: dark ? AppColors.darkSurface : Colors.grey[200],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.image, size: 40),
                  ),
                ),
              ),
            ],

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                message.time,
                style: TextStyle(fontSize: 11, color: timeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Loading bubble while waiting for AI response
  Widget _buildLoadingBubble(bool dark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: SizedBox(
          width: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dark ? Colors.white60 : Colors.black45,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Bottom input bar with text field and send button
  Widget _buildInputBar(bool dark) {
    final inputBg = dark ? AppColors.darkSurface : Colors.grey[100]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkBackground : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: dark ? Colors.grey[500] : Colors.grey[600],
              ),
              onPressed: () {},
            ),
            // Text field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: dark ? Colors.white : Colors.black),
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: _isLoading ? 'Thinking...' : 'Type a message...',
                    hintStyle: TextStyle(
                      color: dark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey : AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
