import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/services/reaction_service.dart';

class ReactionBar extends StatefulWidget {
  final String postId;
  final String postCaption;
  final VoidCallback? onReacted;
  final VoidCallback? onCommentTap;

  const ReactionBar({
    super.key,
    required this.postId,
    this.postCaption = '',
    this.onReacted,
    this.onCommentTap,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar>
    with SingleTickerProviderStateMixin {
  final _service = ReactionService();
  RealtimeChannel? _channel;

  PostReactionState _state =
  const PostReactionState(counts: {}, myReaction: null);
  bool _loading = true;

  // Like button bounce animation
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bounceAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.35)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.35, end: 0.88)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.88, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30),
    ]).animate(_bounceController);

    _load();
    _channel = _service.subscribeToReactions(widget.postId, _load);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await _service.fetchReactions(widget.postId);
      if (mounted) setState(() { _state = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(ReactionType type) async {
    HapticFeedback.lightImpact();
    _bounceController.forward(from: 0);
    try {
      final updated = await _service.toggleReaction(widget.postId, type);
      if (mounted) setState(() => _state = updated);
      widget.onReacted?.call();
    } catch (_) {}
  }

  void _share() {
    final text = widget.postCaption.isNotEmpty
        ? widget.postCaption
        : 'CSS এর একটি পোস্ট দেখো!';
    Share.share(text);
  }

  // ── Emoji Picker Bottom Sheet ──────────────────────────────────────────────
  void _showPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
    isDark ? const Color(0xFF00C6FF) : const Color(0xFF0055BB);

    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final bg = isDark ? const Color(0xFF1E2535) : Colors.white;
        final borderColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06);

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 3.5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Picker label
                Text(
                  'রিঅ্যাকশন বেছে নাও',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),

                // Emoji row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ReactionType.values.map((type) {
                    final isActive = _state.myReaction == type;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _toggle(type);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? accentColor.withValues(alpha: 0.15)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isActive
                              ? Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 1.5,
                          )
                              : null,
                        ),
                        child: Text(
                          type.emoji,
                          style: TextStyle(
                            fontSize: isActive ? 34 : 27,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor =
    isDark ? const Color(0xFF8B95A7) : const Color(0xFF6B7280);
    final accentColor =
    isDark ? const Color(0xFF00C6FF) : const Color(0xFF0055BB);
    final divColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _shimmer(isDark, width: 60, height: 10),
            const SizedBox(width: 8),
            _shimmer(isDark, width: 40, height: 10),
          ],
        ),
      );
    }

    final myReaction = _state.myReaction;
    final total = _state.totalCount;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Reaction summary row ──────────────────────────────────────────
        if (total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Row(
              children: [
                // Stacked emoji bubbles
                SizedBox(
                  width: _topEmojis().length * 15.0 + 4,
                  height: 20,
                  child: Stack(
                    children: _topEmojis()
                        .asMap()
                        .entries
                        .map(
                          (e) => Positioned(
                        left: e.key * 14.0,
                        child: _EmojiCircle(
                            emoji: e.value.emoji, isDark: isDark),
                      ),
                    )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _summaryLabel(),
                  style: TextStyle(
                    color: subColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

        // ── Divider ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Divider(height: 1, color: divColor, thickness: 1),
        ),

        // ── Action buttons ────────────────────────────────────────────────
        IntrinsicHeight(
          child: Row(
            children: [
              // Like
              Expanded(
                child: _ActionBtn(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _bounceAnim,
                        child: myReaction != null
                            ? Text(
                          myReaction.emoji,
                          style: const TextStyle(fontSize: 16),
                        )
                            : Icon(
                          Icons.thumb_up_alt_outlined,
                          color: subColor,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        myReaction != null
                            ? _reactionLabel(myReaction)
                            : 'লাইক',
                        style: TextStyle(
                          color: myReaction != null ? accentColor : subColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _toggle(ReactionType.like),
                  onLongPress: () => _showPicker(context),
                ),
              ),

              _VertSep(color: divColor),

              // Comment
              Expanded(
                child: _ActionBtn(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: subColor, size: 17),
                      const SizedBox(width: 6),
                      Text('মন্তব্য',
                          style: TextStyle(
                            color: subColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                  onTap: widget.onCommentTap,
                ),
              ),

              _VertSep(color: divColor),

              // Share
              // Share button section
              Expanded(
                child: _ActionBtn(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Facebook style curved arrow share icon
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(3.14159), // Mirroring for that curved look
                        child: Icon(
                          Icons.reply_rounded,
                          color: subColor,
                          size: 20, // Ektu boro size Facebook-e thake
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('শেয়ার',
                          style: TextStyle(
                            color: subColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                  onTap: _share,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 3),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _shimmer(bool isDark, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  List<ReactionType> _topEmojis() {
    final sorted = _state.counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => ReactionTypeX.fromString(e.key)).toList();
  }

  String _summaryLabel() {
    final total = _state.totalCount;
    final my = _state.myReaction;
    if (my != null && total == 1) return 'তুমি';
    if (my != null) return 'তুমি এবং আরো ${total - 1} জন';
    return '$total জন';
  }

  String _reactionLabel(ReactionType type) {
    switch (type) {
      case ReactionType.like:  return 'লাইক';
      case ReactionType.love:  return 'লাভ';
      case ReactionType.haha:  return 'হাহা';
      case ReactionType.wow:   return 'ওয়াও';
      case ReactionType.sad:   return 'দুঃখিত';
      case ReactionType.angry: return 'রাগ';
    }
  }
}

// ── Action button wrapper ─────────────────────────────────────────────────────
class _ActionBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ActionBtn({
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 9),
        color: _pressed
            ? (isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03))
            : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}

// ── Vertical separator ────────────────────────────────────────────────────────
class _VertSep extends StatelessWidget {
  final Color color;
  const _VertSep({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.8,
      height: double.infinity,
      color: color,
    );
  }
}

// ── Emoji bubble ──────────────────────────────────────────────────────────────
class _EmojiCircle extends StatelessWidget {
  final String emoji;
  final bool isDark;
  const _EmojiCircle({required this.emoji, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF252D3F) : const Color(0xFFEEF0F4),
        border: Border.all(
          color: isDark ? const Color(0xFF161D2B) : Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 10)),
      ),
    );
  }
}