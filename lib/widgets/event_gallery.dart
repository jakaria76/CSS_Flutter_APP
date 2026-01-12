import 'dart:ui';
import 'package:flutter/material.dart';

class EventGallery extends StatelessWidget {
  final List<Map<String, dynamic>> images;

  const EventGallery({
    super.key,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Column(
          children: [
            Icon(Icons.photo_library_outlined, color: Colors.white24, size: 40),
            SizedBox(height: 8),
            Text(
              'No gallery images available',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 16),
            SizedBox(width: 8),
            Text(
              'EVENT MOMENTS',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 180, // উচ্চতা একটু বাড়ানো হয়েছে প্রিমিয়াম লুকের জন্য
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final url = images[index]['image_url'];

              return GestureDetector(
                onTap: () => _showFullScreenImage(context, url),
                child: Container(
                  margin: const EdgeInsets.only(right: 15),
                  width: 260, // কার্ডের প্রস্থ বাড়ানো হয়েছে
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ইমেজ লোডিং ইফেক্ট
                        url != null && url.toString().isNotEmpty
                            ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _placeholder();
                          },
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                            : _placeholder(),

                        // ইমেজের ওপর হালকা গ্রেডিয়েন্ট ওভারলে
                        Positioned.fill(
                          child: Container(
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

                        // জুম আইকন হিল্ট
                        const Positioned(
                          bottom: 12,
                          right: 12,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black26,
                            child: Icon(Icons.fullscreen, color: Colors.white, size: 18),
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

  // ফুল স্ক্রিন ইমেজ দেখার ফাংশন
  void _showFullScreenImage(BuildContext context, String? url) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: InteractiveViewer(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(url),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 260,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 40, color: Colors.white12),
            SizedBox(height: 10),
            CircularProgressIndicator(strokeWidth: 1, color: Colors.cyanAccent),
          ],
        ),
      ),
    );
  }
}