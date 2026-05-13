import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/services/gemini_service.dart';

// ─── Chat message model ───────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

// ─── Main popup widget (BottomSheet হিসেবে call করো) ─────────────────────────
class AiChatPopup extends StatefulWidget {
  const AiChatPopup({super.key});

  /// Home page থেকে এইভাবে call করো:
  /// ```dart
  /// AiChatPopup.show(context);
  /// ```
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => const AiChatPopup(),
    );
  }

  @override
  State<AiChatPopup> createState() => _AiChatPopupState();
}

class _AiChatPopupState extends State<AiChatPopup>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _dotController;

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  // ─── Greeting message ─────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Welcome message
    _messages.add(_ChatMessage(
      text:
      'আসসালামুয়ালাইকুম! আমি CSS সহায়ক। CSS App ও সচেতন ছাত্র সমাজ সম্পর্কে যেকোনো প্রশ্ন করুন। 😊',
      isUser: false,
      time: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _dotController.dispose();
    super.dispose();
  }

  // ─── Send message ─────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    HapticFeedback.lightImpact();
    _inputCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    final reply = await GeminiService.sendMessage(text);

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(
          text: reply,
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Quick questions ──────────────────────────────────────────────────────
  static const List<String> _quickQuestions = [
    'রক্তদান কীভাবে করবো?',
    'ইভেন্টে রেজিস্ট্রেশন কীভাবে?',
    'প্রোফাইল কীভাবে এডিট করবো?',
    '2FA কীভাবে চালু করবো?',
  ];

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildPopup(),
      ),
    );
  }

  Widget _buildPopup() {
    final isDark = SC.isDark;
    final screenH = MediaQuery.of(context).size.height;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    // Colors
    final bgColor = isDark ? const Color(0xFF0A1628) : Colors.white;
    final cardColor = isDark ? const Color(0xFF0F1E2E) : const Color(0xFFF8FAFF);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF6B7280);
    final inputBg = isDark ? const Color(0xFF162030) : const Color(0xFFF1F5F9);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardH),
      child: Container(
        height: screenH * 0.78,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? SC.cyan.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Handle bar ──────────────────────────────────────────────────
            _buildHandle(isDark, borderColor, textColor, subColor),

            // ── Messages list ───────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount:
                _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_isLoading && i == _messages.length) {
                    return _buildTypingIndicator(isDark);
                  }
                  final msg = _messages[i];
                  return _buildMessageBubble(
                      msg, isDark, textColor, cardColor, borderColor);
                },
              ),
            ),

            // ── Quick questions (শুধু শুরুতে দেখাবে) ─────────────────────
            if (_messages.length == 1 && !_isLoading)
              _buildQuickQuestions(isDark, subColor),

            // ── Input area ──────────────────────────────────────────────────
            _buildInputArea(isDark, inputBg, textColor, subColor, borderColor),
          ],
        ),
      ),
    );
  }

  // ─── Handle bar & header ──────────────────────────────────────────────────
  Widget _buildHandle(
      bool isDark, Color borderColor, Color textColor, Color subColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // AI Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SC.cyan.withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),

                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CSS সহায়ক',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'সক্রিয়',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Clear button
                if (_messages.length > 1)
                  IconButton(
                    onPressed: () {
                      GeminiService.clearHistory();
                      setState(() {
                        _messages.clear();
                        _messages.add(_ChatMessage(
                          text:
                          'চ্যাট পরিষ্কার করা হয়েছে। আবার জিজ্ঞেস করুন! 😊',
                          isUser: false,
                          time: DateTime.now(),
                        ));
                      });
                    },
                    icon: Icon(Icons.refresh_rounded,
                        color: subColor, size: 20),
                    tooltip: 'চ্যাট পরিষ্কার করুন',
                  ),

                // Close button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: subColor, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ─── Message bubble ───────────────────────────────────────────────────────
  Widget _buildMessageBubble(_ChatMessage msg, bool isDark, Color textColor,
      Color cardColor, Color borderColor) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar (left side)
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 6),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isUser
                    ? null
                    : (isDark
                    ? const Color(0xFF162030)
                    : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? SC.cyan.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF1A2332)),
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
          ),

          // User avatar (right side)
          if (isUser) ...[
            const SizedBox(width: 6),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF162030)
                    : const Color(0xFFE8F4FD),
                border: Border.all(
                    color: SC.cyan.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.person_rounded,
                  color: SC.cyan, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Typing indicator ─────────────────────────────────────────────────────
  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF162030)
                  : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _dotController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.3;
                    final val = ((_dotController.value - delay) % 1.0)
                        .clamp(0.0, 1.0);
                    final opacity =
                    (val < 0.5 ? val * 2 : (1 - val) * 2).clamp(0.3, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SC.cyan,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick questions ──────────────────────────────────────────────────────
  Widget _buildQuickQuestions(bool isDark, Color subColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'সাধারণ প্রশ্ন:',
            style: TextStyle(color: subColor, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickQuestions.map((q) {
              return GestureDetector(
                onTap: () {
                  _inputCtrl.text = q;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF162030)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: SC.cyan.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    q,
                    style: TextStyle(
                      color: SC.cyan,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Input area ───────────────────────────────────────────────────────────
  Widget _buildInputArea(bool isDark, Color inputBg, Color textColor,
      Color subColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
        color: isDark ? const Color(0xFF0A1628) : Colors.white,
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: SC.cyan.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                style: TextStyle(color: textColor, fontSize: 14),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'CSS App সম্পর্কে জিজ্ঞেস করুন...',
                  hintStyle:
                  TextStyle(color: subColor, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                color: _isLoading
                    ? (isDark
                    ? const Color(0xFF162030)
                    : const Color(0xFFF1F5F9))
                    : null,
                boxShadow: _isLoading
                    ? null
                    : [
                  BoxShadow(
                    color: SC.cyan.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                _isLoading
                    ? Icons.hourglass_empty_rounded
                    : Icons.send_rounded,
                color: _isLoading ? subColor : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}