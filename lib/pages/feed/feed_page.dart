import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:css/models/post_model.dart';
import 'package:css/services/feed_service.dart';
import 'package:css/widgets/post_card.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'reaction_bar.dart';
import 'post_detail_page.dart';
import 'create_post_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with TickerProviderStateMixin {
  final FeedService _feedService = FeedService();
  final ScrollController _scrollController = ScrollController();

  List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  final int _pageSize = 5;

  late AnimationController _fabController;
  late AnimationController _headerController;
  bool _showFab = false;

  // ── Color tokens ────────────────────────────────────────────────────────────
  static const _darkBg       = Color(0xFF0D1117);
  static const _darkCard     = Color(0xFF161D2B);
  static const _darkAppBar   = Color(0xFF111827);
  static const _darkText     = Color(0xFFE8ECF4);
  static const _darkSub      = Color(0xFF8B95A7);
  static const _darkAccent   = Color(0xFF00C6FF);
  static const _darkAccent2  = Color(0xFF0072FF);

  static const _lightBg      = Color(0xFFF2F4F8);
  static const _lightCard    = Color(0xFFFFFFFF);
  static const _lightAppBar  = Color(0xFFFFFFFF);
  static const _lightText    = Color(0xFF0D1117);
  static const _lightSub     = Color(0xFF6B7280);
  static const _lightAccent  = Color(0xFF0055BB);
  static const _lightAccent2 = Color(0xFF003D8F);

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
    _headerController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPosts() async {
    setState(() {
      _isLoading = true;
      _currentOffset = 0;
      _hasMore = true;
    });
    try {
      final posts = await _feedService.fetchPosts(limit: _pageSize, offset: 0);
      if (mounted) {
        setState(() {
          _posts = posts;
          _currentOffset = posts.length;
          _hasMore = posts.length >= _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SC.toast(context, SC.tr('feedLoadError'), SC.red);
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final newPosts = await _feedService.fetchPosts(
          limit: _pageSize, offset: _currentOffset);
      if (mounted) {
        setState(() {
          if (newPosts.isEmpty) {
            _hasMore = false;
          } else {
            _posts.addAll(newPosts);
            _currentOffset += newPosts.length;
            _hasMore = newPosts.length >= _pageSize;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.85) {
      _loadMorePosts();
    }
    final show = _scrollController.offset > 300;
    if (show != _showFab) {
      setState(() => _showFab = show);
      show ? _fabController.forward() : _fabController.reverse();
    }
  }

  bool _isAdmin() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['role'] == 'admin';
  }

  Future<void> _goToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
    if (result == true) _loadInitialPosts();
  }

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
    final isDark = SC.isDark;

    final bgColor    = isDark ? _darkBg : _lightBg;
    final appBarColor = isDark ? _darkAppBar : _lightAppBar;
    final textColor  = isDark ? _darkText : _lightText;
    final accentColor = isDark ? _darkAccent : _lightAccent;
    final subColor   = isDark ? _darkSub : _lightSub;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(isDark, appBarColor, textColor, accentColor, subColor),
        body: RefreshIndicator(
          onRefresh: _loadInitialPosts,
          color: accentColor,
          backgroundColor: appBarColor,
          displacement: 50,
          child: _posts.isEmpty && !_isLoading
              ? _buildEmptyState(isDark, textColor, subColor, accentColor)
              : CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Create post bar (admin only)
              if (_isAdmin())
                SliverToBoxAdapter(
                  child: _buildCreatePostBar(
                      isDark, appBarColor, accentColor, subColor),
                ),

              SliverPadding(
                padding: const EdgeInsets.only(top: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, index) {
                      if (index == _posts.length) {
                        return _buildLoadingIndicator(
                            isDark, subColor, accentColor);
                      }
                      return _AnimatedPostItem(
                        index: index,
                        child: _PostWithReactions(
                          post: _posts[index],
                          bgColor: bgColor,
                          isDark: isDark,
                          onTap: () => _navigateToDetail(_posts[index]),
                          onPostUpdated: _loadInitialPosts,
                        ),
                      );
                    },
                    childCount: _posts.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
        floatingActionButton: ScaleTransition(
          scale: CurvedAnimation(
            parent: _fabController,
            curve: Curves.elasticOut,
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [_darkAccent, _darkAccent2]
                    : [_lightAccent, _lightAccent2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: FloatingActionButton.small(
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
// ── AppBar (Centered Title) ───────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark, Color appBarColor,
      Color textColor, Color accentColor, Color subColor) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: BoxDecoration(
          color: appBarColor,
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              width: 0.8,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack( // Title-ke ekebare center-e rakhar jonno Stack use kora hoyeche
              alignment: Alignment.center,
              children: [
                // Centered Title with gradient
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: isDark
                          ? [_darkAccent, _darkAccent2]
                          : [_lightAccent, _lightAccent2],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      SC.tr('feedTitle'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ),

                // Right side action (Create post button)
                if (_isAdmin())
                  Positioned(
                    right: 0,
                    child: _AppBarIconBtn(
                      icon: Icons.add_rounded,
                      isDark: isDark,
                      onTap: _goToCreatePost,
                      isAccent: true,
                      accentColor: accentColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Create post bar ───────────────────────────────────────────────────────
  Widget _buildCreatePostBar(
      bool isDark, Color cardColor, Color accentColor, Color subColor) {
    final fieldBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF2F4F8);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      color: cardColor,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [_darkAccent, _darkAccent2]
                    : [_lightAccent, _lightAccent2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),

          // Input field (fake)
          Expanded(
            child: GestureDetector(
              onTap: _goToCreatePost,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Text(
                  SC.tr('feedCreatePost'),
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.35),
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ),

          // Photo icon
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _goToCreatePost,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF0F2F5),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                color: accentColor,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(
      bool isDark, Color textColor, Color subColor, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.15),
                  accentColor.withValues(alpha: 0.03),
                ],
              ),
            ),
            child: Icon(
              Icons.dynamic_feed_rounded,
              size: 52,
              color: accentColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            SC.tr('feedEmpty'),
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            SC.tr('feedEmptySub'),
            style: TextStyle(color: subColor, fontSize: 14),
          ),
          if (_isAdmin()) ...[
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: isDark
                      ? [_darkAccent, _darkAccent2]
                      : [_lightAccent, _lightAccent2],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _goToCreatePost,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(SC.tr('feedFirstPost')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Loading indicator ─────────────────────────────────────────────────────
  Widget _buildLoadingIndicator(
      bool isDark, Color subColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: _isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              color: accentColor, strokeWidth: 2.5),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: subColor, size: 14),
            const SizedBox(width: 6),
            Text(
              SC.tr('feedAllShown'),
              style: TextStyle(color: subColor, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar Icon Button
// ─────────────────────────────────────────────────────────────────────────────
class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isAccent;
  final Color? accentColor;

  const _AppBarIconBtn({
    required this.icon,
    required this.isDark,
    this.onTap,
    this.isAccent = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isAccent
        ? accentColor!.withValues(alpha: 0.15)
        : (isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05));
    final iconColor = isAccent
        ? accentColor!
        : (isDark ? const Color(0xFFE8ECF4) : const Color(0xFF374151));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.8,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Post Item (stagger fade-slide-in)
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedPostItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedPostItem({required this.index, required this.child});

  @override
  State<_AnimatedPostItem> createState() => _AnimatedPostItemState();
}

class _AnimatedPostItemState extends State<_AnimatedPostItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    // Stagger delay capped at 300ms
    final delay = (widget.index * 80).clamp(0, 300);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post + Reactions card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _PostWithReactions extends StatelessWidget {
  final Post post;
  final Color bgColor;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onPostUpdated;

  const _PostWithReactions({
    required this.post,
    required this.bgColor,
    required this.isDark,
    required this.onTap,
    required this.onPostUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor   = isDark ? const Color(0xFF161D2B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: isDark
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PostCard(
                post: post,
                onTap: onTap,
                onCommentTap: onTap,
                onPostUpdated: onPostUpdated,
              ),
              ReactionBar(
                postId: post.id,
                postCaption: post.caption,
                onCommentTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}