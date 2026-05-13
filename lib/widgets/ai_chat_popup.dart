import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/services/gemini_service.dart';

// ─── Chat message model ───────────────────────────────────────────────────────
class _ChatMessage {
  final String   text;
  final bool     isUser;
  final DateTime time;
  _ChatMessage({required this.text, required this.isUser, required this.time});
}

// ─── Main popup widget ────────────────────────────────────────────────────────
class AiChatPopup extends StatefulWidget {
  const AiChatPopup({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: true,
      builder: (_) => const AiChatPopup(),
    );
  }

  @override
  State<AiChatPopup> createState() => _AiChatPopupState();
}

class _AiChatPopupState extends State<AiChatPopup>
    with TickerProviderStateMixin {

  final TextEditingController _inputCtrl  = TextEditingController();
  final ScrollController      _scrollCtrl = ScrollController();
  final FocusNode             _focusNode  = FocusNode();

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _dotController;
  late AnimationController _statusPulseController;
  late AnimationController _sendBtnController;
  late AnimationController _avatarGlowController;
  late Animation<double>   _sendBtnScale;

  // ── State ─────────────────────────────────────────────────────────────────
  final List<_ChatMessage> _messages       = [];
  bool _isLoading         = false;
  bool _isLoadingKnowledge = false;
  bool _inputHasFocus     = false;

  // ── User info ─────────────────────────────────────────────────────────────
  String? _userName;
  String? _userAvatarUrl;

  static const List<String> _quickQuestions = [
    'রক্তদান কীভাবে করবো?',
    'ইভেন্টে রেজিস্ট্রেশন?',
    'প্রোফাইল এডিট করবো?',
    '2FA কীভাবে চালু করবো?',
  ];

  // ─── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _dotController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )..repeat();

    _statusPulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _avatarGlowController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _sendBtnController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120),
    );
    _sendBtnScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _sendBtnController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      if (mounted) setState(() => _inputHasFocus = _focusNode.hasFocus);
    });

    // ── Welcome message ────────────────────────────────────────────────────
    _messages.add(_ChatMessage(
      text:   'আসসালামুয়ালাইকুম! আমি CSS সহায়ক। CSS App ও সচেতন ছাত্র সমাজ সম্পর্কে যেকোনো প্রশ্ন করুন। 😊',
      isUser: false,
      time:   DateTime.now(),
    ));

    // ── Load user profile + knowledge ──────────────────────────────────────
    _loadUserProfile();
    _initKnowledge();
  }

  // ── Knowledge loading ─────────────────────────────────────────────────────
  // FIX: forceRefresh সরানো হয়েছে — cache valid থাকলে Supabase hit হবে না
  //      ফলে chat open করলে extra API call হবে না এবং দ্রুত load হবে
  Future<void> _initKnowledge() async {
    if (mounted) setState(() => _isLoadingKnowledge = true);
    await GeminiService.loadKnowledge(); // forceRefresh নেই = cache use করবে
    if (mounted) setState(() => _isLoadingKnowledge = false);
  }

  // ── User profile ──────────────────────────────────────────────────────────
  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, profile_image_url')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _userName      = data['full_name']         as String?;
          _userAvatarUrl = data['profile_image_url'] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _dotController.dispose();
    _statusPulseController.dispose();
    _avatarGlowController.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  // ─── Send message ─────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Knowledge এখনো load না হলে wait করো
    if (_isLoadingKnowledge) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('তথ্য লোড হচ্ছে, একটু অপেক্ষা করুন...'),
          backgroundColor: SC.cyan.withValues(alpha: 0.9),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    await _sendBtnController.forward();
    _sendBtnController.reverse();
    _inputCtrl.clear();

    setState(() {
      _messages.add(
          _ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    final reply = await GeminiService.sendMessage(text);

    if (mounted) {
      setState(() {
        _messages.add(
            _ChatMessage(text: reply, isUser: false, time: DateTime.now()));
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
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // FIX: _clearChat-এ শুধু history clear হবে, knowledge refresh হবে না
  //      শুধু admin panel থেকে content update হলে refreshKnowledge() call করো
  void _clearChat() {
    HapticFeedback.mediumImpact();
    GeminiService.clearHistory();
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage(
        text: 'চ্যাট clear করা হয়েছে। আবার জিজ্ঞেস করুন! 😊',
        isUser: false,
        time: DateTime.now(),
      ));
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (_, __, ___) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (_, __, ___) => _buildPopup(),
      ),
    );
  }

  Widget _buildPopup() {
    final isDark    = SC.isDark;
    final screenH   = MediaQuery.of(context).size.height;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    final bgColor   = isDark ? const Color(0xFF080F1C) : Colors.white;
    final bubbleAi  = isDark ? const Color(0xFF131F30) : const Color(0xFFF0F4FF);
    final borderCol = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);
    final textCol   = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final subCol    = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF6B7280);
    final inputBg   = isDark ? const Color(0xFF0F1A2B) : const Color(0xFFF1F5F9);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardH),
      child: Container(
        height: screenH * 0.80,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderCol),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.14),
              blurRadius: 32,
              spreadRadius: 0,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(isDark, borderCol, textCol, subCol),

            // ── Knowledge loading banner ───────────────────────────────────
            if (_isLoadingKnowledge)
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                color: SC.cyan.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: SC.cyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'তথ্য লোড হচ্ছে...',
                      style: TextStyle(
                        color: SC.cyan,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Messages ──────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_isLoading && i == _messages.length) {
                    return _buildTypingIndicator(isDark, bubbleAi, borderCol);
                  }
                  return _buildBubble(
                      _messages[i], isDark, textCol, bubbleAi, borderCol);
                },
              ),
            ),

            // ── Quick questions ────────────────────────────────────────────
            if (_messages.length == 1 && !_isLoading)
              _buildQuickQuestions(isDark, subCol),

            _buildInputArea(isDark, inputBg, textCol, subCol, borderCol),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(
      bool isDark, Color borderCol, Color textCol, Color subCol) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderCol, width: 0.8)),
        color: isDark
            ? const Color(0xFF080F1C).withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.97),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Drag handle
          Container(
            width: 38, height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _buildAiAvatar(size: 42, iconSize: 20),
                const SizedBox(width: 11),

                // Title + status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CSS সহায়ক',
                        style: TextStyle(
                          color: textCol,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _statusPulseController,
                            builder: (_, __) {
                              final glow =
                                  4.0 + _statusPulseController.value * 5.0;
                              return Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isLoadingKnowledge
                                      ? Colors.orange
                                      : const Color(0xFF2ECC71),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isLoadingKnowledge
                                          ? Colors.orange
                                          : const Color(0xFF2ECC71))
                                          .withValues(alpha: 0.6),
                                      blurRadius: glow,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isLoadingKnowledge ? 'লোড হচ্ছে...' : 'সক্রিয়',
                            style:
                            TextStyle(color: subCol, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // User name + avatar
                if (_userName != null || _userAvatarUrl != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_userName != null)
                        Text(
                          _userName!,
                          style: TextStyle(
                            color: textCol,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Text('আপনি',
                          style: TextStyle(color: subCol, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  _buildUserAvatar(size: 36),
                  const SizedBox(width: 4),
                ],

                // Clear + close
                if (_messages.length > 1)
                  _buildIconBtn(
                    icon:    Icons.refresh_rounded,
                    color:   subCol,
                    onTap:   _clearChat,
                    tooltip: 'চ্যাট ক্লিয়ার',
                  ),
                _buildIconBtn(
                  icon:    Icons.close_rounded,
                  color:   subCol,
                  onTap:   () => Navigator.pop(context),
                  tooltip: 'বন্ধ করুন',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ─── AI Avatar ────────────────────────────────────────────────────────────
  Widget _buildAiAvatar({required double size, required double iconSize}) {
    return AnimatedBuilder(
      animation: _avatarGlowController,
      builder: (_, __) {
        final glow        = 8.0  + _avatarGlowController.value * 14.0;
        final ringOpacity = 0.15 + _avatarGlowController.value * 0.25;
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C8FF).withValues(alpha: 0.45),
                blurRadius: glow,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/css_chat_icon.png',
                  width: size, height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: ringOpacity),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── User Avatar ──────────────────────────────────────────────────────────
  Widget _buildUserAvatar({double size = 28}) {
    final isDark = SC.isDark;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? const Color(0xFF131F30)
            : const Color(0xFFE8F4FD),
        border: Border.all(
          color: const Color(0xFF00C8FF).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C8FF).withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipOval(
        child: _userAvatarUrl != null
            ? Image.network(
          _userAvatarUrl!,
          width: size, height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _userInitialWidget(size),
        )
            : _userInitialWidget(size),
      ),
    );
  }

  Widget _userInitialWidget(double size) {
    if (_userName != null && _userName!.isNotEmpty) {
      return Container(
        color: const Color(0xFF00C8FF).withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Text(
          _userName![0].toUpperCase(),
          style: TextStyle(
            color: SC.cyan,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Icon(Icons.person_rounded, color: SC.cyan, size: size * 0.55);
  }

  // ─── Icon button ──────────────────────────────────────────────────────────
  Widget _buildIconBtn({
    required IconData    icon,
    required Color       color,
    required VoidCallback onTap,
    required String      tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 34, height: 34,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // ─── Message bubble ───────────────────────────────────────────────────────
  Widget _buildBubble(_ChatMessage msg, bool isDark, Color textCol,
      Color bubbleAi, Color borderCol) {
    final isUser = msg.isUser;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, (1 - val) * 12),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              _buildAiAvatar(size: 28, iconSize: 13),
              const SizedBox(width: 7),
            ],

            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.73,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                    colors: [Color(0xFF00CFFF), Color(0xFF0055FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: isUser ? null : bubbleAi,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: borderCol, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? const Color(0xFF0072FF).withValues(alpha: 0.25)
                          : Colors.black
                          .withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: isUser
                        ? Colors.white
                        : (isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF0D1B2A)),
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
              ),
            ),

            if (isUser) ...[
              const SizedBox(width: 7),
              _buildUserAvatar(size: 28),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Typing indicator ─────────────────────────────────────────────────────
  Widget _buildTypingIndicator(
      bool isDark, Color bubbleAi, Color borderCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAiAvatar(size: 28, iconSize: 13),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: bubbleAi,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(18),
                topRight:    Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft:  Radius.circular(4),
              ),
              border: Border.all(color: borderCol, width: 0.8),
            ),
            child: AnimatedBuilder(
              animation: _dotController,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay  = i * 0.28;
                  final raw    = (_dotController.value - delay) % 1.0;
                  final t      = raw.clamp(0.0, 1.0);
                  final bounce = math.sin(t * math.pi);
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Transform.translate(
                      offset: Offset(0, -bounce * 5),
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SC.cyan
                              .withValues(alpha: 0.5 + bounce * 0.5),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick questions ──────────────────────────────────────────────────────
  Widget _buildQuickQuestions(bool isDark, Color subCol) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(
              'সাধারণ প্রশ্ন:',
              style: TextStyle(
                color: subCol,
                fontSize: 10.5,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _quickQuestions.map((q) => _QuickChip(
              label:  q,
              isDark: isDark,
              onTap:  () {
                _inputCtrl.text = q;
                _sendMessage();
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Input area ───────────────────────────────────────────────────────────
  Widget _buildInputArea(bool isDark, Color inputBg, Color textCol,
      Color subCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderCol, width: 0.8)),
        color: isDark ? const Color(0xFF080F1C) : Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildUserAvatar(size: 32),
          const SizedBox(width: 8),

          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _inputHasFocus
                      ? const Color(0xFF00C8FF).withValues(alpha: 0.55)
                      : const Color(0xFF00C8FF).withValues(alpha: 0.18),
                  width: _inputHasFocus ? 1.2 : 1.0,
                ),
                boxShadow: _inputHasFocus
                    ? [
                  BoxShadow(
                    color: const Color(0xFF00C8FF)
                        .withValues(alpha: 0.10),
                    blurRadius: 12,
                  ),
                ]
                    : null,
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode:  _focusNode,
                style: TextStyle(
                    color: textCol, fontSize: 13.5, height: 1.4),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'CSS App সম্পর্কে জিজ্ঞেস করুন...',
                  hintStyle: TextStyle(color: subCol, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                ),
              ),
            ),
          ),

          const SizedBox(width: 9),

          ScaleTransition(
            scale: _sendBtnScale,
            child: GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isLoading
                      ? null
                      : const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0055FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  color: _isLoading
                      ? (isDark
                      ? const Color(0xFF131F30)
                      : const Color(0xFFF1F5F9))
                      : null,
                  boxShadow: _isLoading
                      ? null
                      : [
                    BoxShadow(
                      color: const Color(0xFF00C8FF)
                          .withValues(alpha: 0.40),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(
                  _isLoading
                      ? Icons.hourglass_empty_rounded
                      : Icons.send_rounded,
                  color: _isLoading ? subCol : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick chip widget ────────────────────────────────────────────────────────
class _QuickChip extends StatefulWidget {
  final String        label;
  final bool          isDark;
  final VoidCallback  onTap;

  const _QuickChip({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_QuickChip> createState() => _QuickChipState();
}

class _QuickChipState extends State<_QuickChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFF00C8FF).withValues(alpha: 0.15)
              : (widget.isDark
              ? const Color(0xFF0F1A2B)
              : const Color(0xFFEFF6FF)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _pressed
                ? const Color(0xFF00C8FF).withValues(alpha: 0.6)
                : const Color(0xFF00C8FF).withValues(alpha: 0.28),
            width: _pressed ? 1.2 : 1.0,
          ),
          boxShadow: _pressed
              ? [
            BoxShadow(
              color: const Color(0xFF00C8FF).withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ]
              : null,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: SC.cyan,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}