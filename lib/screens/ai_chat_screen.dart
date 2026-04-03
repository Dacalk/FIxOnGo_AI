import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../services/gemini_service.dart';
import '../services/chat_history_service.dart';
import '../models/chat_session.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'time': time,
      'isUser': isUser,
      'imagePath': imagePath,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] as String,
      time: map['time'] as String,
      isUser: map['isUser'] as bool,
      imagePath: map['imagePath'] as String?,
    );
  }
}

/// Roadside AI Assistant chat screen.
/// Displays a conversation-style UI with AI and user message bubbles,
/// timestamps, and optional image attachments.
class AiChatScreen extends StatefulWidget {
  final ChatSession? existingSession;
  const AiChatScreen({super.key, this.existingSession});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatHistoryService _historyService = ChatHistoryService();
  late GeminiService _geminiService;
  late String _sessionId;
  late String _sessionTitle;
  bool _isLoading = false;

  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();

    if (widget.existingSession != null) {
      _sessionId = widget.existingSession!.id;
      _sessionTitle = widget.existingSession!.title;
      _messages = List.from(widget.existingSession!.messages);
    } else {
      final _sessionId = Uuid().v4();
      _sessionTitle = 'New Chat';
      _messages = [
        ChatMessage(
          text:
              "Hi there. I'm your FixOnGo AI Assistant. How can I help you today?",
          time: DateFormat('hh:mm a').format(DateTime.now()),
          isUser: false,
        ),
      ];
    }

    _initializeGemini();
  }

  void _initializeGemini() {
    if (_messages.isNotEmpty && widget.existingSession != null) {
      // Let's do it manually to be safe
      final List<genai.Content> history = _messages
          .where(
            (m) =>
                m.text !=
                "Hi there. I'm your FixOnGo AI Assistant. How can I help you today?",
          )
          .map((m) {
            return genai.Content(m.isUser ? 'user' : 'model', [
              genai.TextPart(m.text),
            ]);
          })
          .toList();
      _geminiService.startChat(history: history);
    } else {
      _geminiService.startChat();
    }
    _scrollToBottom();
  }

  Future<void> _saveCurrentSession() async {
    if (_messages.isEmpty) return;

    // Use the first user message as the title if it's still "New Chat"
    if (_sessionTitle == 'New Chat') {
      try {
        final firstUserMsg = _messages.firstWhere((m) => m.isUser);
        _sessionTitle = firstUserMsg.text.length > 30
            ? '${firstUserMsg.text.substring(0, 27)}...'
            : firstUserMsg.text;
      } catch (_) {
        // No user message yet
      }
    }

    final session = ChatSession(
      id: _sessionId,
      title: _sessionTitle,
      lastMessage: _messages.last.text,
      timestamp: DateTime.now(),
      messages: _messages,
    );

    await _historyService.saveSession(session);
  }

  void _clearHistory() async {
    // For Multi-session, "Clear" means resetting this specific session
    _geminiService.resetChat();
    setState(() {
      _sessionTitle = 'New Chat';
      _messages = [
        ChatMessage(
          text:
              "Hi there. I'm your FixOnGo AI Assistant. How can I help you today?",
          time: DateFormat('hh:mm a').format(DateTime.now()),
          isUser: false,
        ),
      ];
    });
    // Update the saved session to clear messages
    _saveCurrentSession();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat reset')));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      text: text,
      time: DateFormat('hh:mm a').format(DateTime.now()),
      isUser: true,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Save session immediately
    _saveCurrentSession();

    try {
      final aiResponse = await _geminiService.sendMessage(text);

      final aiMessage = ChatMessage(
        text: aiResponse,
        time: DateFormat('hh:mm a').format(DateTime.now()),
        isUser: false,
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
      _scrollToBottom();

      // Save session with AI response
      _saveCurrentSession();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _scrollToBottom() {
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
            icon: Icon(
              Icons.history,
              color: dark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/ai-chat-history');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete_sweep,
              color: dark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear History'),
                  content: const Text(
                    'Are you sure you want to clear the chat history?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearHistory();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
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
              itemCount: _messages.length + 1 + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildDateHeader(dark);
                }
                if (_isLoading && index == _messages.length + 1) {
                  return _buildTypingIndicator(dark);
                }
                return _buildMessageBubble(_messages[index - 1], dark);
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
          DateFormat('EEEE, hh:mm a').format(DateTime.now()).toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: dark ? Colors.grey[400] : AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  /// Typing indicator shown when AI is thinking
  Widget _buildTypingIndicator(bool dark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  dark ? Colors.white70 : AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Roadside AI is thinking...',
              style: TextStyle(
                fontSize: 13,
                color: dark ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
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
                  color: AppColors.primaryBlue,
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
