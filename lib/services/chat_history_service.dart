import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';

class ChatHistoryService {
  static const String _sessionsKey = 'ai_chat_sessions_v2';

  /// Saves the list of all chat sessions to shared preferences.
  Future<void> _saveAllSessions(List<ChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      sessions.map((s) => s.toMap()).toList(),
    );
    await prefs.setString(_sessionsKey, encodedData);
  }

  /// Loads the list of all chat sessions from shared preferences.
  Future<List<ChatSession>> loadAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionsJson = prefs.getString(_sessionsKey);

    if (sessionsJson == null || sessionsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedData = jsonDecode(sessionsJson);
      final sessions = decodedData
          .map((item) => ChatSession.fromMap(item as Map<String, dynamic>))
          .toList();

      // Sort by timestamp descending (newest first)
      sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return sessions;
    } catch (e) {
      print('Error loading chat sessions: $e');
      return [];
    }
  }

  /// Saves or updates a single chat session.
  Future<void> saveSession(ChatSession session) async {
    final sessions = await loadAllSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);

    if (index != -1) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }

    await _saveAllSessions(sessions);
  }

  /// Deletes a specific chat session.
  Future<void> deleteSession(String id) async {
    final sessions = await loadAllSessions();
    sessions.removeWhere((s) => s.id == id);
    await _saveAllSessions(sessions);
  }

  /// Clears all chat history.
  Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }
}
