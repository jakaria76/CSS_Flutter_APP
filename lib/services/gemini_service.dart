import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:css/constants/ai_system_prompt.dart';
import 'package:css/constants/app_secrets.dart';

/// CSS App AI Service — Groq API (Llama 3.3 70B)
/// Free tier: 30 requests/minute, 14,400/day
/// Class name kept as GeminiService to avoid breaking other files
class GeminiService {
  GeminiService._();

  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  // ─── Chat history ──────────────────────────────────────────────────────────
  static final List<Map<String, dynamic>> _history = [];

  static void clearHistory() => _history.clear();

  // ─── Main method ───────────────────────────────────────────────────────────
  static Future<String> sendMessage(String userMessage) async {
    if (AppSecrets.geminiApiKey.isEmpty ||
        AppSecrets.geminiApiKey == 'YOUR_API_KEY_HERE') {
      return '❌ API Key সেট করা হয়নি। Developer-কে জানান।';
    }

    _history.add({'role': 'user', 'content': userMessage});

    final messages = [
      {'role': 'system', 'content': cssAiSystemPrompt},
      ..._history,
    ];

    final url = Uri.parse(_baseUrl);
    final body = jsonEncode({
      'model': _model,
      'messages': messages,
      'max_tokens': 1024,
      'temperature': 0.7,
    });

    try {
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppSecrets.geminiApiKey}',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final text =
            data['choices']?[0]?['message']?['content'] as String? ??
                'দুঃখিত, উত্তর পাওয়া যায়নি।';
        _history.add({'role': 'assistant', 'content': text});
        return text;
      }

      _removeLastUserMessage();

      switch (response.statusCode) {
        case 401:
          return '❌ API Key ভুল। Developer-কে জানান।';
        case 429:
        // Wait 3 seconds and retry once
          await Future.delayed(const Duration(seconds: 3));
          return await _retry(url, body, userMessage);
        case 500:
        case 503:
          return 'Server সাময়িকভাবে বন্ধ আছে। একটু পরে চেষ্টা করুন।';
        default:
          return 'সংযোগে সমস্যা হয়েছে। (${response.statusCode})';
      }
    } on TimeoutException {
      _removeLastUserMessage();
      return 'সময় শেষ হয়ে গেছে। Internet connection চেক করুন।';
    } catch (e) {
      _removeLastUserMessage();
      if (e.toString().contains('SocketException')) {
        return 'Internet connection নেই। নেট চালু করে আবার চেষ্টা করুন।';
      }
      return 'সংযোগে সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }
  }

  // ─── Retry once ────────────────────────────────────────────────────────────
  static Future<String> _retry(
      Uri url, String body, String userMessage) async {
    _history.add({'role': 'user', 'content': userMessage});
    try {
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppSecrets.geminiApiKey}',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['choices']?[0]?['message']?['content'] as String? ??
                'দুঃখিত, উত্তর পাওয়া যায়নি।';
        _history.add({'role': 'assistant', 'content': text});
        return text;
      }

      _removeLastUserMessage();
      return 'একটু বেশি প্রশ্ন হয়ে গেছে। ৩০ সেকেন্ড পরে আবার চেষ্টা করুন।';
    } catch (e) {
      _removeLastUserMessage();
      return 'সংযোগে সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }
  }

  static void _removeLastUserMessage() {
    if (_history.isNotEmpty && _history.last['role'] == 'user') {
      _history.removeLast();
    }
  }
}