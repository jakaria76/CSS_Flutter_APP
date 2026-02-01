import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/event_card.dart';

class EventsSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> events;
  final Color titleColor;
  final bool isLoading;
  final VoidCallback onViewAll;
  final Function(int eventId) onEventTap;

  const EventsSection({
    super.key,
    required this.title,
    required this.events,
    required this.titleColor,
    required this.isLoading,
    required this.onViewAll,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                if (events.isNotEmpty)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "সব দেখুন",
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Colors.cyanAccent,
                  strokeWidth: 1,
                ),
              ),
            )
          else if (events.isEmpty)
            _buildEmptyEventPlaceholder()
          else
            SizedBox(
              height: 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 15,
                  right: 15,
                  bottom: 15,
                  top: 5,
                ),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final bool past = _isPastEvent(event['start_datetime']);
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildGlassEventWrapper(event, past),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassEventWrapper(Map<String, dynamic> event, bool past) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: EventCard(
            event: event,
            isPast: past,
            onTap: past ? null : () {
              // Convert to int properly
              final eventId = event['id'];
              if (eventId != null) {
                onEventTap(eventId is int ? eventId : int.parse(eventId.toString()));
              }
            },
          ),
        ),
      ),
    );
  }

  bool _isPastEvent(String? startDate) {
    if (startDate == null) return false;
    final start = DateTime.parse(startDate).toLocal();
    return start.isBefore(DateTime.now());
  }

  Widget _buildEmptyEventPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(
          child: Text(
            "No events found",
            style: TextStyle(
              color: Colors.white10,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}