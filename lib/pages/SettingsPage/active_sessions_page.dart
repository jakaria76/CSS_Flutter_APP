import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/services/session_service.dart';
import 'settings_constants.dart';

class ActiveSessionsPage extends StatefulWidget {
  const ActiveSessionsPage({super.key});

  @override
  State<ActiveSessionsPage> createState() => _ActiveSessionsPageState();
}

class _ActiveSessionsPageState extends State<ActiveSessionsPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late AnimationController _fadeCtrl;
  bool _isLoading = true;
  bool _revoking = false;
  List<_Session> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
    )..forward();
    _fetchSessions();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Timestamp parse ──────────────────────────────────────────────────────

  DateTime _parseTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return DateTime.now();
    if (parsed.isUtc) return parsed.toLocal();
    return DateTime.utc(
      parsed.year, parsed.month, parsed.day,
      parsed.hour, parsed.minute, parsed.second,
      parsed.millisecond, parsed.microsecond,
    ).toLocal();
  }

  // ─── Fetch sessions ───────────────────────────────────────────────────────

  Future<void> _fetchSessions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final currentKey = SessionService.getCurrentSessionKey();

      final response = await _supabase
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .order('last_active', ascending: false);

      if (!mounted) return;

      setState(() {
        _sessions = (response as List).map((row) {
          final deviceName = (row['device_name'] ?? '').toString().trim();
          final deviceModel = (row['device_model'] ?? '').toString().trim();
          final combined =
          [deviceName, deviceModel].where((s) => s.isNotEmpty).join(' ');

          return _Session(
            id: row['id'] as String,
            sessionKey: row['session_key'] as String? ?? '',
            deviceName:
            combined.isEmpty ? SC.tr('unknown_device') : combined,
            osVersion: (row['os_version'] as String?)?.isNotEmpty == true
                ? row['os_version'] as String
                : SC.tr('unknown_os'),
            lastActive: _parseTimestamp(row['last_active'] as String?),
            isCurrent: row['session_key'] == currentKey,
          );
        }).toList();
      });
    } catch (e) {
      if (mounted) SC.toast(context, SC.tr('session_load_error'), SC.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Revoke single session ────────────────────────────────────────────────

  Future<void> _confirmRevoke(_Session s) async {
    final confirmed = await _showConfirmDialog(
      title: SC.tr('revoke_confirm_title'),
      message: '${s.deviceName}\n${SC.tr('revoke_confirm_msg')}',
    );
    if (!confirmed) return;
    await _revokeSession(s);
  }

  Future<void> _revokeSession(_Session s) async {
    setState(() => _revoking = true);
    try {
      // ✅ DB থেকে delete করো — ঐ device এ AuthGuardService Realtime event পেয়ে auto logout করবে
      await _supabase.from('user_sessions').delete().eq('id', s.id);

      if (!mounted) return;
      setState(() => _sessions.removeWhere((x) => x.id == s.id));
      SC.toast(context, SC.tr('session_revoked'), SC.orange);
    } catch (_) {
      if (mounted) SC.toast(context, SC.tr('session_revoke_error'), SC.red);
    } finally {
      if (mounted) setState(() => _revoking = false);
    }
  }

  // ─── Revoke all other sessions ────────────────────────────────────────────

  Future<void> _confirmRevokeAll() async {
    final confirmed = await _showConfirmDialog(
      title: SC.tr('revoke_all_confirm_title'),
      message: SC.tr('revoke_all_confirm_msg'),
    );
    if (!confirmed) return;
    await _revokeAll();
  }

  Future<void> _revokeAll() async {
    setState(() => _revoking = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      final currentKey = SessionService.getCurrentSessionKey();
      if (userId == null) return;

      if (currentKey != null) {
        // ✅ Current session বাদে সব delete — ঐ device গুলোতে auto logout হবে
        await _supabase
            .from('user_sessions')
            .delete()
            .eq('user_id', userId)
            .neq('session_key', currentKey);
      } else {
        await _supabase
            .from('user_sessions')
            .delete()
            .eq('user_id', userId);
      }

      if (!mounted) return;
      setState(() => _sessions.removeWhere((s) => !s.isCurrent));
      SC.toast(context, SC.tr('all_sessions_revoked'), SC.green);
    } catch (_) {
      if (mounted) SC.toast(context, SC.tr('something_wrong'), SC.red);
    } finally {
      if (mounted) setState(() => _revoking = false);
    }
  }

  // ─── Confirm Dialog ───────────────────────────────────────────────────────

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
    final isDark = SC.isDark;
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF4A5568);

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        content: Text(message,
            style: TextStyle(color: subColor, fontSize: 13, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(SC.tr('cancel'),
                style:
                TextStyle(color: subColor, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(SC.tr('confirm'),
                style: const TextStyle(
                    color: SC.orange, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  IconData _platformIcon(String os) {
    final lower = os.toLowerCase();
    if (lower.contains('ios') || lower.contains('iphone')) {
      return Icons.phone_iphone_rounded;
    }
    if (lower.contains('android')) return Icons.phone_android_rounded;
    return Icons.devices_rounded;
  }

  String _timeAgo(DateTime localDt) {
    final diff = DateTime.now().difference(localDt);
    if (diff.inSeconds < 60) return SC.tr('just_now');
    if (diff.inMinutes < 60) {
      return SC.tr('min_ago').replaceAll('@min', diff.inMinutes.toString());
    }
    if (diff.inHours < 24) {
      return SC.tr('hour_ago').replaceAll('@hour', diff.inHours.toString());
    }
    return SC.tr('day_ago').replaceAll('@day', diff.inDays.toString());
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF4A5568);
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
            SC.blob(240, SC.blue.withValues(alpha: 0.05)),
            Column(
              children: [
                _buildAppBar(textColor),
                Expanded(
                  child: _isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                        color: SC.cyan, strokeWidth: 2.5),
                  )
                      : FadeTransition(
                    opacity: _fadeCtrl,
                    child: RefreshIndicator(
                      color: SC.cyan,
                      onRefresh: _fetchSessions,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 20),
                        children: [
                          // ── Header info ──────────────────────────
                          _buildHeaderInfo(subTextColor),
                          const SizedBox(height: 16),

                          // ── Session cards ─────────────────────────
                          for (final s in _sessions) ...[
                            _sessionCard(s, cardColor, textColor,
                                subTextColor, borderColor),
                            const SizedBox(height: 12),
                          ],

                          // ── Empty state ───────────────────────────
                          if (_sessions.isEmpty)
                            _buildEmptyState(subTextColor),

                          const SizedBox(height: 8),

                          // ── Info tip ──────────────────────────────
                          _buildInfoTip(subTextColor),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(Color textColor) {
    final otherSessions = _sessions.where((s) => !s.isCurrent).toList();
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10, bottom: 4),
      child: Row(
        children: [
          IconButton(
            icon:
            Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              SC.tr('sessions_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
          ),
          if (otherSessions.isNotEmpty)
            TextButton(
              onPressed: _revoking ? null : _confirmRevokeAll,
              child: Text(
                SC.tr('revoke_all'),
                style: TextStyle(
                  color: _revoking
                      ? textColor.withValues(alpha: 0.3)
                      : SC.orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ─── Header info ──────────────────────────────────────────────────────────

  Widget _buildHeaderInfo(Color subTextColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            SC.tr('active_sessions_count')
                .replaceAll('@count', _sessions.length.toString()),
            style: TextStyle(color: subTextColor, fontSize: 13),
          ),
        ),
        // ✅ Realtime badge — user কে জানাবে live sync চলছে
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: SC.cyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border:
            Border.all(color: SC.cyan.withValues(alpha: 0.25), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SC.cyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Live',
                style: TextStyle(
                  color: SC.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(Color subTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.devices_rounded, color: subTextColor, size: 48),
            const SizedBox(height: 12),
            Text(
              SC.tr('no_sessions'),
              style: TextStyle(color: subTextColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Info tip ─────────────────────────────────────────────────────────────

  Widget _buildInfoTip(Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SC.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: SC.blue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              SC.tr('session_info_tip'),
              style: TextStyle(
                  color: subTextColor, fontSize: 12, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Session Card ─────────────────────────────────────────────────────────

  Widget _sessionCard(
      _Session s,
      Color cardColor,
      Color textColor,
      Color subTextColor,
      Color borderColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: s.isCurrent
            ? SC.cyan.withValues(alpha: 0.06)
            : cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: s.isCurrent
                ? SC.cyan.withValues(alpha: 0.3)
                : borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: SC.isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Platform icon ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (s.isCurrent ? SC.cyan : SC.blue)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _platformIcon(s.osVersion),
              color: s.isCurrent ? SC.cyan : SC.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // ── Info ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.deviceName,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.isCurrent) ...[
                      const SizedBox(width: 8),
                      // ✅ "এই device" badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: SC.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          SC.tr('active_now'),
                          style: const TextStyle(
                              color: SC.cyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(s.osVersion,
                    style:
                    TextStyle(color: subTextColor, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _timeAgo(s.lastActive),
                  style: TextStyle(
                      color: subTextColor.withValues(alpha: 0.6),
                      fontSize: 11),
                ),
              ],
            ),
          ),

          // ── Revoke button (other sessions only) ───────────────────
          if (!s.isCurrent)
            _revoking
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: SC.orange, strokeWidth: 2),
            )
                : _RevokeButton(
              onTap: () => _confirmRevoke(s),
            ),
        ],
      ),
    );
  }
}

// ─── Revoke Button Widget ─────────────────────────────────────────────────────

class _RevokeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RevokeButton({required this.onTap});

  @override
  State<_RevokeButton> createState() => _RevokeButtonState();
}

class _RevokeButtonState extends State<_RevokeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _pressed
              ? SC.orange.withOpacity(0.2)
              : SC.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SC.orange.withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded,
                color: SC.orange, size: 14),
            const SizedBox(width: 5),
            Text(
              SC.tr('revoke'),
              style: const TextStyle(
                color: SC.orange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class _Session {
  final String id;
  final String sessionKey;
  final String deviceName;
  final String osVersion;
  final DateTime lastActive;
  final bool isCurrent;

  const _Session({
    required this.id,
    required this.sessionKey,
    required this.deviceName,
    required this.osVersion,
    required this.lastActive,
    required this.isCurrent,
  });
}