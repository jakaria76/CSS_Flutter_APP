import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/committee_member_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class ManageCommitteePage extends StatefulWidget {
  const ManageCommitteePage({super.key});
  @override
  State<ManageCommitteePage> createState() => _ManageCommitteePageState();
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _opacity = Tween(begin: 1.0, end: 0.35).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: Container(width: 6, height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
  );
}

class _ManageCommitteePageState extends State<ManageCommitteePage> with TickerProviderStateMixin {

  final SupabaseClient _supabase = Supabase.instance.client;
  List<CommitteeMember> members = [];
  bool _isLoading = true;
  String _searchQuery = '';

  late final AnimationController _listAnim;
  late final AnimationController _fabAnim;

  static const String _committeeMemberType = 'present_committee';
  static const String _generalMemberType   = 'general';

  final List<String> committeePositions = [
    "সভাপতি","সহ-সভাপতি","সাধারণ সম্পাদক","যুগ্ম-সাধারণ সম্পাদক",
    "সাংগঠনিক সম্পাদক","সহ-সাংগঠনিক সম্পাদক","দপ্তর সম্পাদক",
    "সিনিয়র সহ-দপ্তর সম্পাদক","সহ-দপ্তর সম্পাদক","অর্থ সম্পাদক",
    "সিনিয়র অর্থ সম্পাদক","সহ-অর্থ সম্পাদক","শিক্ষা সম্পাদক",
    "সহ-শিক্ষা সম্পাদক","পরিকল্পনা সম্পাদক","সহ-পরিকল্পনা সম্পাদক",
    "মানব সম্পদ সম্পাদক","সহ-মানব সম্পদ সম্পাদক","পরিবেশ সম্পাদক",
    "সহ-পরিবেশ সম্পাদক","ধর্ম সম্পাদক","সহ-ধর্ম সম্পাদক",
    "প্রচার সম্পাদক","সহ-প্রচার সম্পাদক","ব্র্যান্ড ও গণমাধ্যম সম্পাদক",
    "সিনিয়র ব্র্যান্ড ও গণমাধ্যম সম্পাদক","গ্রাফিক্স ডিজাইনার",
    "সহ-গ্রাফিক্স ডিজাইনার","ক্রিয়া সম্পাদক","সহ-ক্রিয়া সম্পাদক",
    "পাঠাগার সম্পাদক","সহ-পাঠাগার সম্পাদক","সাংস্কৃতিক সম্পাদক",
    "সহ-সাংস্কৃতিক সম্পাদক","বিজ্ঞান ও প্রযুক্তি সম্পাদক",
    "সহ-বিজ্ঞান ও প্রযুক্তি সম্পাদক","সমাজ কল্যাণ সম্পাদক",
    "সহ-সমাজ কল্যাণ সম্পাদক","স্বাস্থ্য সম্পাদক","সহ-স্বাস্থ্য সম্পাদক",
    "নারী সম্পাদক","সহ-নারী সম্পাদক","আন্তর্জাতিক সম্পাদক",
    "সহ-আন্তর্জাতিক সম্পাদক","ছাত্র কল্যাণ সম্পাদক",
    "সহ-ছাত্র কল্যাণ সম্পাদক","সাহিত্য সম্পাদক","সহ-সাহিত্য সম্পাদক",
    "তথ্য ও গবেষণা সম্পাদক","সহ-তথ্য ও গবেষণা সম্পাদক",
    "ত্রাণ ও দুর্যোগ সম্পাদক","সিনিয়র ত্রাণ ও দুর্যোগ সম্পাদক",
    "সহ-ত্রাণ ও দুর্যোগ সম্পাদক","কার্যকরী সদস্য",
  ];

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fabAnim  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fetchCommitteeMembers();
  }

  @override
  void dispose() { _listAnim.dispose(); _fabAnim.dispose(); super.dispose(); }

  Future<void> _fetchCommitteeMembers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, committee_position, profile_image_url')
          .eq('member_type', _committeeMemberType);

      final List<CommitteeMember> fetched = [];
      for (var item in response) {
        final position = item['committee_position'] as String?;
        if (position != null) {
          fetched.add(CommitteeMember(
            id: item['id'].toString(),
            fullName: item['full_name'] as String? ?? 'Unknown',
            position: position,
            imagePath: item['profile_image_url'] as String?,
            category: _getCategoryFromPosition(position),
          ));
        }
      }
      if (mounted) {
        setState(() { members = fetched; _isLoading = false; });
        _listAnim.forward(from: 0);
      }
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); _snack('Error: $e', error: true); }
    }
  }

  String _getCategoryFromPosition(String position) {
    if (position == 'সভাপতি' || position == 'সহ-সভাপতি' || position == 'সাধারণ সম্পাদক') return 'Top';
    if (position.contains('সম্পাদক') || position.contains('সহ-') || position == 'কার্যকরী সদস্য') return 'Executive';
    return 'Members';
  }

  List<CommitteeMember> get _filtered {
    if (_searchQuery.isEmpty) return members;
    final q = _searchQuery.toLowerCase();
    return members.where((m) =>
    m.fullName.toLowerCase().contains(q) || m.position.toLowerCase().contains(q)).toList();
  }

  void _snack(String msg, {bool error = false}) => SC.toast(context, msg, error ? SC.red : SC.cyan);

  Future<void> _deleteMember(CommitteeMember member) async {
    try {
      await _supabase.from('profiles').update({
        'member_type': _generalMemberType, 'committee_position': null,
      }).eq('id', member.id);
      _snack('${member.fullName} ${SC.tr('removedFromCommittee')}');
      _fetchCommitteeMembers();
    } catch (e) { _snack('Error: $e', error: true); }
  }

  Future<void> _updateMember(String userId, String position) async {
    try {
      await _supabase.from('profiles').update({
        'member_type': _committeeMemberType, 'committee_position': position,
      }).eq('id', userId);
      _snack(SC.tr('memberUpdated'));
      _fetchCommitteeMembers();
    } catch (e) { _snack('Error: $e', error: true); }
  }

  void _showDeleteConfirmation(CommitteeMember member) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _DeleteDialog(member: member, onConfirm: () => _deleteMember(member)),
    );
  }

  void _showMemberForm({CommitteeMember? member}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _MemberFormSheet(
        member: member, supabase: _supabase,
        committeePositions: committeePositions,
        committeeMemberType: _committeeMemberType,
        onSubmit: _updateMember, onSnack: _snack,
      ),
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
    final bgColor     = isDark ? SC.bgStart : const Color(0xFFF0F4FF);
    final cardColor   = isDark ? SC.cardBg  : Colors.white;
    final textColor   = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor    = isDark ? const Color(0xFF8899AA) : const Color(0xFF4A5568);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.08);
    final surface2    = isDark ? const Color(0xFF141C28) : const Color(0xFFEEF2FF);
    final filtered    = _filtered;
    final topMembers   = filtered.where((m) => m.category == 'Top').toList();
    final execMembers  = filtered.where((m) => m.category == 'Executive').toList();
    final otherMembers = filtered.where((m) => m.category == 'Members').toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
            Positioned(
              top: -80, right: -60,
              child: Container(width: 260, height: 260,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [SC.cyan.withValues(alpha: 0.05), Colors.transparent]))),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true, expandedHeight: 175,
                  backgroundColor: bgColor, elevation: 0, surfaceTintColor: Colors.transparent,
                  leading: GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      margin: const EdgeInsets.only(left: 12),
                      child: Row(children: [
                        Icon(Icons.arrow_back_ios_new_rounded, color: subColor, size: 16),
                        const SizedBox(width: 2),
                        Text(SC.tr('goBack'), style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                  leadingWidth: 110,
                  actions: [
                    GestureDetector(
                      onTap: _fetchCommitteeMembers,
                      child: Container(
                        width: 36, height: 36, margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor, width: 0.5)),
                        child: Icon(Icons.refresh_rounded, color: SC.cyan, size: 17),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Container(
                      decoration: BoxDecoration(gradient: SC.currentGradient,
                          border: Border(bottom: BorderSide(color: borderColor, width: 0.5))),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [
                                _PulseDot(color: SC.cyan),
                                const SizedBox(width: 7),
                                Text(SC.tr('adminPanel'),
                                    style: TextStyle(color: SC.cyan.withValues(alpha: 0.75),
                                        fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.2)),
                              ]),
                              const SizedBox(height: 10),
                              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(SC.tr('committeeManagement'),
                                      style: TextStyle(color: textColor, fontSize: 20,
                                          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                  const SizedBox(height: 2),
                                  Text('Committee Management', style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w500)),
                                ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: SC.cyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: SC.cyan.withValues(alpha: 0.2), width: 0.5),
                                  ),
                                  child: Text(SC.tr('committeeLabel'),
                                      style: TextStyle(color: SC.cyan, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                Container(height: 2, width: 32, decoration: BoxDecoration(color: SC.cyan, borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 6),
                                Container(height: 2, width: 8, decoration: BoxDecoration(color: SC.cyan.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 6),
                                Container(height: 1, width: 3, decoration: BoxDecoration(color: SC.cyan.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(children: [
                      Row(children: [
                        _miniStat(SC.tr('totalMembers'), members.length, SC.amber, cardColor, borderColor, subColor),
                        const SizedBox(width: 10),
                        _miniStat(SC.tr('leadership'), members.where((m) => m.category == 'Top').length,
                            SC.cyan, cardColor, borderColor, subColor),
                        const SizedBox(width: 10),
                        _miniStat(SC.tr('executive'), members.where((m) => m.category == 'Executive').length,
                            SC.blue, cardColor, borderColor, subColor),
                      ]),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 0.5)),
                        child: Row(children: [
                          const SizedBox(width: 14),
                          Icon(Icons.search_rounded, color: subColor, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                              style: TextStyle(color: textColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: SC.tr('searchMembers'),
                                hintStyle: TextStyle(color: subColor, fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _searchQuery = ''),
                              child: Container(margin: const EdgeInsets.only(right: 10), width: 22, height: 22,
                                  decoration: BoxDecoration(color: surface2, shape: BoxShape.circle),
                                  child: Icon(Icons.close_rounded, color: subColor, size: 13)),
                            )
                          else const SizedBox(width: 14),
                        ]),
                      ),
                      const SizedBox(height: 22),
                    ]),
                  ),
                ),

                if (_isLoading)
                  SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: SC.cyan, strokeWidth: 2)))
                else ...[
                  if (topMembers.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _sectionHeader(SC.tr('leadershipSection'),
                        Icons.stars_rounded, SC.amber, cardColor, borderColor, textColor)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      sliver: SliverList(delegate: SliverChildBuilderDelegate(
                              (_, i) => _memberTile(topMembers[i], i, SC.amber, textColor, subColor, borderColor, cardColor, surface2),
                          childCount: topMembers.length)),
                    ),
                  ],
                  if (execMembers.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _sectionHeader(SC.tr('executiveBoard'),
                        Icons.workspace_premium_rounded, SC.cyan, cardColor, borderColor, textColor)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      sliver: SliverList(delegate: SliverChildBuilderDelegate(
                              (_, i) => _memberTile(execMembers[i], i, SC.cyan, textColor, subColor, borderColor, cardColor, surface2),
                          childCount: execMembers.length)),
                    ),
                  ],
                  if (otherMembers.isNotEmpty) ...[
                    SliverToBoxAdapter(child: _sectionHeader(SC.tr('membersSection'),
                        Icons.people_rounded, SC.green, cardColor, borderColor, textColor)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      sliver: SliverList(delegate: SliverChildBuilderDelegate(
                              (_, i) => _memberTile(otherMembers[i], i, SC.blue, textColor, subColor, borderColor, cardColor, surface2),
                          childCount: otherMembers.length)),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ],
            ),

            Positioned(
              bottom: 24, right: 20,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _fabAnim, curve: Curves.easeOutBack),
                child: GestureDetector(
                  onTap: () { HapticFeedback.mediumImpact(); _showMemberForm(); },
                  child: Container(
                    height: 50, padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: SC.cyan, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: SC.cyan.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(SC.tr('addMember'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, int count, Color color, Color cardColor, Color borderColor, Color subColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.5)),
        child: Column(children: [
          Text('$count', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: subColor, fontSize: 10.5, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color,
      Color cardColor, Color borderColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5),
              border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5)),
          child: Text('${members.where((m) {
            if (title == SC.tr('leadershipSection')) return m.category == 'Top';
            if (title == SC.tr('executiveBoard')) return m.category == 'Executive';
            return m.category == 'Members';
          }).length}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _memberTile(CommitteeMember member, int index, Color accent,
      Color textColor, Color subColor, Color borderColor, Color cardColor, Color surface2) {
    return AnimatedBuilder(
      animation: _listAnim,
      builder: (_, child) {
        final delay = (index * 0.04).clamp(0.0, 0.5);
        final t = ((_listAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(t);
        return Opacity(opacity: curve, child: Transform.translate(offset: Offset(0, 16 * (1 - curve)), child: child));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 0.5)),
        child: Material(
          color: Colors.transparent, borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _showMemberForm(member: member),
            borderRadius: BorderRadius.circular(14),
            splashColor: accent.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 50, height: 56,
                  decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.2), width: 0.5)),
                  clipBehavior: Clip.antiAlias,
                  child: member.imagePath != null && member.imagePath!.isNotEmpty
                      ? Image.network(member.imagePath!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 24, color: accent.withValues(alpha: 0.3)))
                      : Icon(Icons.person_rounded, size: 24, color: accent.withValues(alpha: 0.3)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(member.fullName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: accent.withValues(alpha: 0.2), width: 0.5)),
                    child: Text(member.position, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ])),
                const SizedBox(width: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _tileBtn(Icons.edit_rounded, SC.blue, () => _showMemberForm(member: member)),
                  const SizedBox(width: 6),
                  _tileBtn(Icons.delete_rounded, SC.red, () => _showDeleteConfirmation(member)),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tileBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  final CommitteeMember member;
  final VoidCallback onConfirm;
  const _DeleteDialog({required this.member, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final isDark      = SC.isDark;
    final surfaceColor= isDark ? const Color(0xFF0F1620) : Colors.white;
    final surface2    = isDark ? const Color(0xFF141C28) : const Color(0xFFEEF2FF);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.08);
    final textColor   = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor    = isDark ? const Color(0xFF8899AA) : const Color(0xFF4A5568);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38,
                decoration: BoxDecoration(color: SC.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SC.red.withValues(alpha: 0.25), width: 0.5)),
                child: Icon(Icons.delete_rounded, color: SC.red, size: 18)),
            const SizedBox(width: 12),
            Text(SC.tr('deleteMember'), style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 0.5)),
            child: Row(children: [
              Container(width: 44, height: 50,
                  decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(8)),
                  clipBehavior: Clip.antiAlias,
                  child: member.imagePath != null
                      ? Image.network(member.imagePath!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 22, color: subColor))
                      : Icon(Icons.person_rounded, size: 22, color: subColor)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(member.fullName, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(member.position, style: TextStyle(color: SC.cyan, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: SC.amber.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SC.amber.withValues(alpha: 0.2), width: 0.5)),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: SC.amber.withValues(alpha: 0.7), size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(SC.tr('memberTypeRevert'), style: TextStyle(color: subColor, fontSize: 12, height: 1.4))),
            ]),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(height: 42,
                  decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 0.5)),
                  child: Center(child: Text(SC.tr('cancel'), style: TextStyle(color: subColor, fontWeight: FontWeight.w700, fontSize: 13)))),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () { Navigator.pop(context); onConfirm(); },
              child: Container(height: 42, decoration: BoxDecoration(color: SC.red, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(SC.tr('remove'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)))),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _MemberFormSheet extends StatefulWidget {
  final CommitteeMember? member;
  final SupabaseClient supabase;
  final List<String> committeePositions;
  final String committeeMemberType;
  final void Function(String userId, String position) onSubmit;
  final void Function(String msg, {bool error}) onSnack;

  const _MemberFormSheet({
    required this.member, required this.supabase,
    required this.committeePositions, required this.committeeMemberType,
    required this.onSubmit, required this.onSnack,
  });

  @override
  State<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<_MemberFormSheet> {
  String? _selectedUserId;
  String? _selectedPosition;
  List<Map<String, dynamic>> _availableUsers = [];
  bool _loadingUsers = false;
  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedPosition = widget.member!.position;
      if (_selectedPosition != null && !widget.committeePositions.contains(_selectedPosition)) {
        _selectedPosition = null;
      }
    } else { _loadUsers(); }
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final response = await widget.supabase.from('profiles').select('id, full_name')
          .neq('member_type', widget.committeeMemberType);
      setState(() { _availableUsers = List<Map<String, dynamic>>.from(response); _loadingUsers = false; });
    } catch (_) { setState(() => _loadingUsers = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = SC.isDark;
    final surfaceColor= isDark ? const Color(0xFF0F1620) : Colors.white;
    final surface2    = isDark ? const Color(0xFF141C28) : const Color(0xFFEEF2FF);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.08);
    final textColor   = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor    = isDark ? const Color(0xFF8899AA) : const Color(0xFF4A5568);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12, left: 20, right: 20,
      ),
      decoration: BoxDecoration(color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: SC.cyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SC.cyan.withValues(alpha: 0.25), width: 0.5)),
              child: Icon(_isEditing ? Icons.edit_rounded : Icons.person_add_rounded, color: SC.cyan, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_isEditing ? SC.tr('editPosition') : SC.tr('addMemberSheet'),
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
              Text(_isEditing ? SC.tr('updateMemberDetails') : SC.tr('selectMemberAndPosition'),
                  style: TextStyle(color: subColor, fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 24),

          if (_isEditing) ...[
            Text(SC.tr('memberName'), style: TextStyle(color: subColor, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 0.5)),
              child: Row(children: [
                Container(width: 42, height: 46,
                    decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(8)),
                    clipBehavior: Clip.antiAlias,
                    child: widget.member!.imagePath != null
                        ? Image.network(widget.member!.imagePath!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 20, color: subColor))
                        : Icon(Icons.person_rounded, size: 20, color: subColor)),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.member!.fullName,
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700))),
              ]),
            ),
          ] else ...[
            Text(SC.tr('selectMember'), style: TextStyle(color: subColor, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            const SizedBox(height: 8),
            _loadingUsers
                ? Center(child: Padding(padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(color: SC.cyan, strokeWidth: 2)))
                : _styledDropdown<String>(
              value: _selectedUserId, hint: SC.tr('chooseMember'),
              textColor: textColor, subColor: subColor, surface2: surface2, borderColor: borderColor,
              items: _availableUsers.map((u) => DropdownMenuItem(value: u['id'].toString(),
                  child: Text(u['full_name'], style: TextStyle(color: textColor)))).toList(),
              onChanged: (v) => setState(() => _selectedUserId = v),
            ),
          ],

          const SizedBox(height: 18),
          Text(SC.tr('selectPosition'), style: TextStyle(color: subColor, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          _styledDropdown<String>(
            value: _selectedPosition, hint: SC.tr('choosePosition'),
            textColor: textColor, subColor: subColor, surface2: surface2, borderColor: borderColor,
            items: widget.committeePositions.map((p) => DropdownMenuItem(value: p,
                child: Text(p, style: TextStyle(color: textColor)))).toList(),
            onChanged: (v) => setState(() => _selectedPosition = v),
          ),
          const SizedBox(height: 28),

          GestureDetector(
            onTap: () {
              if (_selectedPosition == null) { widget.onSnack(SC.tr('selectPositionFirst'), error: true); return; }
              if (!_isEditing && _selectedUserId == null) { widget.onSnack(SC.tr('selectMemberFirst'), error: true); return; }
              Navigator.pop(context);
              widget.onSubmit(_isEditing ? widget.member!.id : _selectedUserId!, _selectedPosition!);
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(color: SC.cyan, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(_isEditing ? SC.tr('updatePosition') : SC.tr('addToCommittee'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _styledDropdown<T>({
    required T? value, required String hint,
    required Color textColor, required Color subColor,
    required Color surface2, required Color borderColor,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true, dropdownColor: surface2,
          value: value, hint: Text(hint, style: TextStyle(color: subColor, fontSize: 14)),
          items: items, onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: subColor, size: 20),
          style: TextStyle(color: textColor, fontSize: 14),
        ),
      ),
    );
  }
}