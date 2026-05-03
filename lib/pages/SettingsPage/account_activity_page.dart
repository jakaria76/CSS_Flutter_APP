import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_constants.dart';

class AccountActivityPage extends StatefulWidget {
  const AccountActivityPage({super.key});

  @override
  State<AccountActivityPage> createState() => _AccountActivityPageState();
}

class _AccountActivityPageState extends State<AccountActivityPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  List<_Activity> _activities = [];
  bool _loading = true;
  bool _hasError = false;
  final _db = Supabase.instance.client;

  // activity_type → icon, color mapping
  static const _typeConfig = <String, Map<String, dynamic>>{
    'login_success':   {'icon': Icons.login_rounded,         'colorKey': 'green'},
    'login_failed':    {'icon': Icons.warning_amber_rounded,  'colorKey': 'red'},
    'logout':          {'icon': Icons.logout_rounded,         'colorKey': 'orange'},
    'profile_update':  {'icon': Icons.edit_rounded,           'colorKey': 'cyan'},
    'password_change': {'icon': Icons.lock_reset_rounded,     'colorKey': 'blue'},
    'email_change_req':{'icon': Icons.email_rounded,          'colorKey': 'purple'},
  };

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
    )..forward();
    _loadActivity();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Color key থেকে SC color নেওয়া ──
  Color _resolveColor(String key) {
    switch (key) {
      case 'green':  return SC.green;
      case 'red':    return SC.red;
      case 'orange': return SC.orange;
      case 'cyan':   return SC.cyan;
      case 'blue':   return SC.blue;
      case 'purple': return SC.purple;
      default:       return SC.cyan;
    }
  }

  // ── Supabase থেকে real data load ──
  Future<void> _loadActivity() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) {
        setState(() { _loading = false; _hasError = true; });
        return;
      }

      final response = await _db
          .from('account_activities')
          .select('id, activity_type, detail, device, location, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      if (!mounted) return;

      final list = (response as List).map((row) {
        final type = row['activity_type'] as String? ?? 'login_success';
        final config = _typeConfig[type] ?? _typeConfig['login_success']!;

        // detail build করা
        final detail = row['detail'] as String?;
        final device = row['device'] as String?;
        final location = row['location'] as String?;

        String detailText = '';
        if (device != null && location != null) {
          detailText = '$device · $location';
        } else if (device != null) {
          detailText = device;
        } else if (detail != null) {
          detailText = detail;
        }

        return _Activity(
          id: row['id'] as String,
          titleKey: type,
          detailText: detailText,
          isDetailKey: detailText.isEmpty && detail != null,
          detailKey: detail ?? '',
          time: DateTime.parse(row['created_at'] as String).toLocal(),
          color: _resolveColor(config['colorKey'] as String),
          icon: config['icon'] as IconData,
        );
      }).toList();

      setState(() {
        _activities = list;
        _loading = false;
      });

      _fadeCtrl
        ..reset()
        ..forward();
    } catch (e) {
      debugPrint('Activity load error: $e');
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  // ── Time format ──
  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return SC.tr('just_now');
    if (diff.inHours < 1) {
      return SC.tr('min_ago').replaceAll('@min', diff.inMinutes.toString());
    }
    if (diff.inDays < 1) {
      return SC.tr('hour_ago').replaceAll('@hour', diff.inHours.toString());
    }
    if (diff.inDays < 7) {
      return SC.tr('day_ago').replaceAll('@day', diff.inDays.toString());
    }
    return '${dt.day}/${dt.month}/${dt.year}';
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
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF4A5568);
    final timelineColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Background
            Container(
                decoration: BoxDecoration(gradient: SC.currentGradient)),
            Positioned(
              top: -60,
              right: -60,
              child: SC.blob(240, SC.teal.withValues(alpha: 0.05)),
            ),
            Column(
              children: [
                _buildAppBar(textColor),
                Expanded(
                  child: _loading
                      ? Center(
                      child: CircularProgressIndicator(color: SC.cyan))
                      : _hasError
                      ? _buildErrorState(subTextColor)
                      : _activities.isEmpty
                      ? _buildEmptyState(subTextColor)
                      : RefreshIndicator(
                    color: SC.cyan,
                    backgroundColor: isDark
                        ? SC.cardBg
                        : Colors.white,
                    onRefresh: _loadActivity,
                    child: FadeTransition(
                      opacity: _fadeCtrl,
                      child: ListView.builder(
                        physics:
                        const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                            18, 12, 18, 40),
                        itemCount: _activities.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 20),
                              child: Text(
                                SC.tr('recent_activities')
                                    .replaceAll(
                                    '@count',
                                    _activities.length
                                        .toString()),
                                style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13),
                              ),
                            );
                          }
                          final a = _activities[index - 1];
                          final isLast =
                              index == _activities.length;
                          return _activityItem(
                              a,
                              isLast,
                              textColor,
                              subTextColor,
                              timelineColor);
                        },
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

  // ── AppBar ──
  Widget _buildAppBar(Color textColor) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10, bottom: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              SC.tr('activity_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor, size: 22),
            onPressed: _loading ? null : _loadActivity,
          ),
        ],
      ),
    );
  }

  // ── Activity Item ──
  Widget _activityItem(
      _Activity a,
      bool isLast,
      Color textColor,
      Color subTextColor,
      Color timelineColor,
      ) {
    // detail text নির্ধারণ
    final displayDetail = a.detailText.isNotEmpty
        ? a.detailText
        : (a.isDetailKey ? SC.tr(a.detailKey) : a.detailKey);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: a.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: a.color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(a.icon, color: a.color, size: 18),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin:
                      const EdgeInsets.symmetric(vertical: 4),
                      color: timelineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 7),
                  Text(
                    SC.tr(a.titleKey),
                    style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  if (displayDetail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      displayDetail,
                      style: TextStyle(
                          color: subTextColor, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(a.time),
                    style: TextStyle(
                        color: subTextColor.withValues(alpha: 0.6),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState(Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded,
              size: 56, color: subTextColor.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(SC.tr('no_activity'),
              style: TextStyle(color: subTextColor, fontSize: 15)),
        ],
      ),
    );
  }

  // ── Error State ──
  Widget _buildErrorState(Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 56, color: SC.red.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(SC.tr('activity_error'),
              style: TextStyle(color: subTextColor, fontSize: 15)),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _loadActivity,
            icon: Icon(Icons.refresh_rounded, color: SC.cyan),
            label: Text(SC.tr('retry'),
                style: TextStyle(color: SC.cyan)),
          ),
        ],
      ),
    );
  }
}

// ── Model ──
class _Activity {
  final String id;
  final String titleKey;
  final String detailText;   // device · location (direct show)
  final bool isDetailKey;    // detailKey টা SC.tr() দিয়ে translate করতে হবে?
  final String detailKey;    // translation key বা raw text
  final DateTime time;
  final Color color;
  final IconData icon;

  const _Activity({
    required this.id,
    required this.titleKey,
    required this.detailText,
    required this.isDetailKey,
    required this.detailKey,
    required this.time,
    required this.color,
    required this.icon,
  });
}