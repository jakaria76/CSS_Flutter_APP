import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/models/comment_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isOwner;
  final VoidCallback? onDelete;

  const CommentTile({
    Key? key,
    required this.comment,
    required this.isOwner,
    this.onDelete,
  }) : super(key: key);

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return SC.tr('just_now_short');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${SC.tr('minutes_ago_short')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${SC.tr('hours_ago_short')}';
    } else if (difference.inDays == 1) {
      return SC.tr('yesterday');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${SC.tr('days_ago_short')}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${SC.tr('weeks_ago_short')}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${SC.tr('months_ago_short')}';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${SC.tr('years_ago_short')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // থিম এবং ভাষা পরিবর্তনের জন্য লিসেনার
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildTile(context),
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF4A5568);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User header
                Row(
                  children: [
                    // User Profile Picture
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SC.cyan.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark ? const Color(0xFF1A2634) : Colors.grey.shade200,
                        backgroundImage: comment.hasProfileImage()
                            ? NetworkImage(comment.userImage!)
                            : null,
                        child: !comment.hasProfileImage()
                            ? Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey,
                        )
                            : null,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // User name and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.getDisplayName(),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(comment.createdAt),
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delete button (only for owner)
                    if (isOwner && onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: SC.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: SC.red,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Comment text
                Text(
                  comment.commentText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}