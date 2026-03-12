import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  GenerativeModel? _model;
  GenerativeModel? _fallbackModel;
  ChatSession? _chat;
  ChatSession? _fallbackChat;

  void init() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      print('Warning: Gemini API Key is missing or invalid.');
      return;
    }

    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

    _fallbackModel = GenerativeModel(model: 'gemini-2.5-pro', apiKey: apiKey);

    _ultimateFallbackModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );

    _chat = _model!.startChat(history: _initialHistory);
    _fallbackChat = _fallbackModel!.startChat(history: _initialHistory);
    _ultimateFallbackChat = _ultimateFallbackModel!.startChat(
      history: _initialHistory,
    );
  }

  GenerativeModel? _ultimateFallbackModel;
  ChatSession? _ultimateFallbackChat;

  static final List<Content> _initialHistory = [
    Content.text(
      'You are a helpful Roadside AI Assistant for FixOnGo. '
      'Your goal is to help users troubleshoot car problems and provide roadside assistance advice. '
      'Be concise, professional, and friendly.',
    ),
  ];

  Future<String?> sendMessage(String message) async {
    if (_chat == null) {
      init();
    }

    if (_chat == null) return 'API Key not configured.';

    try {
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text;
    } catch (e) {
      print('Error sending message to Gemini (Primary): $e');

      // Try fallback
      try {
        print('Attempting fallback to gemini-pro...');
        final response = await _fallbackChat!.sendMessage(
          Content.text(message),
        );
        return response.text;
      } catch (e2) {
        print('Error sending message to Gemini (Fallback): $e2');

        // Try ultimate fallback
        try {
          print('Attempting ultimate fallback to gemini-1.0-pro...');
          final response = await _ultimateFallbackChat!.sendMessage(
            Content.text(message),
          );
          return response.text;
        } catch (e3) {
          print('Error sending message to Gemini (Ultimate Fallback): $e3');
          return 'Sorry, I encountered an error. Please check your API key and connection.';
        }
      }
    }
  }

  List<Content> get history => _chat?.history.toList() ?? [];
}
