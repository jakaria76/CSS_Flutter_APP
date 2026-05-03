import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import '../pages/feed/post_detail_page.dart';
import '../pages/feed/feed_page.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class DashboardPostSection extends StatelessWidget {
  final bool isLoading;
  final List<Post> posts;

  const DashboardPostSection({
    Key? key,
    required this.isLoading,
    required this.posts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildSection(context),
      ),
    );
  }

  Widget _buildSection(BuildContext context) {
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF4A5568);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SC.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.campaign,
                      color: SC.cyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    SC.tr('admin_updates_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? SC.cyan : textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _navigateToFeed(context),
                child: Row(
                  children: [
                    Text(
                      SC.tr('view_all_short'),
                      style: TextStyle(
                        color: SC.cyan,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: SC.cyan,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Loading State
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(
                color: SC.cyan,
                strokeWidth: 2,
              ),
            ),
          ),

        // Empty State
        if (!isLoading && posts.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.post_add_outlined,
                    size: 56,
                    color: subTextColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    SC.tr('no_posts'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    SC.tr('no_updates_yet'),
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Posts List
        if (!isLoading && posts.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                onTap: () => _navigateToPostDetail(context, post),
                onCommentTap: () => _navigateToPostDetail(context, post),
              );
            },
          ),

        // See More Button
        if (!isLoading && posts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Center(
              child: TextButton.icon(
                onPressed: () => _navigateToFeed(context),
                icon: Icon(Icons.arrow_forward, size: 18, color: SC.cyan),
                label: Text(
                  SC.tr('see_more_posts'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SC.cyan,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: SC.cyan.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: SC.cyan.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _navigateToFeed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FeedPage()),
    );
  }

  void _navigateToPostDetail(BuildContext context, Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailPage(post: post)),
    );
  }
}