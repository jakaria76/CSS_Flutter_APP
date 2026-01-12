import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:css/pages/events/event_register_page.dart';
import 'package:css/registrations/event_registrations_page.dart';

class EventDetailsPage extends StatefulWidget {
  final int eventId;
  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? event;
  List<Map<String, dynamic>> gallery = [];
  bool loading = true;
  String? error;
  String? userRole;
  Timer? _timer;
  Duration? remaining;

  @override
  void initState() {
    super.initState();
    loadEvent();
    _checkUserRole();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final data = await supabase.from('profiles').select('role').eq('id', user.id).maybeSingle();
      if (mounted) setState(() => userRole = data?['role']?.toString().toLowerCase());
    }
  }

  Future<void> loadEvent() async {
    try {
      final e = await supabase.from('events').select().eq('id', widget.eventId).maybeSingle();
      if (e == null) {
        setState(() { error = 'Event not found'; loading = false; });
        return;
      }
      final imgs = await supabase.from('event_images').select().eq('event_id', widget.eventId);
      event = Map<String, dynamic>.from(e);
      gallery = List<Map<String, dynamic>>.from(imgs);
      setupCountdown();
    } catch (e) {
      error = 'Failed to load event';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void setupCountdown() {
    final start = DateTime.parse(event!['start_datetime']).toLocal();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = start.difference(DateTime.now());
      if (!mounted) return;
      setState(() => remaining = diff.isNegative ? Duration.zero : diff);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(backgroundColor: Color(0xFF0F2027), body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeroBanner(),
                _buildDetailsContent(),
              ],
            ),
          ),

          _buildStickyActionButton(),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    final banner = event!['banner_url'];
    return Stack(
      children: [
        Hero(
          tag: 'event_${widget.eventId}',
          child: Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              image: banner != null ? DecorationImage(image: NetworkImage(banner), fit: BoxFit.cover) : null,
              color: Colors.grey.shade900,
            ),
            child: banner == null ? const Icon(Icons.image, size: 100, color: Colors.white24) : null,
          ),
        ),
        Container(
          height: 350,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.3), Colors.transparent, const Color(0xFF0F2027)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsContent() {
    final price = (event!['price'] ?? 0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _priceBadge(price),
          const SizedBox(height: 15),
          Text(
            event!['title'] ?? '',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
          ),
          const SizedBox(height: 15),

          // Info Card
          _glassContainer(
            child: Column(
              children: [
                _infoTile(Icons.calendar_month, "Date & Time", formatDate(event!['start_datetime'])),
                const Divider(color: Colors.white10),
                _infoTile(Icons.location_on, "Venue", event!['venue'] ?? 'TBD'),
                if (remaining != null) ...[
                  const Divider(color: Colors.white10),
                  _infoTile(Icons.timer_outlined, "Countdown", countdownText(remaining!), color: Colors.cyanAccent),
                ]
              ],
            ),
          ),

          if (userRole == 'admin') ...[
            const SizedBox(height: 15),
            _adminAction(),
          ],

          const SizedBox(height: 25),
          const Text('ABOUT EVENT', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Text(
            event!['full_description'] ?? 'No description provided.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.6),
          ),

          const SizedBox(height: 25),
          if (gallery.isNotEmpty) _buildGallery(),

          const SizedBox(height: 20),
          _glassButton(icon: Icons.map_outlined, label: "OPEN IN GOOGLE MAPS", onTap: openMap),

          const SizedBox(height: 120), // Space for sticky button
        ],
      ),
    );
  }

  Widget _glassContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _infoTile(IconData icon, String title, String subtitle, {Color? color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (color ?? Colors.white).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color ?? Colors.white70, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        )
      ],
    );
  }

  Widget _priceBadge(double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: price > 0 ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: price > 0 ? Colors.orange : Colors.green),
      ),
      child: Text(
        price > 0 ? '৳ ${price.toInt()}' : 'FREE ENTRY',
        style: TextStyle(color: price > 0 ? Colors.orange : Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }

  Widget _buildGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GALLERY', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: gallery.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 15),
                width: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: NetworkImage(gallery[index]['image_url']), fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _adminAction() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventRegistrationsPage(eventId: widget.eventId, eventTitle: event!['title'] ?? 'Event'))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.3), Colors.blue.withOpacity(0.3)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            SizedBox(width: 10),
            Text("VIEW REGISTRATIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _glassButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyActionButton() {
    final bool isClosed = remaining == Duration.zero;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, const Color(0xFF0F2027).withOpacity(0.8), const Color(0xFF0F2027)],
          ),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isClosed ? Colors.grey : Colors.cyanAccent,
            foregroundColor: const Color(0xFF0F2027),
            padding: const EdgeInsets.all(18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            shadowColor: Colors.cyanAccent.withOpacity(0.3),
          ),
          onPressed: isClosed ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventRegisterPage(eventId: event!['id'], price: (event!['price'] ?? 0).toDouble()))),
          child: Text(
            isClosed ? 'REGISTRATION CLOSED' : 'REGISTER NOW',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  String formatDate(String dt) {
    final d = DateTime.parse(dt).toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year} • ${d.hour % 12 == 0 ? 12 : d.hour % 12}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  String countdownText(Duration d) {
    if (d == Duration.zero) return "Event Started";
    return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
  }

  void openMap() async {
    final lat = event!['latitude'];
    final lng = event!['longitude'];
    if (lat == null || lng == null) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}