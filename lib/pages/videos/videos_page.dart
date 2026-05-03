import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:css/services/video_service.dart';
import 'package:css/models/video_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> with TickerProviderStateMixin {
  final service = VideoService();
  List<Video> videos = [];
  bool isLoading = true;
  String? errorMessage;
  String _searchQuery = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    loadVideos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadVideos() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final fetched = await service.fetchVideos();
      if (mounted) {
        setState(() {
          videos = fetched;
          isLoading = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = SC.tr('videoLoadError');
          isLoading = false;
        });
      }
    }
  }

  List<Video> get _filteredVideos {
    if (_searchQuery.isEmpty) return videos;
    return videos
        .where((v) =>
        v.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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
    final bgColor = isDark ? SC.bgStart : const Color(0xFFF0F4FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            _buildBackgroundOrbs(isDark),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(isDark, textColor, borderColor, fillColor),
                if (isLoading)
                  SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(color: SC.cyan)),
                  )
                else if (errorMessage != null)
                  SliverFillRemaining(
                      child: _buildErrorState(textColor, isDark))
                else if (_filteredVideos.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState(textColor))
                  else
                    _buildVideoList(isDark, textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs(bool isDark) {
    return Stack(
      children: [
        Positioned(
            top: 100,
            left: -50,
            child: _orb(300, SC.cyan.withValues(alpha: isDark ? 0.05 : 0.03))),
        Positioned(
            bottom: 100,
            right: -50,
            child: _orb(
                400, SC.purple.withValues(alpha: isDark ? 0.05 : 0.03))),
      ],
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)
      ],
    ),
  );

  Widget _buildSliverAppBar(bool isDark, Color textColor, Color borderColor,
      Color fillColor) {
    final subTextColor = isDark
        ? Colors.white24
        : Colors.black.withValues(alpha: 0.3);

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? SC.bgStart : const Color(0xFFF0F4FF),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child:
          Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
                decoration: BoxDecoration(gradient: SC.currentGradient)),
            Positioned(
              right: 20,
              bottom: 100,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.play_circle_filled,
                    size: 100, color: SC.cyan),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SC.cyan,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      SC.tr('videos'),
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    SC.tr('videoGallery'),
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: textColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: SC.tr('searchVideo'),
                  hintStyle:
                  TextStyle(color: subTextColor, fontSize: 14),
                  prefixIcon:
                  Icon(Icons.search_rounded, color: SC.cyan),
                  filled: true,
                  fillColor: fillColor,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                          color: SC.cyan.withValues(alpha: 0.3))),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoList(bool isDark, Color textColor) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final v = _filteredVideos[index];
            return FadeTransition(
              opacity: _animationController,
              child: VideoCard(
                key: ValueKey(v.id),
                video: v,
                totalCount: _filteredVideos.length,
                index: index,
                isDark: isDark,
                textColor: textColor,
              ),
            );
          },
          childCount: _filteredVideos.length,
        ),
      ),
    );
  }

  Widget _buildErrorState(Color textColor, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: SC.red),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? SC.tr('errorOccurred'),
            style:
            TextStyle(color: textColor.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: loadVideos,
            style: ElevatedButton.styleFrom(backgroundColor: SC.cyan),
            child: Text(SC.tr('retryBtn'),
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined,
              size: 80,
              color: textColor.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            SC.tr('noVideoFound'),
            style: TextStyle(
                color: textColor.withValues(alpha: 0.25),
                fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════
// VIDEO CARD
// ══════════════════════════════════════
class VideoCard extends StatefulWidget {
  final Video video;
  final int totalCount;
  final int index;
  final bool isDark;
  final Color textColor;

  const VideoCard({
    super.key,
    required this.video,
    required this.totalCount,
    required this.index,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late YoutubePlayerController _controller;
  String? videoId;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    videoId = YoutubePlayer.convertUrlToId(widget.video.youtubeUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      // handle state
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (videoId == null) return const SizedBox.shrink();

    final isDark = widget.isDark;
    final textColor = widget.textColor;
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final subColor =
    isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF4A5568);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: SC.cyan,
              bottomActions: [
                const SizedBox(width: 14.0),
                CurrentPosition(),
                const SizedBox(width: 8.0),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
                const PlaybackSpeedButton(),
              ],
              onReady: () => _isPlayerReady = true,
              onEnded: (_) => _controller.pause(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.play_circle_outline,
                          size: 16,
                          color: SC.cyan.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        '${SC.tr('videoCount')} ${widget.index + 1} ${SC.tr('of')} ${widget.totalCount}',
                        style: TextStyle(color: subColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}