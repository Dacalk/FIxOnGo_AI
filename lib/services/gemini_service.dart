import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  ChatSession? _chatSession;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.replaceAll('"', '').trim();
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception(
        'GEMINI_API_KEY not found in .env file or is still the default value.',
      );
    }

    _model = GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);

    // Start a new chat session to maintain context
    _chatSession = _model.startChat();
  }

  /// Sends a message and receives the AI's response.
  Future<String> sendMessage(String message) async {
    try {
      final response = await _chatSession?.sendMessage(Content.text(message));
      return response?.text ?? 'Sorry, I couldn\'t generate a response.';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Resets the chat session.
  void resetChat() {
    _chatSession = _model.startChat();
  }
}
