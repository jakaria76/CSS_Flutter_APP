import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/gallery_image_model.dart';

class GalleryPreviewSection extends StatelessWidget {
  final bool isLoading;
  final List<GalleryImage> images;
  final VoidCallback onViewAll;

  const GalleryPreviewSection({
    super.key,
    required this.isLoading,
    required this.images,
    required this.onViewAll,
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
                "স্মৃতির অ্যালবাম",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              if (images.isNotEmpty)
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
          height: 150,
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
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return Container(
                width: 140,
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
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: image.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.white10,
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