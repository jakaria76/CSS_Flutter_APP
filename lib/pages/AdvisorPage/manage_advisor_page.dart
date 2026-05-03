import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'advisor_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _opacity = Tween(begin: 1.0, end: 0.35)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class ManageAdvisorPage extends StatefulWidget {
  const ManageAdvisorPage({super.key});
  @override
  State<ManageAdvisorPage> createState() => _ManageAdvisorPageState();
}

class _ManageAdvisorPageState extends State<ManageAdvisorPage>
    with TickerProviderStateMixin {

  final SupabaseClient _supabase = Supabase.instance.client;
  List<Advisor> _advisors = [];
  bool   _isLoading   = true;
  String _searchQuery = '';

  late final AnimationController _listAnim;
  late final AnimationController _fabAnim;

  static const _advisorMemberType = 'advisor';
  static const _generalMemberType = 'general';

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fetchAdvisors();
  }

  @override
  void dispose() {
    _listAnim.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  Future<void> _fetchAdvisors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select(
        'id, full_name, full_name_bn, profile_image_url, '
            'occupation, institution, designation, expertise, advisor_note',
      )
          .eq('member_type', _advisorMemberType)
          .order('full_name', ascending: true);

      final List<Advisor> fetched = [];
      for (var item in response) {
        final id = item['id'];
        if (id == null) continue;
        fetched.add(Advisor(
          id: id.toString(),
          fullName: item['full_name'] as String? ?? 'Unknown',
          fullNameBn: item['full_name_bn'] as String?,
          imagePath: item['profile_image_url'] as String?,
          occupation: item['occupation'] as String?,
          institution: item['institution'] as String?,
          designation: item['designation'] as String?,
          expertise: item['expertise'] as String?,
          note: item['advisor_note'] as String?,
        ));
      }

      if (mounted) {
        setState(() { _advisors = fetched; _isLoading = false; });
        _listAnim.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Error: $e', error: true);
      }
    }
  }

  List<Advisor> get _filtered {
    if (_searchQuery.isEmpty) return _advisors;
    final q = _searchQuery.toLowerCase();
    return _advisors.where((a) =>
    a.fullName.toLowerCase().contains(q) ||
        (a.fullNameBn?.toLowerCase().contains(q) ?? false) ||
        (a.designation?.toLowerCase().contains(q) ?? false) ||
        (a.occupation?.toLowerCase().contains(q) ?? false) ||
        (a.institution?.toLowerCase().contains(q) ?? false)).toList();
  }

  void _snack(String msg, {bool error = false}) =>
      SC.toast(context, msg, error ? SC.red : SC.cyan);

  Future<void> _deleteAdvisor(Advisor advisor) async {
    try {
      await _supabase.from('profiles').update({
        'member_type': _generalMemberType,
        'occupation': null, 'institution': null,
        'designation': null, 'expertise': null, 'advisor_note': null,
      }).eq('id', advisor.id);
      _snack('${advisor.fullName} ${SC.tr('advisorRemovedMsg')}');
      _fetchAdvisors();
    } catch (e) { _snack('Error: $e', error: true); }
  }

  Future<void> _updateAdvisor({
    required String userId,
    required String? occupation,
    required String? institution,
    required String? designation,
    required String? expertise,
    required String? note,
  }) async {
    try {
      await _supabase.from('profiles').update({
        'member_type': _advisorMemberType,
        'occupation': occupation, 'institution': institution,
        'designation': designation, 'expertise': expertise, 'advisor_note': note,
      }).eq('id', userId);
      _snack(SC.tr('infoUpdated'));
      _fetchAdvisors();
    } catch (e) { _snack('Error: $e', error: true); }
  }

  void _showDeleteConfirmation(Advisor advisor) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _DeleteDialog(advisor: advisor, onConfirm: () => _deleteAdvisor(advisor)),
    );
  }

  void _showAdvisorForm({Advisor? advisor}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _AdvisorFormSheet(
        advisor: advisor,
        supabase: _supabase,
        advisorMemberType: _advisorMemberType,
        onSubmit: _updateAdvisor,
        onSnack: _snack,
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
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final surfaceColor= isDark ? const Color(0xFF0F1620) : Colors.white;
    final surface2    = isDark ? const Color(0xFF141C28) : const Color(0xFFEEF2FF);
    final accentAmber = SC.amber;
    final filtered    = _filtered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: SC.currentGradient,
              ),
            ),
            Positioned(
              top: -80, left: -60,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    accentAmber.withValues(alpha: 0.05),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // AppBar
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 185,
                  backgroundColor: bgColor,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.arrow_back_ios_new_rounded, color: subColor, size: 16),
                        const SizedBox(width: 2),
                        Text(SC.tr('goBack'),
                            style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  leadingWidth: 110,
                  actions: [
                    GestureDetector(
                      onTap: _fetchAdvisors,
                      child: Container(
                        width: 36, height: 36,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor, width: 0.5),
                        ),
                        child: Icon(Icons.refresh_rounded, color: accentAmber, size: 17),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: SC.currentGradient,
                        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [
                                _PulseDot(color: accentAmber),
                                const SizedBox(width: 7),
                                Text(SC.tr('adminPanel'),
                                    style: TextStyle(
                                        color: accentAmber.withValues(alpha: 0.75),
                                        fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.2)),
                              ]),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(SC.tr('advisorManagement'),
                                            style: TextStyle(color: textColor, fontSize: 18,
                                                fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                        const SizedBox(height: 2),
                                        Text('Advisor Management',
                                            style: TextStyle(color: subColor, fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentAmber.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: accentAmber.withValues(alpha: 0.2), width: 0.5),
                                    ),
                                    child: Text(SC.tr('advisorManagementEn'),
                                        style: TextStyle(color: accentAmber, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(children: [
                                Container(height: 2, width: 32,
                                    decoration: BoxDecoration(color: accentAmber, borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 6),
                                Container(height: 2, width: 8,
                                    decoration: BoxDecoration(color: accentAmber.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 6),
                                Container(height: 1, width: 3,
                                    decoration: BoxDecoration(color: accentAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Stats + Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        Row(children: [
                          _miniStat(SC.tr('totalAdvisors'), _advisors.length, accentAmber,
                              surfaceColor, borderColor, subColor),
                          const SizedBox(width: 10),
                          _miniStat(SC.tr('institutions'),
                              _advisors.where((a) => a.institution != null && a.institution!.isNotEmpty).length,
                              SC.blue, surfaceColor, borderColor, subColor),
                          const SizedBox(width: 10),
                          _miniStat(SC.tr('results'), filtered.length,
                              SC.cyan, surfaceColor, borderColor, subColor),
                        ]),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 0.5),
                          ),
                          child: Row(children: [
                            const SizedBox(width: 14),
                            Icon(Icons.search_rounded, color: subColor, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _searchQuery = v),
                                style: TextStyle(color: textColor, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: SC.tr('searchAdvisor'),
                                  hintStyle: TextStyle(color: subColor, fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () => setState(() => _searchQuery = ''),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(color: surface2, shape: BoxShape.circle),
                                  child: Icon(Icons.close_rounded, color: subColor, size: 13),
                                ),
                              )
                            else const SizedBox(width: 14),
                          ]),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),

                // List
                if (_isLoading)
                  SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: accentAmber, strokeWidth: 2)),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: borderColor, width: 0.5),
                              ),
                              child: Icon(Icons.people_alt_rounded, size: 32, color: subColor),
                            ),
                            const SizedBox(height: 18),
                            Text(SC.tr('noAdvisors'),
                                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(SC.tr('addAdvisorHint'),
                                style: TextStyle(color: subColor, fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (_, i) => _advisorTile(filtered[i], i,
                            textColor, subColor, borderColor, surfaceColor, surface2, accentAmber),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),

            // FAB
            Positioned(
              bottom: 24, right: 20,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _fabAnim, curve: Curves.easeOutBack),
                child: GestureDetector(
                  onTap: () { HapticFeedback.mediumImpact(); _showAdvisorForm(); },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: accentAmber,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                          color: accentAmber.withValues(alpha: 0.3),
                          blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(SC.tr('addAdvisor'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, int count, Color color,
      Color surfaceColor, Color borderColor, Color subColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(children: [
          Text('$count', style: TextStyle(color: color, fontSize: 20,
              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: subColor, fontSize: 10, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _advisorTile(Advisor advisor, int index,
      Color textColor, Color subColor, Color borderColor,
      Color surfaceColor, Color surface2, Color accentAmber) {
    return AnimatedBuilder(
      animation: _listAnim,
      builder: (_, child) {
        final delay = (index * 0.04).clamp(0.0, 0.5);
        final t = ((_listAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(t);
        return Opacity(opacity: curve,
            child: Transform.translate(offset: Offset(0, 16 * (1 - curve)), child: child));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showAdvisorForm(advisor: advisor),
            borderRadius: BorderRadius.circular(16),
            splashColor: accentAmber.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Stack(children: [
                  Container(
                    width: 52, height: 58,
                    decoration: BoxDecoration(
                      color: surface2,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: accentAmber.withValues(alpha: 0.2), width: 0.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (advisor.imagePath != null && advisor.imagePath!.isNotEmpty)
                        ? Image.network(advisor.imagePath!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _photoPlaceholder(surface2, accentAmber))
                        : _photoPlaceholder(surface2, accentAmber),
                  ),
                  Positioned(
                    top: -3, left: -3,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: accentAmber, shape: BoxShape.circle,
                        border: Border.all(color: surfaceColor, width: 1.5),
                      ),
                      child: Center(child: Text('${index + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900))),
                    ),
                  ),
                ]),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(advisor.fullName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
                      if (advisor.fullNameBn != null && advisor.fullNameBn!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(advisor.fullNameBn!, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: subColor, fontSize: 11)),
                      ],
                      const SizedBox(height: 6),
                      Row(children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentAmber.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: accentAmber.withValues(alpha: 0.2), width: 0.5),
                            ),
                            child: Text(advisor.badgeLabel, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: accentAmber, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        if (advisor.institution != null && advisor.institution!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: surface2,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: borderColor, width: 0.5),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.account_balance_rounded, size: 9, color: subColor),
                                const SizedBox(width: 3),
                                Flexible(child: Text(advisor.institution!, maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: subColor, fontSize: 10, fontWeight: FontWeight.w600))),
                              ]),
                            ),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _tileBtn(Icons.edit_rounded, SC.blue, () => _showAdvisorForm(advisor: advisor)),
                  const SizedBox(width: 6),
                  _tileBtn(Icons.delete_rounded, SC.red, () => _showDeleteConfirmation(advisor)),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder(Color surface2, Color accentAmber) {
    return Container(color: surface2,
        child: Center(child: Icon(Icons.person_rounded, size: 22, color: accentAmber.withValues(alpha: 0.3))));
  }

  Widget _tileBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// DELETE DIALOG
// ════════════════════════════════════════════════════════════════
class _DeleteDialog extends StatelessWidget {
  final Advisor advisor;
  final VoidCallback onConfirm;
  const _DeleteDialog({required this.advisor, required this.onConfirm});

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: SC.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SC.red.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Icon(Icons.delete_rounded, color: SC.red, size: 18),
              ),
              const SizedBox(width: 12),
              Text(SC.tr('removeFromList'),
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 50,
                  decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(8)),
                  clipBehavior: Clip.antiAlias,
                  child: (advisor.imagePath != null && advisor.imagePath!.isNotEmpty)
                      ? Image.network(advisor.imagePath!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 22, color: subColor))
                      : Icon(Icons.person_rounded, size: 22, color: subColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(advisor.fullName,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(advisor.badgeLabel, style: TextStyle(color: SC.amber, fontSize: 12)),
                    if (advisor.institution != null && advisor.institution!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(advisor.institution!, style: TextStyle(color: subColor, fontSize: 11)),
                    ],
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SC.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SC.amber.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: SC.amber.withValues(alpha: 0.7), size: 15),
                const SizedBox(width: 8),
                Expanded(child: Text(SC.tr('memberTypeRevert'),
                    style: TextStyle(color: subColor, fontSize: 12, height: 1.4))),
              ]),
            ),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 0.5),
                    ),
                    child: Center(child: Text(SC.tr('cancel'),
                        style: TextStyle(color: subColor, fontWeight: FontWeight.w700, fontSize: 13))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () { Navigator.pop(context); onConfirm(); },
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: SC.red, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(SC.tr('remove'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FORM BOTTOM SHEET
// ════════════════════════════════════════════════════════════════
class _AdvisorFormSheet extends StatefulWidget {
  final Advisor? advisor;
  final SupabaseClient supabase;
  final String advisorMemberType;
  final void Function({
  required String userId, required String? occupation,
  required String? institution, required String? designation,
  required String? expertise, required String? note,
  }) onSubmit;
  final void Function(String msg, {bool error}) onSnack;

  const _AdvisorFormSheet({
    required this.advisor, required this.supabase,
    required this.advisorMemberType, required this.onSubmit, required this.onSnack,
  });

  @override
  State<_AdvisorFormSheet> createState() => _AdvisorFormSheetState();
}

class _AdvisorFormSheetState extends State<_AdvisorFormSheet> {
  String? _selectedUserId;
  final _occupationCtrl  = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _expertiseCtrl   = TextEditingController();
  final _noteCtrl        = TextEditingController();

  List<Map<String, dynamic>> _availableUsers = [];
  bool _loadingUsers = false;
  bool get _isEditing => widget.advisor != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _occupationCtrl.text  = widget.advisor!.occupation  ?? '';
      _institutionCtrl.text = widget.advisor!.institution ?? '';
      _designationCtrl.text = widget.advisor!.designation ?? '';
      _expertiseCtrl.text   = widget.advisor!.expertise   ?? '';
      _noteCtrl.text        = widget.advisor!.note        ?? '';
    } else { _loadUsers(); }
  }

  @override
  void dispose() {
    _occupationCtrl.dispose(); _institutionCtrl.dispose();
    _designationCtrl.dispose(); _expertiseCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final response = await widget.supabase
          .from('profiles').select('id, full_name')
          .neq('member_type', widget.advisorMemberType);
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
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: SC.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SC.amber.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Icon(_isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
                    color: SC.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_isEditing ? SC.tr('editInfo') : SC.tr('addAdvisor'),
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
                Text(_isEditing ? SC.tr('updateAdvisorDetails') : SC.tr('assignAdvisorRole'),
                    style: TextStyle(color: subColor, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 24),

            if (_isEditing) ...[
              _label(SC.tr('memberName'), subColor),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface2, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 0.5),
                ),
                child: Row(children: [
                  Container(width: 42, height: 46,
                      decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(8)),
                      clipBehavior: Clip.antiAlias,
                      child: (widget.advisor!.imagePath != null && widget.advisor!.imagePath!.isNotEmpty)
                          ? Image.network(widget.advisor!.imagePath!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 20, color: subColor))
                          : Icon(Icons.person_rounded, size: 20, color: subColor)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.advisor!.fullName,
                        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700)),
                    if (widget.advisor!.fullNameBn != null && widget.advisor!.fullNameBn!.isNotEmpty)
                      Text(widget.advisor!.fullNameBn!, style: TextStyle(color: subColor, fontSize: 11)),
                  ])),
                ]),
              ),
            ] else ...[
              _label(SC.tr('selectMember'), subColor),
              const SizedBox(height: 8),
              _loadingUsers
                  ? Center(child: Padding(padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: SC.amber, strokeWidth: 2)))
                  : _styledDropdown<String>(
                value: _selectedUserId,
                hint: SC.tr('chooseMember'),
                textColor: textColor, subColor: subColor,
                surface2: surface2, borderColor: borderColor,
                items: _availableUsers.map((u) => DropdownMenuItem(
                    value: u['id'].toString(),
                    child: Text(u['full_name'], style: TextStyle(color: textColor)))).toList(),
                onChanged: (v) => setState(() => _selectedUserId = v),
              ),
            ],

            const SizedBox(height: 16),
            _label(SC.tr('occupation'), subColor), const SizedBox(height: 8),
            _textField(_occupationCtrl, SC.tr('occupationHint'), textColor, subColor, surface2, borderColor),
            const SizedBox(height: 16),
            _label(SC.tr('institution'), subColor), const SizedBox(height: 8),
            _textField(_institutionCtrl, SC.tr('institutionHint'), textColor, subColor, surface2, borderColor),
            const SizedBox(height: 16),
            _label(SC.tr('designation'), subColor), const SizedBox(height: 8),
            _textField(_designationCtrl, SC.tr('designationHint'), textColor, subColor, surface2, borderColor),
            const SizedBox(height: 16),
            _label(SC.tr('expertiseArea'), subColor), const SizedBox(height: 8),
            _textField(_expertiseCtrl, SC.tr('expertiseHint'), textColor, subColor, surface2, borderColor, maxLines: 2),
            const SizedBox(height: 16),
            _label(SC.tr('noteOptional'), subColor), const SizedBox(height: 8),
            _textField(_noteCtrl, SC.tr('advisorNoteHint'), textColor, subColor, surface2, borderColor, maxLines: 3),
            const SizedBox(height: 28),

            GestureDetector(
              onTap: () {
                if (!_isEditing && _selectedUserId == null) {
                  widget.onSnack(SC.tr('selectMemberFirst'), error: true);
                  return;
                }
                Navigator.pop(context);
                widget.onSubmit(
                  userId: _isEditing ? widget.advisor!.id : _selectedUserId!,
                  occupation: _occupationCtrl.text.trim().isEmpty ? null : _occupationCtrl.text.trim(),
                  institution: _institutionCtrl.text.trim().isEmpty ? null : _institutionCtrl.text.trim(),
                  designation: _designationCtrl.text.trim().isEmpty ? null : _designationCtrl.text.trim(),
                  expertise: _expertiseCtrl.text.trim().isEmpty ? null : _expertiseCtrl.text.trim(),
                  note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                );
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(color: SC.amber, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(_isEditing ? SC.tr('updateInfo') : SC.tr('addToList'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color subColor) => Text(text,
      style: TextStyle(color: subColor, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3));

  Widget _textField(TextEditingController ctrl, String hint,
      Color textColor, Color subColor, Color surface2, Color borderColor, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5)),
      child: TextField(controller: ctrl, maxLines: maxLines,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(hintText: hint,
              hintStyle: TextStyle(color: subColor, fontSize: 13),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12))),
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