import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // থিম এবং ভাষা পরিবর্তনের জন্য লিসেনার ব্যবহার করা হয়েছে
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
        // Header Section
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

        // Video List Section
        SizedBox(
          height: 140,
          child: isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: SC.cyan,
              strokeWidth: 1,
            ),
          )
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              final videoId = YoutubePlayer.convertUrlToId(video.youtubeUrl);
              final thumbnailUrl = videoId != null
                  ? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg'
                  : '';

              return GestureDetector(
                onTap: onVideoTap,
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)]
                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail Image
                        CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDark ? Colors.white10 : Colors.black12,
                            child: const Icon(Icons.videocam_off_outlined),
                          ),
                        ),

                        // Dark Overlay
                        Container(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),

                        // Play Icon
                        Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: SC.cyan,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}