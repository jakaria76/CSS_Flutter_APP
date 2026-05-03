import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_event_page.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

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
      SC.toast(context, SC.tr('failedLoadEvents'), SC.red);
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
      SC.toast(context, SC.tr('failedUpdateEvent'), SC.red);
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
      SC.toast(context, SC.tr('eventDeleted'), SC.green);
    } catch (_) {
      SC.toast(context, SC.tr('failedDeleteEvent'), SC.red);
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
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
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
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
          title: Text(
            SC.tr('manageEvents').toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 18,
              color: SC.cyan,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: SC.cyan),
              onPressed: fetchEvents,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: SC.currentGradient),
          child: Stack(
            children: [
              Positioned(
                top: 100,
                right: -50,
                child: SC.blob(200, SC.cyan.withValues(alpha: 0.08)),
              ),
              SafeArea(
                child: loading
                    ? Center(child: CircularProgressIndicator(color: SC.cyan))
                    : events.isEmpty
                    ? _buildEmptyState(textColor)
                    : RefreshIndicator(
                  color: SC.cyan,
                  onRefresh: fetchEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) =>
                        _buildAdminEventCard(events[index], isDark, textColor, borderColor),
                  ),
                ),
              ),
              if (actionLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                      child: CircularProgressIndicator(color: SC.cyan)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminEventCard(
      Map<String, dynamic> e,
      bool isDark,
      Color textColor,
      Color borderColor,
      ) {
    final past = isPast(e['start_datetime']);
    final int id = e['id'];
    final String? bannerUrl = e['banner_url'];
    final cardColor = isDark ? SC.cardBg : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                      child: bannerUrl != null && bannerUrl.isNotEmpty
                          ? Image.network(
                        bannerUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildImagePlaceholder(isDark),
                      )
                          : _buildImagePlaceholder(isDark),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _badge(
                        past ? SC.tr('past') : SC.tr('upcoming'),
                        past ? Colors.grey : Colors.blue,
                      ),
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
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e['start_datetime'] != null
                            ? formatDate(e['start_datetime'])
                            : SC.tr('noDate'),
                        style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _badge(
                            e['is_published'] == true
                                ? SC.tr('published')
                                : SC.tr('draft'),
                            e['is_published'] == true
                                ? Colors.green
                                : Colors.orange,
                          ),
                          if (e['is_featured'] == true)
                            _badge(SC.tr('featured'), Colors.purpleAccent),
                          _badge(
                            (e['price'] ?? 0) > 0
                                ? '৳${e['price']}'
                                : SC.tr('free'),
                            SC.cyan,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: borderColor, height: 1),
                      ),
                      Row(
                        children: [
                          _statusSwitch(
                            SC.tr('live'),
                            e['is_published'] ?? false,
                            textColor,
                                (v) => updateStatus(id, {'is_published': v}),
                          ),
                          const SizedBox(width: 20),
                          _statusSwitch(
                            SC.tr('feature'),
                            e['is_featured'] ?? false,
                            textColor,
                                (v) => updateStatus(id, {'is_featured': v}),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              icon: Icons.edit_note,
                              label: SC.tr('edit').toUpperCase(),
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.06),
                              textColor: textColor,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditEventPage(eventId: id),
                                ),
                              ).then((_) => fetchEvents()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              icon: Icons.delete_sweep_outlined,
                              label: SC.tr('delete').toUpperCase(),
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              textColor: Colors.redAccent,
                              onTap: () => _confirmDelete(id, isDark),
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

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      height: 150,
      width: double.infinity,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04),
      child: Icon(Icons.image_outlined,
          color: isDark ? Colors.white24 : Colors.black26, size: 40),
    );
  }

  Widget _statusSwitch(
      String label, bool value, Color textColor, Function(bool) onChanged) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        Transform.scale(
          scale: 0.7,
          child: Switch(value: value, onChanged: onChanged, activeColor: SC.cyan),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id, bool isDark) {
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: cardColor,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(SC.tr('deleteEvent'),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Text(SC.tr('deleteWarning'),
              style: TextStyle(color: textColor.withValues(alpha: 0.6))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(SC.tr('cancel'),
                  style: TextStyle(color: textColor.withValues(alpha: 0.4))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteEvent(id);
              },
              child: Text(SC.tr('delete'),
                  style: const TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy,
              size: 64, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(SC.tr('noEventsYet'),
              style:
              TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1)),
    );
  }

  String formatDate(String dt) {
    final d = DateTime.parse(dt).toLocal();
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year} • '
        '${d.hour % 12 == 0 ? 12 : d.hour % 12}:'
        '${d.minute.toString().padLeft(2, '0')} '
        '${d.hour >= 12 ? 'PM' : 'AM'}';
  }
}