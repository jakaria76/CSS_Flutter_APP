import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'package:css/pages/SettingsPage/settings_constants.dart';

class ManageAboutPage extends StatefulWidget {
  const ManageAboutPage({super.key});

  @override
  State<ManageAboutPage> createState() => _ManageAboutPageState();
}

class _ManageAboutPageState extends State<ManageAboutPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  bool loading        = false;
  bool initialLoading = true;

  int?   overviewId;
  String orgDescription = '';
  int    foundedYear    = 2022;
  String focusAreas     = '';

  int?   contactId;
  String contactEmail    = '';
  String contactPhone    = '';
  String contactAddress  = '';
  String contactFacebook = '';
  String contactWebsite  = '';

  List<Map<String, dynamic>> missions   = [];
  List<Map<String, dynamic>> activities = [];
  List<Map<String, dynamic>> story      = [];

  // ── Light mode colors ────────────────────────────────────────────────────
  static const _lightBg   = Color(0xFFF0F4FF);
  static const _lightCard = Colors.white;
  static const _lightText = Color(0xFF1A2332);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => initialLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        _supabase.from('about_overview').select().maybeSingle(),
        _supabase.from('about_contact').select().maybeSingle(),
        _supabase.from('about_mission_points').select().order('order_index'),
        _supabase.from('about_activities').select().order('order_index'),
        _supabase.from('about_story').select().order('event_date'),
      ]);
      if (!mounted) return;
      setState(() {
        final ov = results[0] as Map<String, dynamic>?;
        if (ov != null) {
          overviewId     = ov['id'] as int?;
          orgDescription = (ov['description'] as String?) ?? '';
          foundedYear    = (ov['founded_year'] as int?) ?? 2022;
          focusAreas     = (ov['focus'] as String?) ?? '';
        }
        final ct = results[1] as Map<String, dynamic>?;
        if (ct != null) {
          contactId       = ct['id'] as int?;
          contactEmail    = (ct['email']    as String?) ?? '';
          contactPhone    = (ct['phone']    as String?) ?? '';
          contactAddress  = (ct['address']  as String?) ?? '';
          contactFacebook = (ct['facebook'] as String?) ?? '';
          contactWebsite  = (ct['website']  as String?) ?? '';
        }
        missions   = List<Map<String, dynamic>>.from(results[2] as List);
        activities = List<Map<String, dynamic>>.from(results[3] as List);
        story      = List<Map<String, dynamic>>.from(results[4] as List);
        initialLoading = false;
      });
    } catch (e) {
      _msg('${SC.tr('manageLoadFailed')}$e');
      if (mounted) setState(() => initialLoading = false);
    }
  }

  Future<void> _saveOverview() async {
    setState(() => loading = true);
    try {
      final data = {
        'description':  orgDescription,
        'founded_year': foundedYear,
        'focus':        focusAreas,
      };
      if (overviewId != null) {
        await _supabase.from('about_overview').update(data).eq('id', overviewId!);
      } else {
        await _supabase.from('about_overview').insert(data);
      }
      _msg(SC.tr('manageOverviewSaved'), ok: true);
      _loadData();
    } catch (e) {
      _msg('${SC.tr('manageError')}$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveContact() async {
    setState(() => loading = true);
    try {
      final data = {
        'email':    contactEmail,
        'phone':    contactPhone,
        'address':  contactAddress,
        'facebook': contactFacebook,
        'website':  contactWebsite,
      };
      if (contactId != null) {
        await _supabase.from('about_contact').update(data).eq('id', contactId!);
      } else {
        await _supabase.from('about_contact').insert(data);
      }
      _msg(SC.tr('manageContactSaved'), ok: true);
      _loadData();
    } catch (e) {
      _msg('${SC.tr('manageError')}$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteStaticItem(String table, int id) async {
    setState(() => loading = true);
    try {
      await _supabase.from(table).delete().eq('id', id);
      await _loadData();
      _msg(SC.tr('manageDeleted'), ok: true);
    } catch (e) {
      _msg('${SC.tr('manageFailed')}$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════
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
    final textColor   = isDark ? Colors.white : _lightText;
    final bgColor     = isDark ? SC.bgStart   : _lightBg;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(isDark, textColor),
        body: Container(
          height: double.infinity,
          width:  double.infinity,
          decoration: BoxDecoration(gradient: SC.currentGradient),
          child: Stack(children: [
            Positioned(
              top: -50, left: -50,
              child: _blurOrb(200,
                  SC.cyan.withValues(alpha: isDark ? 0.10 : 0.06)),
            ),
            Positioned(
              bottom: 100, right: -30,
              child: _blurOrb(150,
                  SC.purple.withValues(alpha: isDark ? 0.05 : 0.03)),
            ),
            SafeArea(
              child: initialLoading
                  ? _buildLoader(isDark)
                  : Column(children: [
                _buildTabBar(isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(isDark),
                      _buildMissionTab(isDark),
                      _buildActivitiesTab(isDark),
                      _buildStoryTab(isDark),
                      _buildContactTab(isDark),
                    ],
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) => AppBar(
    elevation: 0,
    backgroundColor: Colors.transparent,
    leading: IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.arrow_back_ios_new,
            color: textColor, size: 18),
      ),
      onPressed: () => Navigator.pop(context),
    ),
    title: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: SC.cyan.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: SC.cyan.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 10, spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.admin_panel_settings,
            color: SC.cyan, size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(SC.tr('manageAbout'),
            style: TextStyle(
              color: textColor, fontSize: 18, fontWeight: FontWeight.bold,
            )),
        Text(SC.tr('manageAboutSubtitle'),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 11, fontWeight: FontWeight.w400,
            )),
      ]),
    ]),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: loading
              ? SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: SC.cyan),
          )
              : Icon(Icons.refresh_rounded, color: SC.cyan),
          onPressed: loading ? null : _loadData,
        ),
      ),
    ],
  );

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark) {
    final barBg     = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);
    final barBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final unselectedColor = isDark
        ? Colors.white.withValues(alpha: 0.54)
        : _lightText.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: barBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: SC.cyan,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: SC.cyan.withValues(alpha: 0.4),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor:           isDark ? const Color(0xFF0F2027) : Colors.white,
        unselectedLabelColor: unselectedColor,
        labelStyle:           const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: [
          Tab(icon: const Icon(Icons.info_outline,         size: 18),
              text: SC.tr('manageAboutOverview')),
          Tab(icon: const Icon(Icons.flag_outlined,         size: 18),
              text: SC.tr('manageAboutMission')),
          Tab(icon: const Icon(Icons.event_note_outlined,   size: 18),
              text: SC.tr('manageAboutActivities')),
          Tab(icon: const Icon(Icons.timeline_outlined,     size: 18),
              text: SC.tr('manageAboutStory')),
          Tab(icon: const Icon(Icons.contact_mail_outlined, size: 18),
              text: SC.tr('manageAboutContact')),
        ],
      ),
    );
  }

  // ── Overview Tab ──────────────────────────────────────────────────────────
  Widget _buildOverviewTab(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: _card(
      isDark: isDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(SC.tr('manageOrgOverview'),
            Icons.business_outlined, isDark),
        const SizedBox(height: 20),
        _tf(
          label: SC.tr('manageDescription'),
          init: orgDescription, maxLines: 5,
          hint: SC.tr('manageDescHint'),
          icon: Icons.description_outlined,
          isDark: isDark,
          onChanged: (v) => orgDescription = v,
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _tf(
            label: SC.tr('manageFoundedYear'),
            init: foundedYear.toString(),
            keyboardType: TextInputType.number,
            icon: Icons.calendar_today_outlined,
            isDark: isDark,
            onChanged: (v) => foundedYear = int.tryParse(v) ?? foundedYear,
          )),
          const SizedBox(width: 16),
          Expanded(child: _tf(
            label: SC.tr('managePrimaryFocus'),
            init: focusAreas,
            hint: SC.tr('manageFocusHint'),
            icon: Icons.star_border,
            isDark: isDark,
            onChanged: (v) => focusAreas = v,
          )),
        ]),
        const SizedBox(height: 32),
        _saveBtn(_saveOverview, SC.tr('manageSaveOverview'), isDark),
      ]),
    ),
  );

  // ── Mission Tab ───────────────────────────────────────────────────────────
  Widget _buildMissionTab(bool isDark) => _listTab(
    items: missions,
    title: SC.tr('manageMissionPoints'),
    table: 'about_mission_points',
    icon: Icons.flag_outlined,
    textKey: 'text',
    isDark: isDark,
    onAdd: (v) async {
      await _supabase.from('about_mission_points')
          .insert({'text': v, 'order_index': missions.length});
      _loadData();
    },
  );

  // ── Activities Tab ────────────────────────────────────────────────────────
  Widget _buildActivitiesTab(bool isDark) => _listTab(
    items: activities,
    title: SC.tr('manageAboutActivities'),
    table: 'about_activities',
    icon: Icons.event_note_outlined,
    textKey: 'title',
    isDark: isDark,
    onAdd: (v) async {
      await _supabase.from('about_activities')
          .insert({'title': v, 'icon': 'bolt', 'order_index': activities.length});
      _loadData();
    },
  );

  // ── Story Tab ─────────────────────────────────────────────────────────────
  Widget _buildStoryTab(bool isDark) {
    final cardBg     = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.9);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);
    final textColor  = isDark ? Colors.white : _lightText;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _fab(
        onPressed: _addStoryDialog,
        icon: Icons.add_rounded,
        label: SC.tr('manageAddEvent'),
        isDark: isDark,
      ),
      body: story.isEmpty
          ? _empty(SC.tr('manageNoStory'), SC.tr('manageAddMilestone'),
          Icons.timeline_outlined, isDark)
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: story.length,
        itemBuilder: (_, i) {
          final e    = story[i];
          final date = DateTime.tryParse((e['event_date'] as String?) ?? '');
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SC.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.event, color: SC.cyan, size: 20),
                  ),
                  title: Text(
                    (e['description'] as String?) ?? '',
                    style: TextStyle(
                      color: textColor, fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: date != null
                      ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: SC.cyan),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMM yyyy').format(date),
                        style: TextStyle(
                            color: SC.cyan, fontSize: 12),
                      ),
                    ]),
                  )
                      : null,
                  trailing: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 18),
                    ),
                    onPressed: () => _showDeleteDialog(
                            () => _deleteStaticItem(
                            'about_story', e['id'] as int)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Contact Tab ───────────────────────────────────────────────────────────
  Widget _buildContactTab(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      _card(
        isDark: isDark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader(SC.tr('manageContactInfo'),
              Icons.contacts_outlined, isDark),
          const SizedBox(height: 20),
          _tf(
            label: SC.tr('manageEmailAddr'), init: contactEmail,
            hint: SC.tr('manageEmailHint'), icon: Icons.email_outlined,
            isDark: isDark, onChanged: (v) => contactEmail = v,
          ),
          const SizedBox(height: 16),
          _tf(
            label: SC.tr('managePhone'), init: contactPhone,
            hint: SC.tr('managePhoneHint'), icon: Icons.phone_outlined,
            isDark: isDark, onChanged: (v) => contactPhone = v,
          ),
          const SizedBox(height: 16),
          _tf(
            label: SC.tr('manageAddress'), init: contactAddress,
            maxLines: 2, hint: SC.tr('manageAddressHint'),
            icon: Icons.location_on_outlined,
            isDark: isDark, onChanged: (v) => contactAddress = v,
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _card(
        isDark: isDark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader(SC.tr('manageSocialWeb'), Icons.link, isDark),
          const SizedBox(height: 20),
          _tf(
            label: SC.tr('manageFacebook'), init: contactFacebook,
            hint: SC.tr('manageFacebookHint'), icon: Icons.facebook,
            isDark: isDark, onChanged: (v) => contactFacebook = v,
          ),
          const SizedBox(height: 16),
          _tf(
            label: SC.tr('manageWebsite'), init: contactWebsite,
            hint: SC.tr('manageWebsiteHint'), icon: Icons.language,
            isDark: isDark, onChanged: (v) => contactWebsite = v,
          ),
          const SizedBox(height: 32),
          _saveBtn(_saveContact, SC.tr('manageSaveContact'), isDark),
        ]),
      ),
    ]),
  );

  // ════════════════════════════════════════════════════════════
  // DIALOGS
  // ════════════════════════════════════════════════════════════
  void _addStoryDialog() {
    final descC = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final isDark = SC.isDark;
          return Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: SC.cyan.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(children: [
                        Icon(Icons.event_note, color: SC.cyan, size: 24),
                        const SizedBox(width: 12),
                        Text(SC.tr('manageNewStoryEvent'),
                            style: TextStyle(
                              color: isDark ? Colors.white : _lightText,
                              fontSize: 18, fontWeight: FontWeight.bold,
                            )),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setD(() => selectedDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.08)),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_month, color: SC.cyan),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: TextStyle(
                                  color: isDark ? Colors.white : _lightText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _dlgField(descC, SC.tr('manageEventDesc'),
                            Icons.description_outlined, maxLines: 4,
                            isDark: isDark),
                      ]),
                    ),
                    _dialogFooter(
                      isDark: isDark,
                      onCancel: () => Navigator.pop(ctx),
                      onConfirm: () {
                        if (descC.text.isEmpty) return;
                        _supabase.from('about_story').insert({
                          'event_date':  DateFormat('yyyy-MM-dd').format(selectedDate),
                          'description': descC.text,
                          'order_index': story.length,
                        }).then((_) => _loadData());
                        Navigator.pop(ctx);
                      },
                      confirmLabel: SC.tr('manageAddEvent'),
                      confirmColor: SC.cyan,
                      confirmTextColor: isDark
                          ? const Color(0xFF0F2027)
                          : Colors.white,
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = SC.isDark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Colors.redAccent, size: 40),
                      ),
                      const SizedBox(height: 20),
                      Text(SC.tr('manageDeleteConfirm'),
                          style: TextStyle(
                            color: isDark ? Colors.white : _lightText,
                            fontSize: 20, fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      Text(SC.tr('manageDeleteWarning'),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.54)
                                : _lightText.withValues(alpha: 0.5),
                            fontSize: 14,
                          )),
                    ]),
                  ),
                  _dialogFooter(
                    isDark: isDark,
                    onCancel: () => Navigator.pop(ctx),
                    onConfirm: () { onDelete(); Navigator.pop(ctx); },
                    confirmLabel: SC.tr('manageDelete'),
                    confirmColor: Colors.redAccent,
                    confirmTextColor: Colors.white,
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInputDialog(
      String title,
      TextEditingController c,
      Future<void> Function(String) onSave) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = SC.isDark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: SC.cyan.withValues(alpha: 0.2),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.add_circle_outline, color: SC.cyan, size: 24),
                      const SizedBox(width: 12),
                      Text(title,
                          style: TextStyle(
                            color: isDark ? Colors.white : _lightText,
                            fontSize: 18, fontWeight: FontWeight.bold,
                          )),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: c,
                        autofocus: true,
                        maxLines: 3,
                        style: TextStyle(
                            color: isDark ? Colors.white : _lightText,
                            fontSize: 14),
                        decoration: InputDecoration(
                          hintText: SC.tr('manageEnterText'),
                          hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : _lightText.withValues(alpha: 0.35)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                  _dialogFooter(
                    isDark: isDark,
                    onCancel: () => Navigator.pop(ctx),
                    onConfirm: () {
                      if (c.text.isNotEmpty) {
                        onSave(c.text);
                        Navigator.pop(ctx);
                      }
                    },
                    confirmLabel: SC.tr('manageSave'),
                    confirmColor: SC.cyan,
                    confirmTextColor: isDark
                        ? const Color(0xFF0F2027)
                        : Colors.white,
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Dialog Footer (shared) ────────────────────────────────────────────────
  Widget _dialogFooter({
    required bool isDark,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required String confirmLabel,
    required Color confirmColor,
    required Color confirmTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(children: [
        Expanded(
          child: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.12)),
              ),
            ),
            child: Text(SC.tr('manageCancel'),
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : _lightText.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                )),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmLabel,
                style: TextStyle(
                    color: confirmTextColor, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ════════════════════════════════════════════════════════════
  Widget _listTab({
    required List<Map<String, dynamic>> items,
    required String title,
    required String table,
    required IconData icon,
    required String textKey,
    required bool isDark,
    required Future<void> Function(String) onAdd,
  }) {
    final cardBg     = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.9);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);
    final textColor  = isDark ? Colors.white : _lightText;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _fab(
        onPressed: () {
          final c = TextEditingController();
          _showInputDialog('${SC.tr('manageAdd')} $title', c, onAdd);
        },
        icon: Icons.add_rounded,
        label: SC.tr('manageAdd'),
        isDark: isDark,
      ),
      body: items.isEmpty
          ? _empty(SC.tr('manageNoItems'), SC.tr('manageAddFirst'),
          icon, isDark)
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final text = (items[i][textKey] as String?) ?? '';
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SC.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: SC.cyan, size: 18),
                  ),
                  title: Text(text,
                      style: TextStyle(
                        color: textColor, fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )),
                  trailing: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 18),
                    ),
                    onPressed: () => _showDeleteDialog(
                            () => _deleteStaticItem(table, items[i]['id'] as int)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _card({required bool isDark, required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 20, offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );

  Widget _sectionHeader(String title, IconData icon, bool isDark) =>
      Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SC.cyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: SC.cyan, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: TextStyle(
              color: isDark ? Colors.white : _lightText,
              fontWeight: FontWeight.bold, fontSize: 18,
            )),
      ]);

  Widget _tf({
    String? label,
    String? init,
    Function(String)? onChanged,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    IconData? icon,
    required bool isDark,
  }) {
    final textColor   = isDark ? Colors.white : _lightText;
    final hintColor   = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : _lightText.withValues(alpha: 0.35);
    final fieldBg     = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.08);
    final labelColor  = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : _lightText.withValues(alpha: 0.45);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null) ...[
        Text(label,
            style: TextStyle(
              color: labelColor, fontSize: 10,
              fontWeight: FontWeight.bold, letterSpacing: 1,
            )),
        const SizedBox(height: 8),
      ],
      Container(
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: TextFormField(
          initialValue: init,
          onChanged: onChanged,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: hintColor),
            prefixIcon: icon != null
                ? Icon(icon,
                color: SC.cyan.withValues(alpha: 0.7), size: 20)
                : null,
            contentPadding: const EdgeInsets.all(16),
            border: InputBorder.none,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: SC.cyan, width: 1.2),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _dlgField(TextEditingController c, String hint, IconData icon,
      {int maxLines = 1, required bool isDark}) {
    final textColor = isDark ? Colors.white : _lightText;
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : _lightText.withValues(alpha: 0.35);
    final bg = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(icon,
                color: SC.cyan.withValues(alpha: 0.7), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  Widget _saveBtn(VoidCallback onTap, String label, bool isDark) =>
      SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: SC.cyan,
            foregroundColor: isDark ? const Color(0xFF0F2027) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            shadowColor: SC.cyan.withValues(alpha: 0.3),
          ),
          child: loading
              ? SizedBox(
            height: 25, width: 25,
            child: CircularProgressIndicator(
                strokeWidth: 3,
                color: isDark ? const Color(0xFF0F2027) : Colors.white),
          )
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.save_outlined, size: 20),
            const SizedBox(width: 10),
            Text(label.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14, letterSpacing: 1,
                )),
          ]),
        ),
      );

  Widget _fab({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isDark,
  }) =>
      FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: SC.cyan,
        elevation: 10,
        icon: Icon(icon,
            color: isDark ? const Color(0xFF0F2027) : Colors.white),
        label: Text(label,
            style: TextStyle(
              color: isDark ? const Color(0xFF0F2027) : Colors.white,
              fontWeight: FontWeight.w900, fontSize: 14,
            )),
      );

  Widget _empty(String title, String subtitle, IconData icon, bool isDark) =>
      Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: SC.cyan.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: SC.cyan),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: TextStyle(
                color: isDark ? Colors.white : _lightText,
                fontSize: 20, fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.54)
                    : _lightText.withValues(alpha: 0.5),
                fontSize: 14,
              )),
        ]),
      );

  Widget _blurOrb(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
      ],
    ),
  );

  Widget _buildLoader(bool isDark) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SC.cyan.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SC.cyan.withValues(alpha: 0.3),
              blurRadius: 20, spreadRadius: 5,
            ),
          ],
        ),
        child: CircularProgressIndicator(color: SC.cyan, strokeWidth: 3),
      ),
      const SizedBox(height: 24),
      Text(SC.tr('manageLoadingDash'),
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : _lightText.withValues(alpha: 0.6),
            fontSize: 16, fontWeight: FontWeight.w600,
          )),
    ]),
  );

  void _msg(String msg, {bool ok = false}) {
    if (!mounted) return;
    SC.toast(context, msg, ok ? SC.green : SC.red);
  }
}