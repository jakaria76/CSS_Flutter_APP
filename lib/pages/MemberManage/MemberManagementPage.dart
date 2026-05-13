import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/services/cloudinary_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class MemberItem {
  final String id;
  String name;
  String email;
  final String avatarUrl;
  String committeePosition;
  String memberType;
  String accountStatus;
  String role;

  MemberItem({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.committeePosition,
    required this.memberType,
    required this.accountStatus,
    required this.role,
  });

  bool get isBlocked => accountStatus == 'blocked';

  String get displayPosition {
    if (committeePosition.isNotEmpty) return committeePosition;
    return memberType.isNotEmpty ? memberType : 'Member';
  }

  factory MemberItem.fromMap(Map<String, dynamic> m) => MemberItem(
    id: m['id']?.toString() ?? '',
    name: m['full_name']?.toString() ?? m['name']?.toString() ?? 'Unknown',
    email: m['email']?.toString() ?? '',
    avatarUrl:
    m['avatar_url']?.toString() ?? m['profile_image_url']?.toString() ?? '',
    committeePosition: m['committee_position']?.toString() ?? '',
    memberType: m['member_type']?.toString() ?? 'member',
    accountStatus: m['account_status']?.toString() ?? 'active',
    role: m['role']?.toString() ?? 'member',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class MemberManagementPage extends StatefulWidget {
  const MemberManagementPage({super.key});

  @override
  State<MemberManagementPage> createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _cyan    = Color(0xFF00E5FF);
  static const _blue    = Color(0xFF4A90E2);
  static const _red     = Color(0xFFEF5350);
  static const _orange  = Color(0xFFFF8A65);
  static const _green   = Color(0xFF4CAF50);
  static const _amber   = Color(0xFFFFB300);
  static const _purple  = Color(0xFF9C27B0);
  static const _teal    = Color(0xFF26A69A);
  static const _bgStart = Color(0xFF060E17);
  static const _cardBg  = Color(0xFF0F1E2E);

  // ── State ──────────────────────────────────────────────────────────────────
  List<MemberItem> _all   = [];
  List<MemberItem> _shown = [];
  bool   _loading = true;
  String _search  = '';
  String _filter  = 'All';

  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  final _searchCtrl = TextEditingController();

  // ── Committee positions ────────────────────────────────────────────────────
  static const _committeePositions = [
    "সভাপতি", "সহ-সভাপতি", "সাধারণ সম্পাদক", "যুগ্ম-সাধারণ সম্পাদক",
    "সাংগঠনিক সম্পাদক", "সহ-সাংগঠনিক সম্পাদক", "দপ্তর সম্পাদক",
    "সিনিয়র সহ-দপ্তর সম্পাদক", "সহ-দপ্তর সম্পাদক", "অর্থ সম্পাদক",
    "সিনিয়র অর্থ সম্পাদক", "সহ-অর্থ সম্পাদক", "শিক্ষা সম্পাদক",
    "সহ-শিক্ষা সম্পাদক", "পরিকল্পনা সম্পাদক", "সহ-পরিকল্পনা সম্পাদক",
    "মানব সম্পদ সম্পাদক", "সহ-মানব সম্পদ সম্পাদক", "পরিবেশ সম্পাদক",
    "সহ-পরিবেশ সম্পাদক", "ধর্ম সম্পাদক", "সহ-ধর্ম সম্পাদক",
    "প্রচার সম্পাদক", "সহ-প্রচার সম্পাদক", "ব্র্যান্ড ও গণমাধ্যম সম্পাদক",
    "সিনিয়র ব্র্যান্ড ও গণমাধ্যম সম্পাদক", "গ্রাফিক্স ডিজাইনার",
    "সহ-গ্রাফিক্স ডিজাইনার", "ক্রিয়া সম্পাদক", "সহ-ক্রিয়া সম্পাদক",
    "পাঠাগার সম্পাদক", "সহ-পাঠাগার সম্পাদক", "সাংস্কৃতিক সম্পাদক",
    "সহ-সাংস্কৃতিক সম্পাদক", "বিজ্ঞান ও প্রযুক্তি সম্পাদক",
    "সহ-বিজ্ঞান ও প্রযুক্তি সম্পাদক", "সমাজ কল্যাণ সম্পাদক",
    "সহ-সমাজ কল্যাণ সম্পাদক", "স্বাস্থ্য সম্পাদক", "সহ-স্বাস্থ্য সম্পাদক",
    "নারী সম্পাদক", "সহ-নারী সম্পাদক", "আন্তর্জাতিক সম্পাদক",
    "সহ-আন্তর্জাতিক সম্পাদক", "ছাত্র কল্যাণ সম্পাদক",
    "সহ-ছাত্র কল্যাণ সম্পাদক", "সাহিত্য সম্পাদক", "সহ-সাহিত্য সম্পাদক",
    "তথ্য ও গবেষণা সম্পাদক", "সহ-তথ্য ও গবেষণা সম্পাদক",
    "ত্রাণ ও দুর্যোগ সম্পাদক", "সিনিয়র ত্রাণ ও দুর্যোগ সম্পাদক",
    "সহ-ত্রাণ ও দুর্যোগ সম্পাদক", "কার্যকরী সদস্য",
  ];

  // ── Member types — Postgres enum এর সাথে exact match ──────────────────────
  static const _memberTypes = [
    'present_committee',
    'previous_committee',
    'advisor',
  ];

  static String _memberTypeLabel(String t) {
    switch (t) {
      case 'present_committee':  return 'Present Committee';
      case 'previous_committee': return 'Previous Committee';
      case 'advisor':            return 'Advisor';
      default: return t.replaceAll('_', ' ').toUpperCase();
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700), value: 0)
      ..forward();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _fetchMembers();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data fetch ─────────────────────────────────────────────────────────────

  Future<void> _fetchMembers() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase
          .from('profiles')
          .select(
        'id, full_name, name, email, avatar_url, profile_image_url, '
            'committee_position, member_type, account_status, role',
      )
          .order('full_name');

      final list = (res as List)
          .map((m) => MemberItem.fromMap(m as Map<String, dynamic>))
          .toList();

      setState(() {
        _all = list;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _toast('Failed to load members: $e', _red);
    }
  }

  void _applyFilter() {
    List<MemberItem> base = List.from(_all);
    if (_filter == 'Active')  base = base.where((m) => !m.isBlocked).toList();
    if (_filter == 'Blocked') base = base.where((m) =>  m.isBlocked).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      base = base
          .where((m) =>
      m.name.toLowerCase().contains(q) ||
          m.email.toLowerCase().contains(q) ||
          m.displayPosition.toLowerCase().contains(q))
          .toList();
    }
    _shown = base;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _updateCommitteePosition(MemberItem member, String newPos) async {
    try {
      await _supabase
          .from('profiles')
          .update({'committee_position': newPos.isEmpty ? null : newPos})
          .eq('id', member.id);
      setState(() {
        member.committeePosition = newPos;
        _applyFilter();
      });
      _toast(
        newPos.isEmpty
            ? 'Committee position cleared'
            : 'Position updated to "$newPos"',
        _green,
      );
    } catch (e) {
      _toast('Failed to update position: $e', _red);
    }
  }

  Future<void> _updateMemberType(MemberItem member, String newType) async {
    try {
      await _supabase
          .from('profiles')
          .update({'member_type': newType})
          .eq('id', member.id);
      setState(() {
        member.memberType = newType;
        _applyFilter();
      });
      _toast('Member type updated to "${_memberTypeLabel(newType)}"', _green);
    } catch (e) {
      _toast('Failed to update member type: $e', _red);
    }
  }

  Future<void> _toggleBlock(MemberItem member) async {
    final newStatus = member.isBlocked ? 'active' : 'blocked';
    try {
      await _supabase
          .from('profiles')
          .update({'account_status': newStatus})
          .eq('id', member.id);

      if (newStatus == 'blocked') {
        await _supabase.from('blocked_emails').upsert({
          'email':      member.email,
          'blocked_at': DateTime.now().toIso8601String(),
          'reason':     'blocked_by_admin',
        }, onConflict: 'email');
      } else {
        await _supabase
            .from('blocked_emails')
            .delete()
            .eq('email', member.email);
      }

      setState(() {
        member.accountStatus = newStatus;
        _applyFilter();
      });
      _toast(
        newStatus == 'blocked'
            ? '${member.name} has been blocked'
            : '${member.name} has been unblocked',
        newStatus == 'blocked' ? _orange : _green,
      );
    } catch (e) {
      _toast('Failed to update block status: $e', _red);
    }
  }

  /// ✅ FIXED: Edge Function সব কিছু delete করে,
  /// তারপর Flutter এ Cloudinary image delete করে।
  Future<void> _deleteAccount(MemberItem member) async {
    _showLoadingOverlay('Deleting account…');
    try {
      // ── Edge Function call — সব tables + auth user delete করবে ──
      final response = await _supabase.functions.invoke(
        'admin-delete-user',
        body: {'uid': member.id},
      );

      final result = response.data as Map<String, dynamic>?;

      // Error check
      if (result == null || result.containsKey('error')) {
        if (mounted) Navigator.of(context).pop();
        _toast('Delete failed: ${result?['error'] ?? 'Unknown error'}', _red);
        return;
      }

      // ── Cloudinary image delete (Edge Function থেকে URL পেলে) ──
      final imageUrl = result['profileImageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await CloudinaryService.deleteFile(imageUrl, resourceType: 'image');
        } catch (_) {
          // image delete fail হলেও account delete সফল ধরো
        }
      }

      // ── blocked_emails এ add করো ──
      try {
        await _supabase.from('blocked_emails').upsert({
          'email':      member.email,
          'blocked_at': DateTime.now().toIso8601String(),
          'reason':     'account_deleted_by_admin',
        }, onConflict: 'email');
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pop(); // loading dismiss
      setState(() {
        _all.removeWhere((m) => m.id == member.id);
        _applyFilter();
      });
      _toast('${member.name}\'s account deleted permanently', _red);

    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _toast('Delete failed: $e', _red);
    }
  }

  // ── Dialogs / sheets ───────────────────────────────────────────────────────

  void _showMemberActions(MemberItem member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActionsSheet(
        member: member,
        memberTypeLabel: _memberTypeLabel,
        onChangeCommitteePosition: () {
          Navigator.pop(context);
          _showCommitteePositionSheet(member);
        },
        onChangeMemberType: () {
          Navigator.pop(context);
          _showMemberTypeSheet(member);
        },
        onBlock: () {
          Navigator.pop(context);
          _showBlockConfirm(member);
        },
        onDelete: () {
          Navigator.pop(context);
          _showDeleteConfirm(member);
        },
      ),
    );
  }

  void _showCommitteePositionSheet(MemberItem member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SelectionSheet(
        title: 'Committee Position',
        subtitle: member.name,
        icon: Icons.badge_outlined,
        current: member.committeePosition,
        options: _committeePositions,
        displayLabel: (s) => s.isEmpty ? '— No Position —' : s,
        accentColor: _cyan,
        onSelect: (pos) {
          Navigator.pop(context);
          _updateCommitteePosition(member, pos);
        },
      ),
    );
  }

  void _showMemberTypeSheet(MemberItem member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SelectionSheet(
        title: 'Member Type',
        subtitle: member.name,
        icon: Icons.people_alt_outlined,
        current: member.memberType,
        options: _memberTypes,
        displayLabel: _memberTypeLabel,
        accentColor: _teal,
        onSelect: (type) {
          Navigator.pop(context);
          _updateMemberType(member, type);
        },
      ),
    );
  }

  void _showBlockConfirm(MemberItem member) {
    final isBlocking = !member.isBlocked;
    _showConfirmDialog(
      icon:         isBlocking ? Icons.block_rounded     : Icons.lock_open_rounded,
      iconColor:    isBlocking ? _orange                 : _green,
      title:        isBlocking ? 'Block Member?'         : 'Unblock Member?',
      message:      isBlocking
          ? '${member.name} will be blocked immediately.\n\nThey won\'t be able to log in or re-register with this email address.'
          : '${member.name} will be unblocked and can log in again.',
      confirmLabel: isBlocking ? 'Block'   : 'Unblock',
      confirmColor: isBlocking ? _orange   : _green,
      onConfirm:    () => _toggleBlock(member),
    );
  }

  void _showDeleteConfirm(MemberItem member) {
    _showConfirmDialog(
      icon:         Icons.delete_forever_rounded,
      iconColor:    _red,
      title:        'Delete Account?',
      message:      'This will permanently delete ${member.name}\'s account '
          'and block their email address.\n\nThis action CANNOT be undone.',
      confirmLabel: 'Delete Forever',
      confirmColor: _red,
      onConfirm:    () => _deleteAccount(member),
    );
  }

  void _showConfirmDialog({
    required IconData     icon,
    required Color        iconColor,
    required String       title,
    required String       message,
    required String       confirmLabel,
    required Color        confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _cardBg.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: iconColor.withValues(alpha: 0.4), width: 1.2),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withValues(
                          alpha: 0.08 + _pulseCtrl.value * 0.05),
                      border: Border.all(
                          color: iconColor.withValues(
                              alpha: 0.3 + _pulseCtrl.value * 0.1)),
                    ),
                    child: Icon(icon, color: iconColor, size: 36),
                  ),
                ),
                const SizedBox(height: 20),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20)),
                const SizedBox(height: 12),
                Text(message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        height: 1.6)),
                const SizedBox(height: 28),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(confirmLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showLoadingOverlay(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _cardBg.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(
                      color: _cyan, strokeWidth: 2.5),
                  const SizedBox(height: 20),
                  Text(msg,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: _bgStart,
        appBar: _buildAppBar(),
        body: _buildBackground(child: _buildContent()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: Padding(
      padding: const EdgeInsets.all(10),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    ),
    title: const Text(
      'Member Management',
      style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 14),
        child: IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _cyan, size: 22),
          onPressed: _fetchMembers,
          tooltip: 'Refresh',
        ),
      ),
    ],
  );

  Widget _buildBackground({required Widget child}) => Stack(children: [
    Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF060E17),
            Color(0xFF0A1628),
            Color(0xFF060E17),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
    Positioned(
        top: -100,
        right: -80,
        child: _blob(300, _cyan.withValues(alpha: 0.04))),
    Positioned(
        bottom: 200,
        left: -120,
        child: _blob(280, _blue.withValues(alpha: 0.05))),
    child,
  ]);

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _buildContent() => FadeTransition(
    opacity: _fadeCtrl,
    child: Column(children: [
      _buildSearchAndFilter(),
      if (!_loading) _buildStats(),
      Expanded(
        child: _loading
            ? _buildLoading()
            : _shown.isEmpty
            ? _buildEmpty()
            : _buildList(),
      ),
    ]),
  );

  // ── Search + Filter ────────────────────────────────────────────────────────

  Widget _buildSearchAndFilter() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => setState(() {
                    _search = v;
                    _applyFilter();
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, position…',
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: _cyan.withValues(alpha: 0.7), size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _search = '';
                            _applyFilter();
                          });
                        })
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['All', 'Active', 'Blocked'].map((f) {
              final active = _filter == f;
              final color  = f == 'Blocked' ? _orange : _cyan;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _filter = f;
                    _applyFilter();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? color.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? color.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(f,
                        style: TextStyle(
                            color: active ? color : Colors.white54,
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Widget _buildStats() {
    final total   = _all.length;
    final active  = _all.where((m) => !m.isBlocked).length;
    final blocked = _all.where((m) =>  m.isBlocked).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        _statChip('Total',   total,   _cyan),
        const SizedBox(width: 8),
        _statChip('Active',  active,  _green),
        const SizedBox(width: 8),
        _statChip('Blocked', blocked, _orange),
      ]),
    );
  }

  Widget _statChip(String label, int count, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text('$count',
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.7), fontSize: 11)),
      ]),
    ),
  );

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
    itemCount: _shown.length,
    itemBuilder: (_, i) => _MemberCard(
      member: _shown[i],
      memberTypeLabel: _memberTypeLabel,
      onTap: () => _showMemberActions(_shown[i]),
      onPositionTap: () => _showCommitteePositionSheet(_shown[i]),
      onTypeTap: () => _showMemberTypeSheet(_shown[i]),
    ),
  );

  Widget _buildLoading() => Center(
    child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                  color: _cyan,
                  strokeWidth: 2.5,
                  backgroundColor: _cyan.withValues(alpha: 0.1))),
          const SizedBox(height: 16),
          Text('Loading members…',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14)),
        ]),
  );

  Widget _buildEmpty() => Center(
    child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined,
              size: 56, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text('No members found',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16)),
        ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MEMBER CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final MemberItem  member;
  final String Function(String) memberTypeLabel;
  final VoidCallback onTap;
  final VoidCallback onPositionTap;
  final VoidCallback onTypeTap;

  const _MemberCard({
    required this.member,
    required this.memberTypeLabel,
    required this.onTap,
    required this.onPositionTap,
    required this.onTypeTap,
  });

  static const _cyan   = Color(0xFF00E5FF);
  static const _orange = Color(0xFFFF8A65);
  static const _amber  = Color(0xFFFFB300);
  static const _teal   = Color(0xFF26A69A);
  static const _cardBg = Color(0xFF0F1E2E);

  Color get _accentColor {
    final t = member.memberType.toLowerCase();
    if (t.contains('advisor'))           return const Color(0xFF9C27B0);
    if (t.contains('previous'))          return const Color(0xFF9C27B0);
    if (t.contains('life'))              return _amber;
    if (t.contains('honorary'))          return _orange;
    if (t.contains('present_committee')) return _teal;
    final p = member.committeePosition.toLowerCase();
    if (p.contains('president'))         return _cyan;
    if (p.contains('secretary'))         return const Color(0xFF4A90E2);
    if (p.contains('treasurer'))         return _amber;
    return _teal;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: member.isBlocked
                ? _orange.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _buildAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(member.name,
                          style: TextStyle(
                              color: member.isBlocked
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (member.isBlocked) _blockedBadge(),
                  ]),
                  const SizedBox(height: 3),
                  Text(member.email,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (member.committeePosition.isNotEmpty)
                      _chip(
                        icon: Icons.badge_outlined,
                        label: member.committeePosition,
                        color: _accentColor,
                        onTap: onPositionTap,
                        showEdit: true,
                      ),
                    _chip(
                      icon: Icons.people_alt_outlined,
                      label: memberTypeLabel(member.memberType),
                      color: _teal,
                      onTap: onTypeTap,
                      showEdit: true,
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.more_vert_rounded,
                color: Colors.white.withValues(alpha: 0.3), size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _blockedBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _orange.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _orange.withValues(alpha: 0.3)),
    ),
    child: const Text('BLOCKED',
        style: TextStyle(
            color: _orange,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8)),
  );

  Widget _chip({
    required IconData  icon,
    required String    label,
    required Color     color,
    VoidCallback?      onTap,
    bool showEdit = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            if (showEdit) ...[
              const SizedBox(width: 3),
              Icon(Icons.edit_rounded,
                  size: 9, color: color.withValues(alpha: 0.6)),
            ],
          ]),
        ),
      );

  Widget _buildAvatar() {
    final hasImg = member.avatarUrl.isNotEmpty;
    return Stack(children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _accentColor.withValues(alpha: 0.12),
          border: Border.all(
            color: member.isBlocked
                ? _orange.withValues(alpha: 0.4)
                : _accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: hasImg
            ? ClipOval(
            child: Image.network(member.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials()))
            : _initials(),
      ),
      if (member.isBlocked)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
                color: _orange,
                shape: BoxShape.circle,
                border: Border.all(color: _cardBg, width: 2)),
            child: const Icon(Icons.block_rounded,
                size: 9, color: Colors.white),
          ),
        ),
    ]);
  }

  Widget _initials() => Center(
    child: Text(
      member.name.isNotEmpty
          ? member.name
          .trim()
          .split(' ')
          .take(2)
          .map((w) => w[0])
          .join()
          : '?',
      style: TextStyle(
          color: _accentColor,
          fontWeight: FontWeight.w700,
          fontSize: 18),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// GENERIC SELECTION BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _SelectionSheet extends StatelessWidget {
  final String               title;
  final String               subtitle;
  final IconData             icon;
  final String               current;
  final List<String>         options;
  final String Function(String) displayLabel;
  final Color                accentColor;
  final ValueChanged<String> onSelect;

  const _SelectionSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.current,
    required this.options,
    required this.displayLabel,
    required this.accentColor,
    required this.onSelect,
  });

  static const _cardBg = Color(0xFF0F1E2E);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          decoration: BoxDecoration(
            color: _cardBg.withValues(alpha: 0.97),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: options.map((opt) {
                    final isCurrent = opt == current;
                    return GestureDetector(
                      onTap: isCurrent ? null : () => onSelect(opt),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? accentColor.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? accentColor.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(displayLabel(opt),
                                style: TextStyle(
                                    color: isCurrent
                                        ? accentColor
                                        : Colors.white70,
                                    fontWeight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    fontSize: 14)),
                          ),
                          if (isCurrent)
                            Icon(Icons.check_circle_rounded,
                                color: accentColor, size: 18),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIONS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ActionsSheet extends StatelessWidget {
  final MemberItem   member;
  final String Function(String) memberTypeLabel;
  final VoidCallback onChangeCommitteePosition;
  final VoidCallback onChangeMemberType;
  final VoidCallback onBlock;
  final VoidCallback onDelete;

  const _ActionsSheet({
    required this.member,
    required this.memberTypeLabel,
    required this.onChangeCommitteePosition,
    required this.onChangeMemberType,
    required this.onBlock,
    required this.onDelete,
  });

  static const _cyan   = Color(0xFF00E5FF);
  static const _orange = Color(0xFFFF8A65);
  static const _green  = Color(0xFF4CAF50);
  static const _red    = Color(0xFFEF5350);
  static const _teal   = Color(0xFF26A69A);
  static const _cardBg = Color(0xFF0F1E2E);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          decoration: BoxDecoration(
            color: _cardBg.withValues(alpha: 0.97),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Row(children: [
              const Icon(Icons.manage_accounts_rounded,
                  color: _cyan, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text(member.email,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12)),
                  ],
                ),
              ),
              if (member.isBlocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _orange.withValues(alpha: 0.35)),
                  ),
                  child: const Text('BLOCKED',
                      style: TextStyle(
                          color: _orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                ),
            ]),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 16),

            _actionTile(
              icon: Icons.badge_outlined,
              color: _cyan,
              label: 'Change Committee Position',
              subtitle: member.committeePosition.isEmpty
                  ? 'Not assigned'
                  : 'Current: ${member.committeePosition}',
              onTap: onChangeCommitteePosition,
            ),
            const SizedBox(height: 10),

            _actionTile(
              icon: Icons.people_alt_outlined,
              color: _teal,
              label: 'Change Member Type',
              subtitle: 'Current: ${memberTypeLabel(member.memberType)}',
              onTap: onChangeMemberType,
            ),
            const SizedBox(height: 10),

            _actionTile(
              icon: member.isBlocked
                  ? Icons.lock_open_rounded
                  : Icons.block_rounded,
              color: member.isBlocked ? _green : _orange,
              label: member.isBlocked ? 'Unblock Member' : 'Block Member',
              subtitle: member.isBlocked
                  ? 'Allow this member to log in again'
                  : 'Prevent login & new sign-up with this email',
              onTap: onBlock,
            ),
            const SizedBox(height: 10),

            _actionTile(
              icon: Icons.delete_forever_rounded,
              color: _red,
              label: 'Delete Account',
              subtitle: 'Permanently remove — cannot be undone',
              onTap: onDelete,
              isDanger: true,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData     icon,
    required Color        color,
    required String       label,
    required String       subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDanger ? 0.08 : 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: isDanger ? color : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.4), size: 14),
          ]),
        ),
      );
}