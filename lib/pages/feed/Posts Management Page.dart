import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:css/models/post_model.dart';
import 'package:css/services/feed_service.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/pages/feed/ManagePostPage.dart';
import 'create_post_page.dart';
import 'feed_widgets.dart';

class PostsManagementPage extends StatefulWidget {
  const PostsManagementPage({super.key});

  @override
  State<PostsManagementPage> createState() => _PostsManagementPageState();
}

class _PostsManagementPageState extends State<PostsManagementPage> {
  final FeedService      _feedService      = FeedService();
  final ScrollController _scrollController = ScrollController();

  List<Post> _posts         = [];
  bool       _isLoading     = false;
  bool       _hasMore       = true;
  int        _currentOffset = 0;
  final int  _pageSize      = 10;

  static const _lightBg     = Color(0xFFF0F4FF);
  static const _lightAppBar = Color(0xFFE4ECF9);
  static const _lightText   = Color(0xFF1A2332);
  static const _lightSubText= Color(0xFF4A5568);

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPosts() async {
    setState(() {
      _isLoading     = true;
      _currentOffset = 0;
      _hasMore       = true;
    });
    try {
      final posts =
      await _feedService.fetchPosts(limit: _pageSize, offset: 0);
      if (mounted) {
        setState(() {
          _posts         = posts;
          _currentOffset = posts.length;
          _hasMore       = posts.length >= _pageSize;
          _isLoading     = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SC.toast(context, SC.tr('postsManageLoadError'), SC.red);
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
  }

  Future<void> _goToEditPost(Post post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ManagePostPage(post: post)),
    );
    if (result == true) _loadInitialPosts();
  }

  Future<void> _goToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
    if (result == true) _loadInitialPosts();
  }

  String _formatDate(DateTime date, bool isDark) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1)  return SC.tr('postsManageJustNow');
    if (diff.inMinutes < 60) return '${diff.inMinutes}${SC.tr('postsManageMinAgo')}';
    if (diff.inHours   < 24) return '${diff.inHours}${SC.tr('postsManageHourAgo')}';
    if (diff.inDays    < 7)  return '${diff.inDays}${SC.tr('postsManageDayAgo')}';
    return '${date.day}/${date.month}/${date.year}';
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
    final isDark      = SC.isDark;
    final bgColor     = isDark ? SC.bgStart      : _lightBg;
    final appBarColor = isDark ? const Color(0xFF132D46) : _lightAppBar;
    final textColor   = isDark ? Colors.white    : _lightText;
    final subColor    = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : _lightSubText.withValues(alpha: 0.6);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(children: [
            Icon(Icons.manage_search_rounded, color: SC.cyan, size: 24),
            const SizedBox(width: 8),
            Text(SC.tr('postsManageTitle'),
                style: TextStyle(
                  fontWeight: FontWeight.bold, color: textColor,
                )),
          ]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [SC.cyan, SC.purple]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 20),
                ),
                onPressed: _goToCreatePost,
              ),
            ),
          ],
        ),
        body: Stack(children: [
          Positioned(
            top: -100, right: -100,
            child: BackgroundOrb(
                color: SC.cyan.withValues(alpha: isDark ? 0.05 : 0.04)),
          ),
          RefreshIndicator(
            onRefresh: _loadInitialPosts,
            color: SC.cyan,
            backgroundColor:
            isDark ? const Color(0xFF203A43) : _lightAppBar,
            child: _posts.isEmpty && !_isLoading
                ? _buildEmptyState(isDark, textColor, subColor)
                : ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length + (_hasMore ? 1 : 0),
              itemBuilder: (_, index) {
                if (index == _posts.length) {
                  return _buildLoadingIndicator(isDark, subColor);
                }
                return _buildPostCard(
                    _posts[index], isDark, textColor, subColor);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPostCard(
      Post post, bool isDark, Color textColor, Color subColor) {
    final cardBg = isDark
        ? LinearGradient(colors: [
      const Color(0xFF203A43).withValues(alpha: 0.8),
      const Color(0xFF2C5364).withValues(alpha: 0.6),
    ],
        begin: Alignment.topLeft, end: Alignment.bottomRight)
        : LinearGradient(colors: [
      Colors.white,
      const Color(0xFFEEF4FF),
    ],
        begin: Alignment.topLeft, end: Alignment.bottomRight);
    final borderColor = isDark
        ? SC.cyan.withValues(alpha: 0.2)
        : SC.cyan.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  SC.cyan.withValues(alpha: 0.3),
                  SC.purple.withValues(alpha: 0.3),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.article_rounded, color: SC.cyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${SC.tr('postsManagePostNum')}${_posts.indexOf(post) + 1}',
                      style: TextStyle(
                        color: textColor, fontSize: 14,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 2),
                  Text(_formatDate(post.createdAt, SC.isDark),
                      style: TextStyle(color: subColor, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SC.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit, color: SC.cyan, size: 18),
              ),
              onPressed: () => _goToEditPost(post),
            ),
          ]),
        ),

        // Caption preview
        if (post.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.caption.length > 100
                  ? '${post.caption.substring(0, 100)}...'
                  : post.caption,
              style: TextStyle(color: subColor, fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ),

        // Image preview
        if (post.images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: post.images.first,
                  width: 60, height: 60, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: isDark
                        ? Colors.grey.shade900
                        : Colors.grey.shade200,
                    child: Center(child: CircularProgressIndicator(
                        color: SC.cyan, strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: isDark
                        ? Colors.grey.shade900
                        : Colors.grey.shade200,
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (post.images.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${post.images.length - 1} ${SC.tr('postsManageMore')}',
                    style: TextStyle(
                        color: subColor, fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
            ]),
          ),

        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            _StatChip(icon: Icons.comment,
                label: '${post.commentCount}', color: SC.cyan),
            const SizedBox(width: 8),
            _StatChip(icon: Icons.image,
                label: '${post.images.length}', color: SC.purple),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEmptyState(
      bool isDark, Color textColor, Color subColor) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.post_add, size: 80,
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.12)),
        const SizedBox(height: 20),
        Text(SC.tr('postsManageEmpty'),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 18, fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 8),
        Text(SC.tr('postsManageEmptySub'),
            style: TextStyle(color: subColor, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _goToCreatePost,
          icon: const Icon(Icons.add),
          label: Text(SC.tr('feedFirstPost')),
          style: ElevatedButton.styleFrom(
            backgroundColor: SC.cyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12),
          ),
        ),
      ]),
    );
  }

  Widget _buildLoadingIndicator(bool isDark, Color subColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: _isLoading
            ? CircularProgressIndicator(color: SC.cyan, strokeWidth: 2)
            : Text(SC.tr('postsManageAllShown'),
            style: TextStyle(color: subColor, fontSize: 13)),
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600,
            )),
      ]),
    );
  }
}