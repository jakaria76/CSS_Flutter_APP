import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class VideoPreviewSection extends StatelessWidget {
  final bool isLoading;
  final List<Video> videos;
  final VoidCallback onViewAll;
  final VoidCallback onVideoTap;

  const VideoPreviewSection({
    super.key,
    required this.isLoading,
    required this.videos,
    required this.onViewAll,
    required this.onVideoTap,
  });

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
    final subTextColor = isDark ? Colors.white38 : const Color(0xFF4A5568);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                SC.tr('video_gallery_title'),
                style: TextStyle(
                  color: isDark ? SC.cyan : textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  SC.tr('view_all_btn'),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Horizontal Scrollable Video Cards ────────────────────────────────
        if (isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: SC.cyan, strokeWidth: 1),
            ),
          )
        else
          SizedBox(
            height: 210, // মোট card height — বাড়ালে/কমালে size বদলাবে
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                return _DashboardVideoCard(
                  video: videos[index],
                  isDark: isDark,
                  textColor: textColor,
                );
              },
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Dashboard Video Card — horizontal, inline YouTube player সহ
// ══════════════════════════════════════════════════════════════════════════════
class _DashboardVideoCard extends StatefulWidget {
  final Video video;
  final bool isDark;
  final Color textColor;

  const _DashboardVideoCard({
    required this.video,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<_DashboardVideoCard> createState() => _DashboardVideoCardState();
}

class _DashboardVideoCardState extends State<_DashboardVideoCard> {
  YoutubePlayerController? _controller;
  bool _playerOpen = false;
  bool _isPlayerReady = false;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = YoutubePlayer.convertUrlToId(widget.video.youtubeUrl);
  }

  void _openPlayer() {
    if (_videoId == null) return;
    setState(() {
      _playerOpen = true;
      _controller = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
        ),
      );
    });
  }

  void _closePlayer() {
    _controller?.pause();
    _controller?.dispose();
    setState(() {
      _controller = null;
      _playerOpen = false;
      _isPlayerReady = false;
    });
  }

  @override
  void deactivate() {
    _controller?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null) return const SizedBox.shrink();

    final isDark = widget.isDark;
    final textColor = widget.textColor;
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFF4A5568);

    final thumbnailUrl = 'https://img.youtube.com/vi/$_videoId/hqdefault.jpg';

    return Container(
      width: 220, // card width — বাড়ালে/কমালে চওড়া বদলাবে
      margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Video / Thumbnail Area ────────────────────────────────────────
            Expanded(
              child: _playerOpen && _controller != null
                  ? YoutubePlayer(
                controller: _controller!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: SC.cyan,
                bottomActions: [
                  const SizedBox(width: 8),
                  CurrentPosition(),
                  const SizedBox(width: 4),
                  ProgressBar(isExpanded: true),
                  RemainingDuration(),
                  const PlaybackSpeedButton(),
                ],
                onReady: () => setState(() => _isPlayerReady = true),
                onEnded: (_) => _closePlayer(),
              )
                  : GestureDetector(
                onTap: _openPlayer,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail
                    CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? const Color(0xFF1A2A3A)
                            : const Color(0xFFE8EEF4),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: SC.cyan,
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => CachedNetworkImage(
                        imageUrl:
                        'https://img.youtube.com/vi/$_videoId/mqdefault.jpg',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: isDark
                              ? const Color(0xFF1A2A3A)
                              : const Color(0xFFE8EEF4),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: isDark
                              ? const Color(0xFF1A2A3A)
                              : const Color(0xFFE8EEF4),
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            size: 36,
                            color: SC.cyan.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),

                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Play Button
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Title + Close ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (_playerOpen) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _closePlayer,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: subColor,
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