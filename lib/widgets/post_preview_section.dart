import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_model.dart';
import 'package:intl/intl.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class PostPreviewSection extends StatelessWidget {
  final bool isLoading;
  final List<Post> posts;
  final VoidCallback onViewAll;
  final Function(Post) onPostTap;

  const PostPreviewSection({
    Key? key,
    required this.isLoading,
    required this.posts,
    required this.onViewAll,
    required this.onPostTap,
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  SC.tr('admin_updates_header'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? SC.cyan : textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    SC.tr('view_all_arrow'),
                    style: TextStyle(color: SC.cyan, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Loading State
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: CircularProgressIndicator(color: SC.cyan),
              ),
            ),

          // Empty State
          if (!isLoading && posts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.post_add, size: 60, color: subTextColor.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text(
                      SC.tr('no_posts_found'),
                      style: TextStyle(color: subTextColor, fontSize: 16),
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
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildPostCard(context, post, isDark, textColor, subTextColor);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Post post, bool isDark, Color textColor, Color subTextColor) {
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: () => onPostTap(post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SC.cyan.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: SC.cyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SC.tr('admin_label_simple'),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(post.createdAt),
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Caption
            if ((post.caption ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  post.caption ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),

            // First Image Preview
            if (post.images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.images.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: isDark ? Colors.white10 : Colors.black12,
                        child: Icon(Icons.broken_image, color: subTextColor),
                      );
                    },
                  ),
                ),
              ),

            // Footer (Comment count)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 18,
                    color: subTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.commentCount} ${SC.tr('comments_count')}',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 13,
                    ),
                  ),
                  if (post.images.length > 1) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: SC.cyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${post.images.length - 1} ${SC.tr('more_photos')}',
                        style: TextStyle(
                          color: SC.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}