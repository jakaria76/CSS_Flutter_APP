import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_event_page.dart';

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({super.key});

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  bool actionLoading = false;
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      if (mounted) setState(() => loading = true);

      final res = await supabase
          .from('events')
          .select()
          .order('start_datetime', ascending: false);

      if (mounted) {
        setState(() {
          events = List<Map<String, dynamic>>.from(res);
          loading = false;
        });
      }
    } catch (_) {
      showMsg('Failed to load events');
      if (mounted) setState(() => loading = false);
    }
  }

  bool isPast(String? dt) {
    if (dt == null) return false;
    return DateTime.parse(dt).toLocal().isBefore(DateTime.now());
  }

  Future<void> updateStatus(int id, Map<String, dynamic> data) async {
    if (actionLoading) return;
    setState(() => actionLoading = true);

    try {
      await supabase.from('events').update(data).eq('id', id);
      fetchEvents();
    } catch (_) {
      showMsg('Failed to update event');
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> deleteEvent(int id) async {
    if (actionLoading) return;
    setState(() => actionLoading = true);

    try {
      await supabase.from('events').delete().eq('id', id);
      fetchEvents();
      showMsg('Event deleted successfully');
    } catch (_) {
      showMsg('Failed to delete event');
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,

        // ১. কাস্টম ব্যাক বাটন (গ্লাস ইফেক্টসহ)
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.cyanAccent,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),

        // ২. টাইটেল ডিজাইন
        title: const Text(
          'MANAGE EVENTS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18,
            color: Colors.cyanAccent,
          ),
        ),

        // ৩. রিফ্রেশ অ্যাকশন বাটন
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
            onPressed: fetchEvents, // আপনার ইভেন্ট লোড করার ফাংশন
          ),
          const SizedBox(width: 8), // ডানপাশে সামান্য গ্যাপ দেওয়ার জন্য
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
            Positioned(top: 100, right: -50, child: _blurCircle(200, Colors.cyanAccent.withValues(alpha: 0.1))),

            SafeArea(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : events.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                color: Colors.cyanAccent,
                onRefresh: fetchEvents,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) => _buildAdminEventCard(events[index]),
                ),
              ),
            ),
            if (actionLoading) _buildOverlayLoading(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminEventCard(Map<String, dynamic> e) {
    final past = isPast(e['start_datetime']);
    final int id = e['id'];
    final String? bannerUrl = e['banner_url'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ইভেন্ট ব্যানার ইমেজ যোগ করা হয়েছে ---
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: bannerUrl != null && bannerUrl.isNotEmpty
                          ? Image.network(
                        bannerUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                      )
                          : _buildImagePlaceholder(),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _badge(past ? 'PAST' : 'UPCOMING', past ? Colors.grey : Colors.blue),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (e['title'] ?? '').toString().toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e['start_datetime'] != null ? formatDate(e['start_datetime']) : 'No date',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _badge(e['is_published'] == true ? 'PUBLISHED' : 'DRAFT', e['is_published'] == true ? Colors.green : Colors.orange),
                          if (e['is_featured'] == true) _badge('FEATURED', Colors.purpleAccent),
                          _badge((e['price'] ?? 0) > 0 ? '৳${e['price']}' : 'FREE', Colors.cyanAccent),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white10, height: 1),
                      ),

                      // Controls
                      Row(
                        children: [
                          _statusSwitch('Live', e['is_published'] ?? false, (v) => updateStatus(id, {'is_published': v})),
                          const SizedBox(width: 20),
                          _statusSwitch('Feature', e['is_featured'] ?? false, (v) => updateStatus(id, {'is_featured': v})),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              icon: Icons.edit_note,
                              label: 'EDIT',
                              color: Colors.white.withValues(alpha: 0.1),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditEventPage(eventId: id))).then((_) => fetchEvents()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              icon: Icons.delete_sweep_outlined,
                              label: 'DELETE',
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              textColor: Colors.redAccent,
                              onTap: () => _confirmDelete(id),
                            ),
                          ),
                        ],
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

  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.05),
      child: const Icon(Icons.image_outlined, color: Colors.white24, size: 40),
    );
  }

  Widget _statusSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
        Transform.scale(
          scale: 0.7,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.cyanAccent,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, Color textColor = Colors.white, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF203A43),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Event?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
            TextButton(
              onPressed: () { Navigator.pop(context); deleteEvent(id); },
              child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayLoading() {
    return Container(
      color: Colors.black54,
      child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No events created yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
    );
  }

  Widget _blurCircle(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  String formatDate(String dt) {
    final d = DateTime.parse(dt).toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month-1]} ${d.year} • ${d.hour % 12 == 0 ? 12 : d.hour % 12}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: Colors.cyanAccent.withValues(alpha: 0.8))
    );
  }
}