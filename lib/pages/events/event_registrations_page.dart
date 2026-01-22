import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/registration_tile.dart';

class EventRegistrationsPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final String? bannerUrl; // ব্যানার ইমেজ দেখানোর জন্য নতুন প্যারামিটার

  const EventRegistrationsPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.bannerUrl,
  });

  @override
  State<EventRegistrationsPage> createState() =>
      _EventRegistrationsPageState();
}

class _EventRegistrationsPageState extends State<EventRegistrationsPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  bool onlyVolunteers = false;

  List<Map<String, dynamic>> registrations = [];

  @override
  void initState() {
    super.initState();
    fetchRegistrations();
  }

  Future<void> fetchRegistrations() async {
    try {
      if (mounted) setState(() => loading = true);

      final res = await supabase
          .from('event_registrations')
          .select()
          .eq('event_id', widget.eventId)
          .order('registered_at', ascending: true);

      if (mounted) {
        setState(() {
          registrations = List<Map<String, dynamic>>.from(res);
          loading = false;
        });
      }
    } catch (_) {
      showMsg('Failed to load registrations');
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = onlyVolunteers
        ? registrations.where((r) => r['will_volunteer'] == true).toList()
        : registrations;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'REGISTRATIONS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14),
            ),
            Text(
              widget.eventTitle,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            onPressed: fetchRegistrations,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Stack(
          children: [
            // --- ব্যাকগ্রাউন্ডে ইভেন্ট ইমেজ (নতুন যোগ করা হয়েছে) ---
            if (widget.bannerUrl != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15, // ইমেজটি হালকা দেখা যাবে
                  child: Image.network(
                    widget.bannerUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // ডেকোরেটিভ ব্লার সার্কেল
            Positioned(top: 100, right: -50, child: _blurCircle(180, Colors.cyanAccent.withValues(alpha: 0.1))),

            SafeArea(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : Column(
                children: [
                  _buildFilterHeader(filtered.length),
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                      color: Colors.cyanAccent,
                      onRefresh: fetchRegistrations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          // প্রথম আইটেমের আগে ছোট একটি ইমেজ প্রিভিউ কার্ড (অপশনাল)
                          if (index == 0 && widget.bannerUrl != null) {
                            return Column(
                              children: [
                                _buildEventThumbnail(),
                                const SizedBox(height: 16),
                                RegistrationTile(data: filtered[index]),
                              ],
                            );
                          }
                          return RegistrationTile(
                            data: filtered[index],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ইভেন্ট থাম্বনেইল উইজেট
  Widget _buildEventThumbnail() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: widget.bannerUrl != null
            ? DecorationImage(image: NetworkImage(widget.bannerUrl!), fit: BoxFit.cover)
            : null,
        border: Border.all(color: Colors.white10),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: const Text(
          "Event Overview",
          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PARTICIPANTS',
                        style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      Text(
                        '$count Joined',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                _volunteerToggle(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _volunteerToggle() {
    return Row(
      children: [
        Text(
          'VOLUNTEERS',
          style: TextStyle(
            color: onlyVolunteers ? Colors.cyanAccent : Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: onlyVolunteers,
            activeColor: Colors.cyanAccent,
            onChanged: (v) => setState(() => onlyVolunteers = v),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            onlyVolunteers ? 'No volunteers found' : 'No registrations yet',
            style: const TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.cyanAccent.withValues(alpha: 0.8),
      ),
    );
  }
}