import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/constants/app_secrets.dart';

class GeminiService {
  GeminiService._();

  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model   = 'llama-3.1-8b-instant';

  // ── Cache ──────────────────────────────────────────────────────────────────
  static const String _cacheKey     = 'ai_knowledge_cache';
  static const String _cacheTimeKey = 'ai_knowledge_cache_time';
  static const int    _cacheHours   = 24;

  // ── Chat history ───────────────────────────────────────────────────────────
  static final List<Map<String, dynamic>> _history = [];
  static const int _maxHistoryTurns = 6;

  // ── Knowledge ─────────────────────────────────────────────────────────────
  static String _knowledgeBase   = '';
  static bool   _knowledgeLoaded = false;
  static bool get isKnowledgeLoaded => _knowledgeLoaded;

  // ── Cooldown ───────────────────────────────────────────────────────────────
  static DateTime? _lastRequestTime;
  static const int _cooldownSeconds = 2;

  // ── Base system prompt ─────────────────────────────────────────────────────
  static const String _basePrompt =
      'তুমি CSS App-এর AI Assistant "CSS সহায়ক"। বন্ধুর মতো helpful।\n'
      'User যে ভাষায় লেখে সেই ভাষায় উত্তর দাও (Bengali/English/Banglish)।\n'
      'Short & clear উত্তর, 1-2 emoji যথেষ্ট।\n'
      'শুধু CSS App ও CSS organization নিয়ে উত্তর দাও।\n'
      'তথ্য না জানলে: consciousstudentsociety@gmail.com জানাও।\n'
      'Password বা OTP কখনো চাইবে না।\n';

  // ══════════════════════════════════════════════════════════════════════════
  // Knowledge load — app start বা chat open-এ একবার call করো
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> loadKnowledge({bool forceRefresh = false}) async {
    if (_knowledgeLoaded && !forceRefresh) return;

    final prefs = await SharedPreferences.getInstance();

    // Cache valid কিনা চেক করো
    if (!forceRefresh) {
      final cachedTime  = prefs.getInt(_cacheTimeKey) ?? 0;
      final hoursPassed = (DateTime.now().millisecondsSinceEpoch - cachedTime)
          / (1000 * 60 * 60);

      if (hoursPassed < _cacheHours) {
        final cached = prefs.getString(_cacheKey);
        if (cached != null && cached.isNotEmpty) {
          _knowledgeBase  = cached;
          _knowledgeLoaded = true;
          return;
        }
      }
    }

    // Supabase থেকে fetch
    try {
      final rows = await Supabase.instance.client
          .from('ai_knowledge')
          .select('category, title, content')
          .eq('is_active', true)
          .order('id');

      final buf = StringBuffer('[CSS APP KNOWLEDGE]\n');
      for (final row in rows) {
        final title   = (row['title'] as String?)?.isNotEmpty == true
            ? row['title']
            : row['category'];
        final content = row['content'] as String? ?? '';
        buf.writeln('\n[$title]\n$content');
      }

      _knowledgeBase  = buf.toString();
      _knowledgeLoaded = true;

      await prefs.setString(_cacheKey, _knowledgeBase);
      await prefs.setInt(
          _cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Supabase fail → cache ব্যবহার করো
      final cached = prefs.getString(_cacheKey);
      _knowledgeBase  = cached?.isNotEmpty == true
          ? cached!
          : 'CSS App: Conscious Student Society Bangladesh.\nEmail: consciousstudentsociety@gmail.com';
      _knowledgeLoaded = true;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Send message
  // ══════════════════════════════════════════════════════════════════════════
  static Future<String> sendMessage(String userMessage) async {
    if (AppSecrets.geminiApiKey.isEmpty ||
        AppSecrets.geminiApiKey == 'YOUR_API_KEY_HERE') {
      return '❌ API Key সেট করা হয়নি। Developer-কে জানান।';
    }

    // Cooldown
    if (_lastRequestTime != null) {
      final diff = DateTime.now().difference(_lastRequestTime!).inSeconds;
      if (diff < _cooldownSeconds) {
        return '⏳ ${_cooldownSeconds - diff} সেকেন্ড অপেক্ষা করো!';
      }
    }
    _lastRequestTime = DateTime.now();

    // Knowledge load (না থাকলে)
    if (!_knowledgeLoaded) await loadKnowledge();

    _history.add({'role': 'user', 'content': userMessage});

    final recentHistory = _history.length > _maxHistoryTurns
        ? _history.sublist(_history.length - _maxHistoryTurns)
        : List<Map<String, dynamic>>.from(_history);

    final messages = [
      {'role': 'system', 'content': '$_basePrompt\n$_knowledgeBase'},
      ...recentHistory,
    ];

    final body = jsonEncode({
      'model'      : _model,
      'messages'   : messages,
      'max_tokens' : 512,
      'temperature': 0.6,
    });

    try {
      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type' : 'application/json',
          'Authorization': 'Bearer ${AppSecrets.geminiApiKey}',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] as String?
            ?? 'দুঃখিত, উত্তর পাওয়া যায়নি।';
        _history.add({'role': 'assistant', 'content': text});
        return text;
      }

      _removeLastUserMessage();

      switch (response.statusCode) {
        case 401:  return '❌ API Key ভুল। Developer-কে জানান।';
        case 413:
          clearHistory();
          return '❌ বেশি তথ্য হয়ে গেছে। চ্যাট clear করে আবার চেষ্টা করো।';
        case 429:  return '⏳ লিমিট শেষ। ৩০ সেকেন্ড পরে আবার চেষ্টা করো।';
        case 500:
        case 503:  return 'Server সাময়িকভাবে বন্ধ আছে। একটু পরে চেষ্টা করো।';
        default:   return 'সংযোগে সমস্যা হয়েছে। (${response.statusCode})';
      }
    } on TimeoutException {
      _removeLastUserMessage();
      return 'সময় শেষ হয়ে গেছে। Internet চেক করুন।';
    } catch (e) {
      _removeLastUserMessage();
      if (e.toString().contains('SocketException')) {
        return 'Internet নেই। নেট চালু করে চেষ্টা করুন।';
      }
      return 'সংযোগে সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> refreshKnowledge() async {
    _knowledgeLoaded = false;
    await loadKnowledge(forceRefresh: true);
  }

  static void clearHistory() => _history.clear();

  static void _removeLastUserMessage() {
    if (_history.isNotEmpty && _history.last['role'] == 'user') {
      _history.removeLast();
    }
  }
}