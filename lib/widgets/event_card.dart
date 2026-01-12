import 'dart:ui';
import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isPast;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.isPast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String? banner = event['banner_url']?.toString();
    final int price =
    event['price'] is num ? (event['price'] as num).toInt() : 0;

    return InkWell(
      onTap: isPast ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= IMAGE =================
                Stack(
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: banner != null && banner.isNotEmpty
                          ? Image.network(
                        banner,
                        fit: BoxFit.cover,
                        loadingBuilder:
                            (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            // ✅ image loaded successfully
                            return child;
                          }
                          return _placeholder();
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _placeholder();
                        },
                      )
                          : _placeholder(),
                    ),

                    // PRICE BADGE
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _badge(
                        price > 0 ? '৳$price' : 'FREE',
                        Colors.cyanAccent,
                      ),
                    ),

                    // PAST EVENT OVERLAY
                    if (isPast)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'PAST EVENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ================= CONTENT =================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title']?.toString() ?? 'No Title',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _info(
                        Icons.location_on,
                        event['venue']?.toString() ?? 'TBD',
                      ),
                      const SizedBox(height: 6),
                      _info(
                        Icons.calendar_today,
                        _formatDate(event['start_datetime']),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _placeholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.white.withOpacity(0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image,
        color: Colors.white38,
        size: 48,
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.cyanAccent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dt) {
    if (dt == null) return 'Date not set';
    try {
      final d = DateTime.parse(dt).toLocal();
      return '${d.day}/${d.month}/${d.year} • ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Invalid date';
    }
  }
}
