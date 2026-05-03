import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/event_card.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

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
    final textColor = isDark ? Colors.white : const Color(0xFF0F1923);
    final emptyBgColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);
    final emptyBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.07);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // Accent dot
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: titleColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: titleColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                if (events.isNotEmpty)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SC.cyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: SC.cyan.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            SC.tr('view_all_btn'),
                            style: TextStyle(
                              color: SC.cyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 8,
                            color: SC.cyan,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Loading ──
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: SC.cyan,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
            )

          // ── Empty State ──
          else if (events.isEmpty)
            _buildEmptyState(emptyBgColor, emptyBorderColor)

          // ── List ──
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 8, top: 4),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final bool past = _isPastEvent(event['start_datetime']);
                  final int? eventId = _parseId(event['id']);

                  return Container(
                    width: 230,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: EventCard(
                      event: event,
                      isPast: past,
                      onTap: eventId != null ? () => onEventTap(eventId) : null,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  bool _isPastEvent(String? startDate) {
    if (startDate == null) return false;
    try {
      return DateTime.parse(startDate).toLocal().isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  int? _parseId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    return int.tryParse(id.toString());
  }

  Widget _buildEmptyState(Color bgColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 14,
              color: SC.isDark ? Colors.white12 : Colors.black26,
            ),
            const SizedBox(width: 8),
            Text(
              SC.tr('no_events_found'),
              style: TextStyle(
                color: SC.isDark ? Colors.white12 : Colors.black26,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}