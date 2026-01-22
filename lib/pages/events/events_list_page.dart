import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:css/widgets/event_card.dart';
import 'event_details_page.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      if (mounted) {
        setState(() => loading = true);
      }

      final res = await supabase
          .from('events')
          .select()
          .eq('is_published', true)
          .order('start_datetime', ascending: true);

      if (!mounted) return;

      setState(() {
        events = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to load events'),
          backgroundColor: Colors.redAccent.withOpacity(0.85),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool isPastEvent(String? startDate) {
    if (startDate == null) return false;
    final start = DateTime.parse(startDate).toLocal();
    return start.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,

        // কাস্টম ব্যাক বাটন যোগ করা হয়েছে
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05), // হালকা গ্লাস ইফেক্ট
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.cyanAccent, size: 18),
          ),
          onPressed: () => Navigator.pop(context), // পেজটি বন্ধ করে আগের পেজে যাবে
        ),

        title: const Text(
          'CSS EVENTS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.cyanAccent,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative blur circles
            Positioned(
              top: -50,
              right: -50,
              child: _blurCircle(
                200,
                Colors.cyanAccent.withOpacity(0.1),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: _blurCircle(
                150,
                Colors.redAccent.withOpacity(0.05),
              ),
            ),

            SafeArea(
              child: loading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.cyanAccent,
                ),
              )
                  : RefreshIndicator(
                color: Colors.cyanAccent,
                backgroundColor: const Color(0xFF203A43),
                onRefresh: fetchEvents,
                child: events.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final bool past =
                    isPastEvent(event['start_datetime']);

                    return Padding(
                      padding:
                      const EdgeInsets.only(bottom: 20),
                      child:
                      _buildGlassEventWrapper(event, past),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Glass-style wrapper for event card
  Widget _buildGlassEventWrapper(
      Map<String, dynamic> event, bool past) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: EventCard(
            event: event,
            isPast: past,
            onTap: past
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EventDetailsPage(eventId: event['id']),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'No events found',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
