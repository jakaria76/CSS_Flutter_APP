import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import 'package:css/pages/feed/ManagePostPage.dart';
import 'package:css/pages/feed/FullscreenImageViewer.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onPostUpdated;

  const PostCard({
    Key? key,
    required this.post,
    this.onTap,
    this.onCommentTap,
    this.onPostUpdated,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  bool _isAdmin() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    final isOwner = user.id == widget.post.adminId;
    final isAdminRole = user.userMetadata?['role'] == 'admin';
    return isOwner && isAdminRole;
  }

  Future<void> _navigateToEditPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ManagePostPage(post: widget.post)),
    );
    if (result == true) widget.onPostUpdated?.call();
  }

  void _openImageViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          images: widget.post.images,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => FadeTransition(
          opacity: _fadeAnim,
          child: _buildPostCard(context),
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context) {
    final isDark = SC.isDark;

    final textColor = isDark ? const Color(0xFFE8ECF4) : const Color(0xFF0D1117);
    final subTextColor = isDark ? const Color(0xFF8B95A7) : const Color(0xFF6B7280);
    final adminBadgeBg = isDark
        ? const Color(0xFF00C6FF).withValues(alpha: 0.12)
        : const Color(0xFF0066CC).withValues(alpha: 0.08);
    final adminBadgeColor =
    isDark ? const Color(0xFF00C6FF) : const Color(0xFF0055BB);
    final editBtnBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF00C6FF), const Color(0xFF0072FF)]
                          : [const Color(0xFF0066CC), const Color(0xFF004499)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFF00C6FF).withValues(alpha: 0.30)
                            : const Color(0xFF0055BB).withValues(alpha: 0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      'assets/images/csslogo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            SC.tr('css_admin'),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: adminBadgeBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: adminBadgeColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              SC.tr('admin_label'),
                              style: TextStyle(
                                color: adminBadgeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 11, color: subTextColor),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(widget.post.createdAt),
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: subTextColor.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.public_rounded,
                              size: 11, color: subTextColor),
                          const SizedBox(width: 3),
                          Text(
                            'সবার জন্য',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isAdmin())
                  GestureDetector(
                    onTap: _navigateToEditPost,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: editBtnBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: adminBadgeColor,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Caption ─────────────────────────────────────────────────────
          if (widget.post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.caption,
                    maxLines: _isExpanded ? null : 3,
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (widget.post.caption.length > 120)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _isExpanded ? 'Show less' : 'See more',
                          style: TextStyle(
                            color: adminBadgeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Facebook-style Image Grid ────────────────────────────────────
          if (widget.post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _buildFacebookGrid(isDark),
            ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ── Facebook Grid ────────────────────────────────────────────────────────
  Widget _buildFacebookGrid(bool isDark) {
    final images = widget.post.images;
    final count = images.length;

    if (count == 1) {
      return _gridImage(images[0], isDark,
          height: 280,
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openImageViewer(0));
    }

    if (count == 2) {
      return Row(
        children: [
          Expanded(
            child: _gridImage(images[0], isDark,
                height: 220,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                onTap: () => _openImageViewer(0)),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _gridImage(images[1], isDark,
                height: 220,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                onTap: () => _openImageViewer(1)),
          ),
        ],
      );
    }

    if (count == 3) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _gridImage(images[0], isDark,
                height: 220,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                onTap: () => _openImageViewer(0)),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                _gridImage(images[1], isDark,
                    height: 109,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                    ),
                    onTap: () => _openImageViewer(1)),
                const SizedBox(height: 2),
                _gridImage(images[2], isDark,
                    height: 109,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(14),
                    ),
                    onTap: () => _openImageViewer(2)),
              ],
            ),
          ),
        ],
      );
    }

    if (count == 4) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _gridImage(images[0], isDark,
                    height: 160,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                    ),
                    onTap: () => _openImageViewer(0)),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _gridImage(images[1], isDark,
                    height: 160,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                    ),
                    onTap: () => _openImageViewer(1)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: _gridImage(images[2], isDark,
                    height: 160,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                    ),
                    onTap: () => _openImageViewer(2)),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _gridImage(images[3], isDark,
                    height: 160,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(14),
                    ),
                    onTap: () => _openImageViewer(3)),
              ),
            ],
          ),
        ],
      );
    }

    // 5+ images
    final remaining = count - 4;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _gridImage(images[0], isDark,
                  height: 160,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                  ),
                  onTap: () => _openImageViewer(0)),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: _gridImage(images[1], isDark,
                  height: 160,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                  ),
                  onTap: () => _openImageViewer(1)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: _gridImage(images[2], isDark,
                  height: 130,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                  ),
                  onTap: () => _openImageViewer(2)),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: _gridImage(images[3], isDark,
                  height: 130,
                  borderRadius: BorderRadius.zero,
                  onTap: () => _openImageViewer(3)),
            ),
            const SizedBox(width: 2),
            // +remaining overlay
            Expanded(
              child: GestureDetector(
                onTap: () => _openImageViewer(4),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: images[4],
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        height: 130,
                        color: Colors.black.withValues(alpha: 0.55),
                        child: Center(
                          child: Text(
                            '+$remaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _gridImage(
      String url,
      bool isDark, {
        required double height,
        BorderRadius borderRadius = BorderRadius.zero,
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E2535), const Color(0xFF252D3F)]
                      : [const Color(0xFFEEF0F4), const Color(0xFFE4E7ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: isDark
                      ? const Color(0xFF00C6FF)
                      : const Color(0xFF0055BB),
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: isDark
                  ? const Color(0xFF1E2535)
                  : const Color(0xFFEEF0F4),
              child: Icon(
                Icons.broken_image_rounded,
                color: isDark ? Colors.white24 : Colors.black26,
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return SC.tr('just_now');
    if (diff.inMinutes < 60)
      return '${diff.inMinutes} ${SC.tr('minutes_ago')}';
    if (diff.inHours < 24) return '${diff.inHours} ${SC.tr('hours_ago')}';
    if (diff.inDays < 7) return '${diff.inDays} ${SC.tr('days_ago')}';
    return DateFormat('dd MMM yyyy').format(date);
  }
}