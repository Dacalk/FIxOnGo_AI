import '../screens/ai_chat_screen.dart';

class ChatSession {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime timestamp;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lastMessage': lastMessage,
      'timestamp': timestamp.toIso8601String(),
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] as String,
      title: map['title'] as String,
      lastMessage: map['lastMessage'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      messages: (map['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
          .toList(),
    );
  }

  ChatSession copyWith({
    String? id,
    String? title,
    String? lastMessage,
    DateTime? timestamp,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      messages: messages ?? this.messages,
    );
  }
}
