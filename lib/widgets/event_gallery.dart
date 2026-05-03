import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart'; // আপনার প্রজেক্ট অনুযায়ী পাথ চেক করে নিন

class EventGallery extends StatelessWidget {
  final List<Map<String, dynamic>> images;

  const EventGallery({
    super.key,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    // থিম এবং ভাষা পরিবর্তনের জন্য লিসেনার
    // (সংশোধন: value_listenable পরিবর্তন করে valueListenable করা হয়েছে)
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildGallery(context),
      ),
    );
  }

  Widget _buildGallery(BuildContext context) {
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white38 : const Color(0xFF4A5568);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined, color: subTextColor, size: 40),
            const SizedBox(height: 8),
            Text(
              SC.tr('no_gallery'),
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: SC.cyan, size: 16),
            const SizedBox(width: 8),
            Text(
              SC.tr('event_moments'),
              style: TextStyle(
                color: isDark ? SC.cyan : textColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
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
                  width: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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
                        url != null && url.toString().isNotEmpty
                            ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _placeholder(cardBg);
                          },
                          errorBuilder: (_, __, ___) => _placeholder(cardBg),
                        )
                            : _placeholder(cardBg),

                        // ইমেজের ওপর হালকা গ্রেডিয়েন্ট ওভারলে
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Positioned(
                          bottom: 12,
                          right: 12,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black45,
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

  Widget _placeholder(Color bg) {
    return Container(
      width: 260,
      height: 180,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, size: 40, color: Colors.white12),
            const SizedBox(height: 10),
            CircularProgressIndicator(strokeWidth: 1, color: SC.cyan),
          ],
        ),
      ),
    );
  }
}