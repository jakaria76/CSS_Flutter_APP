import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ভিডিও গ্যালারি",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  "সব দেখুন",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.cyanAccent,
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
              final videoId =
              YoutubePlayer.convertUrlToId(video.youtubeUrl);
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          color: Colors.black.withOpacity(0.4),
                        ),
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.cyanAccent,
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