import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:css/models/comment_model.dart';
import 'package:css/models/post_model.dart';
import 'package:css/services/feed_service.dart';
import 'package:css/widgets/comment_tile.dart';
import 'package:css/widgets/post_card.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'reaction_bar.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with SingleTickerProviderStateMixin {
  final FeedService           _feedService       = FeedService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController      _scrollController  = ScrollController();
  final FocusNode             _focusNode         = FocusNode();

  List<Comment> _comments         = [];
  bool          _isLoading        = false;
  bool          _isPostingComment = false;
  late Post     _currentPost;

  late AnimationController _inputAnimController;
  bool _inputFocused = false;

  // ── Theme ────────────────────────────────────────────────────────────────
  static const _lightBg      = Color(0xFFF0F2F5);
  static const _lightCard    = Color(0xFFFFFFFF);
  static const _lightAppBar  = Color(0xFFFFFFFF);
  static const _lightText    = Color(0xFF050505);
  static const _lightSubText = Color(0xFF65676B);
  static const _lightDivider = Color(0xFFE4E6EB);
  static const _fbBlue       = Color(0xFF1877F2);

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _inputAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _focusNode.addListener(() {
      setState(() => _inputFocused = _focusNode.hasFocus);
      _inputFocused
          ? _inputAnimController.forward()
          : _inputAnimController.reverse();
    });
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _inputAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _feedService.fetchComments(_currentPost.id);
      if (mounted) {
        setState(() {
          _comments  = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SC.toast(context, SC.tr('postDetailLoadError'), SC.red);
      }
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      SC.toast(context, SC.tr('postDetailLoginError'), SC.red);
      return;
    }

    setState(() => _isPostingComment = true);
    try {
      await _feedService.addComment(postId: _currentPost.id, commentText: text);
      if (mounted) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        await _loadComments();
        setState(() {
          _currentPost = _currentPost.copyWith(
              commentCount: _currentPost.commentCount + 1);
        });
        SC.toast(context, SC.tr('postDetailCommentPosted'), SC.green);
      }
    } catch (e) {
      SC.toast(context, SC.tr('postDetailCommentError'), SC.red);
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final isDark    = SC.isDark;
    final dialogBg  = isDark ? const Color(0xFF242526) : _lightCard;
    final textColor = isDark ? const Color(0xFFE4E6EB) : _lightText;
    final subColor  = isDark ? const Color(0xFFB0B3B8) : _lightSubText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(SC.tr('postDetailDeleteCommentTitle'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        content: Text(SC.tr('postDetailDeleteCommentContent'),
            style: TextStyle(color: subColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(SC.tr('managePostCancel'),
                style: const TextStyle(color: _fbBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(SC.tr('managePostDeleteConfirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _feedService.deleteComment(comment.id);
      if (mounted) {
        await _loadComments();
        setState(() {
          _currentPost = _currentPost.copyWith(
              commentCount: _currentPost.commentCount - 1);
        });
        SC.toast(context, SC.tr('postDetailCommentDeleted'), SC.green);
      }
    } catch (e) {
      SC.toast(context, SC.tr('postDetailCommentDeleteError'), SC.red);
    }
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    final isDark       = SC.isDark;
    final bgColor      = isDark ? const Color(0xFF18191A) : _lightBg;
    final appBarColor  = isDark ? const Color(0xFF242526) : _lightAppBar;
    final textColor    = isDark ? const Color(0xFFE4E6EB) : _lightText;
    final subColor     = isDark ? const Color(0xFFB0B3B8) : _lightSubText;
    final dividerColor = isDark ? const Color(0xFF3E4042) : _lightDivider;
    final accentColor  = isDark ? const Color(0xFF2D88FF) : _fbBlue;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,

        // ── App Bar ────────────────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF3A3B3C)
                    : const Color(0xFFE4E6EB),
              ),
              child: Icon(Icons.arrow_back_rounded, color: textColor, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            SC.tr('postDetailTitle'),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),

        // ── Body ──────────────────────────────────────────────────────────
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Post Card ──────────────────────────────────────────
                    PostCard(post: _currentPost),

                    // ── Real Reaction Bar ──────────────────────────────────
                    Container(
                      color: isDark ? const Color(0xFF242526) : Colors.white,
                      child: Column(
                        children: [
                          Divider(height: 1, color: dividerColor),
                          ReactionBar(
                            postId: _currentPost.id,
                            onReacted: () {}, // optionally refresh post
                          ),
                          Divider(height: 1, color: dividerColor),
                        ],
                      ),
                    ),

                    // ── Comments Header ────────────────────────────────────
                    _buildCommentsHeader(
                        isDark, textColor, subColor, dividerColor, accentColor),

                    // ── Comments Body ──────────────────────────────────────
                    if (_isLoading)
                      _buildCommentsLoader()
                    else if (_comments.isEmpty)
                      _buildNoComments(isDark, subColor)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: _comments.length,
                        itemBuilder: (_, i) {
                          final comment = _comments[i];
                          final isOwner = comment.userId == currentUserId;
                          return CommentTile(
                            comment: comment,
                            isOwner: isOwner,
                            onDelete: isOwner
                                ? () => _deleteComment(comment)
                                : null,
                          );
                        },
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Comment Input Bar ──────────────────────────────────────────
            _buildCommentInput(
                isDark, textColor, subColor, dividerColor, accentColor),
          ],
        ),
      ),
    );
  }

  // ── Comments Header ───────────────────────────────────────────────────────
  Widget _buildCommentsHeader(
      bool isDark,
      Color textColor,
      Color subColor,
      Color dividerColor,
      Color accentColor,
      ) {
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;

    return Container(
      color: cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            SC.tr('postDetailComments'),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          GestureDetector(
            child: Row(
              children: [
                Text(
                  'সর্বশেষ',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: accentColor, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── No Comments ───────────────────────────────────────────────────────────
// ── No Comments (FIXED) ───────────────────────────────────────────────────
  Widget _buildNoComments(bool isDark, Color subColor) {
    return Center( // Puro content-ke screen-er majhkane anar jonno
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Vertically center
          crossAxisAlignment: CrossAxisAlignment.center, // Horizontally center
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 52,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              SC.tr('postDetailNoComments'), // "কোনো মন্তব্য নেই।"
              style: TextStyle(
                  color: subColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'প্রথম মন্তব্য করুন!', // Dubaar lekha chilo, ekhon ekbar deya hoyeche
              style: TextStyle(
                color: subColor.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  // ── Comments Loader ───────────────────────────────────────────────────────
  Widget _buildCommentsLoader() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          for (int i = 0; i < 3; i++) ...[
            _SkeletonComment(isDark: SC.isDark),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // ── Comment Input Bar ─────────────────────────────────────────────────────
  Widget _buildCommentInput(
      bool isDark,
      Color textColor,
      Color subColor,
      Color dividerColor,
      Color accentColor,
      ) {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    final barBg   = isDark ? const Color(0xFF242526) : Colors.white;
    final fieldBg = isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5);
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : const Color(0xFF65676B);

    return AnimatedBuilder(
      animation: _inputAnimController,
      builder: (_, __) {
        return Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: barBg,
            border: Border(top: BorderSide(color: dividerColor)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                    alpha: 0.1 + _inputAnimController.value * 0.1),
                blurRadius: 8 + _inputAnimController.value * 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withBlue(200)],
                  ),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),

              // Input field
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _inputFocused
                          ? accentColor.withValues(alpha: 0.5)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _focusNode,
                          enabled: isAuthenticated,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: isAuthenticated
                                ? SC.tr('postDetailCommentHint')
                                : SC.tr('postDetailLoginHint'),
                            hintStyle:
                            TextStyle(color: hintColor, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                          maxLines: 4,
                          minLines: 1,
                          maxLength: 500,
                          buildCounter: (_, {required currentLength,
                            required isFocused, maxLength}) => null,
                        ),
                      ),
                      Padding(
                        padding:
                        const EdgeInsets.only(bottom: 6, right: 10),
                        child: GestureDetector(
                          child: Icon(Icons.emoji_emotions_outlined,
                              color: subColor, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              AnimatedBuilder(
                animation: _commentController,
                builder: (_, __) {
                  final hasText =
                      _commentController.text.trim().isNotEmpty;
                  return GestureDetector(
                    onTap: isAuthenticated &&
                        !_isPostingComment &&
                        hasText
                        ? _postComment
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasText && isAuthenticated
                            ? accentColor
                            : accentColor.withValues(alpha: 0.3),
                      ),
                      child: _isPostingComment
                          ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Skeleton Comment ──────────────────────────────────────────────────────────
class _SkeletonComment extends StatefulWidget {
  final bool isDark;
  const _SkeletonComment({required this.isDark});

  @override
  State<_SkeletonComment> createState() => _SkeletonCommentState();
}

class _SkeletonCommentState extends State<_SkeletonComment>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark
        ? const Color(0xFF3A3B3C)
        : const Color(0xFFE4E6EB);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final color = base.withValues(alpha: _anim.value);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration:
              BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12, width: 120,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10, width: 180,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}