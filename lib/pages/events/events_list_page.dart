import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/widgets/event_card.dart';
import 'event_details_page.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> upcomingEvents = [];
  List<Map<String, dynamic>> pastEvents     = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    try {
      if (mounted) setState(() => loading = true);
      final res = await supabase
          .from('events')
          .select()
          .eq('is_published', true)
          .order('start_datetime', ascending: true);
      final List<Map<String, dynamic>> allEvents =
      List<Map<String, dynamic>>.from(res);
      final now = DateTime.now();
      if (!mounted) return;
      setState(() {
        upcomingEvents = allEvents
            .where((e) => DateTime.parse(e['start_datetime']).isAfter(now))
            .toList();
        pastEvents = allEvents
            .where((e) => DateTime.parse(e['start_datetime']).isBefore(now))
            .toList()
            .reversed
            .toList();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      SC.toast(context, SC.tr('failedLoadEventsMsg'), SC.red);
    }
  }

  void _goToEventDetails(int eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailsPage(eventId: eventId)),
    );
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
    final isDark      = SC.isDark;
    final textColor   = isDark ? Colors.white : const Color(0xFF1A2332);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textColor, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(SC.tr('cssEvents').toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: SC.cyan)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: SC.cyan.withOpacity(0.2),
                        border: Border.all(color: SC.cyan.withOpacity(0.5)),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: SC.cyan,
                      unselectedLabelColor: textColor.withValues(alpha: 0.4),
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.upcoming_rounded, size: 15),
                              const SizedBox(width: 6),
                              Text(SC.tr('upcomingTab').toUpperCase()),
                              if (upcomingEvents.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                _countBadge(upcomingEvents.length, SC.cyan),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_rounded, size: 15),
                              const SizedBox(width: 6),
                              Text(SC.tr('pastTab').toUpperCase()),
                              if (pastEvents.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                _countBadge(pastEvents.length,
                                    textColor.withValues(alpha: 0.5)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: SC.currentGradient),
          child: Stack(
            children: [
              Positioned(
                  top: -50, right: -50,
                  child: SC.blob(200, SC.cyan.withValues(alpha: 0.06))),
              Positioned(
                  bottom: 100, left: -50,
                  child: SC.blob(150, SC.red.withValues(alpha: 0.04))),
              SafeArea(
                child: loading
                    ? Center(child: CircularProgressIndicator(color: SC.cyan))
                    : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventsList(
                      events: upcomingEvents,
                      isPastList: false,
                      emptyIcon: Icons.event_available_outlined,
                      emptyText: SC.tr('noUpcomingEvents'),
                      emptySubText: SC.tr('newEventsAppear'),
                      isDark: isDark,
                      textColor: textColor,
                      borderColor: borderColor,
                    ),
                    _buildEventsList(
                      events: pastEvents,
                      isPastList: true,
                      emptyIcon: Icons.history_outlined,
                      emptyText: SC.tr('noPastEvents'),
                      emptySubText: SC.tr('pastEventsAppear'),
                      isDark: isDark,
                      textColor: textColor,
                      borderColor: borderColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList({
    required List<Map<String, dynamic>> events,
    required bool isPastList,
    required IconData emptyIcon,
    required String emptyText,
    required String emptySubText,
    required bool isDark,
    required Color textColor,
    required Color borderColor,
  }) {
    if (events.isEmpty) {
      return _buildEmptyState(emptyIcon, emptyText, emptySubText, textColor);
    }
    return RefreshIndicator(
      color: SC.cyan,
      backgroundColor: isDark ? SC.cardBg : Colors.white,
      onRefresh: fetchEvents,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildGlassEventWrapper(
                event, isPastList, isDark, textColor, borderColor),
          );
        },
      ),
    );
  }

  Widget _buildGlassEventWrapper(Map<String, dynamic> event, bool isPast,
      bool isDark, Color textColor, Color borderColor) {
    final cardBg = isDark
        ? Colors.white.withValues(alpha: isPast ? 0.03 : 0.06)
        : Colors.white.withValues(alpha: isPast ? 0.7 : 0.9);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPast
                  ? borderColor.withValues(alpha: 0.5)
                  : borderColor,
            ),
          ),
          child: Stack(
            children: [
              EventCard(
                event: event,
                isPast: isPast,
                onTap: () => _goToEventDetails(event['id']),
              ),
              if (isPast)
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.6)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            color: textColor.withValues(alpha: 0.5), size: 12),
                        const SizedBox(width: 4),
                        Text(SC.tr('past').toUpperCase(),
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$count',
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildEmptyState(
      IconData icon, String text, String subText, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor.withValues(alpha: 0.2), size: 80),
          const SizedBox(height: 16),
          Text(text,
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subText,
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.3), fontSize: 13)),
        ],
      ),
    );
  }
}