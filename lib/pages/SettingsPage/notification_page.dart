import 'package:css/pages/NoticePage/notice_page.dart';
import 'package:css/pages/complaints/complaint_detail_page.dart';
import 'package:css/pages/complaints/ManageComplaintPage.dart';
import 'package:css/models/complaint_model.dart';
import 'package:css/models/post_model.dart';
import 'package:css/pages/feed/post_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/pages/Blood/emergency_requests_page.dart';
import 'package:css/pages/events/event_details_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  List<_Notif> _notifs = [];
  bool _loading    = true;
  bool _hasError   = false;
  bool _navigating = false;
  RealtimeChannel? _realtimeChannel;
  final _db = Supabase.instance.client;

  static const _typeConfig = <String, Map<String, dynamic>>{
    'login_success':      {'icon': Icons.login_rounded,          'colorKey': 'green'},
    'login_failed':       {'icon': Icons.warning_amber_rounded,  'colorKey': 'red'},
    'logout':             {'icon': Icons.logout_rounded,         'colorKey': 'orange'},
    'profile_update':     {'icon': Icons.edit_rounded,           'colorKey': 'cyan'},
    'password_change':    {'icon': Icons.lock_reset_rounded,     'colorKey': 'blue'},
    'email_change_req':   {'icon': Icons.email_rounded,          'colorKey': 'purple'},
    'blood_request':      {'icon': Icons.bloodtype_rounded,      'colorKey': 'red'},
    'event_notification': {'icon': Icons.event_rounded,          'colorKey': 'purple'},
    'notice':             {'icon': Icons.campaign_rounded,       'colorKey': 'cyan'},
    'complaint':          {'icon': Icons.report_outlined,        'colorKey': 'orange'},
    'complaint_reply':    {'icon': Icons.reply_rounded,          'colorKey': 'green'},
    'new_post':           {'icon': Icons.article_rounded,        'colorKey': 'cyan'},
    'general':            {'icon': Icons.notifications_rounded,  'colorKey': 'cyan'},
  };

  static const _fallback = <String, Map<String, String>>{
    'login_success':           {'বাংলা': 'লগইন সফল',                                   'English': 'Login Successful'},
    'login_failed':            {'বাংলা': 'লগইন ব্যর্থ',                                 'English': 'Login Failed'},
    'logout':                  {'বাংলা': 'লগআউট',                                       'English': 'Logged Out'},
    'profile_update':          {'বাংলা': 'প্রোফাইল আপডেট',                             'English': 'Profile Updated'},
    'password_change':         {'বাংলা': 'পাসওয়ার্ড পরিবর্তন',                          'English': 'Password Changed'},
    'email_change_req':        {'বাংলা': 'ইমেইল পরিবর্তনের অনুরোধ',                    'English': 'Email Change Request'},
    'blood_request':           {'বাংলা': '🩸 জরুরি রক্তের প্রয়োজন!',                   'English': '🩸 Emergency Blood Needed!'},
    'blood_request_title':     {'বাংলা': '🩸 জরুরি রক্তের প্রয়োজন!',                   'English': '🩸 Emergency Blood Needed!'},
    'blood_request_body':      {'বাংলা': 'কেউ জরুরি রক্তের অনুরোধ করেছে।',             'English': 'Someone posted an emergency blood request.'},
    'event_notification':      {'বাংলা': 'নতুন ইভেন্ট',                                 'English': 'New Event'},
    'event_notification_body': {'বাংলা': 'একটি নতুন ইভেন্ট তৈরি হয়েছে',                'English': 'A new event has been created'},
    'event_created':           {'বাংলা': 'নতুন ইভেন্ট',                                 'English': 'New Event'},
    'event_created_body':      {'বাংলা': 'একটি নতুন ইভেন্ট তৈরি হয়েছে',                'English': 'A new event has been created'},
    'notice':                  {'বাংলা': 'নতুন নোটিশ',                                  'English': 'New Notice'},
    'notice_body':             {'বাংলা': 'একটি নতুন নোটিশ প্রকাশিত হয়েছে',             'English': 'A new notice has been published'},
    'notice_new_title':        {'বাংলা': 'নতুন নোটিশ',                                  'English': 'New Notice'},
    'notice_new_body':         {'বাংলা': 'একটি নতুন নোটিশ এসেছে',                      'English': 'A new notice has arrived'},
    'complaint':               {'বাংলা': 'নতুন অভিযোগ',                                 'English': 'New Complaint'},
    'complaint_body':          {'বাংলা': 'একজন ব্যবহারকারী নতুন অভিযোগ জমা দিয়েছে',    'English': 'A user submitted a new complaint'},
    'new_complaint_title':     {'বাংলা': 'নতুন অভিযোগ',                                 'English': 'New Complaint'},
    'new_complaint_body':      {'বাংলা': 'একজন ব্যবহারকারী নতুন অভিযোগ জমা দিয়েছে',    'English': 'A user submitted a new complaint'},
    'complaint_reply':         {'বাংলা': 'অভিযোগের উত্তর এসেছে',                        'English': 'Complaint Replied'},
    'complaint_reply_body':    {'বাংলা': 'আপনার অভিযোগে অ্যাডমিন উত্তর দিয়েছেন',      'English': 'Admin has replied to your complaint'},
    'complaint_replied_title': {'বাংলা': 'অভিযোগের উত্তর এসেছে',                        'English': 'Complaint Replied'},
    'complaint_replied_body':  {'বাংলা': 'আপনার অভিযোগে অ্যাডমিন উত্তর দিয়েছেন',      'English': 'Admin has replied to your complaint'},
    'new_post':                {'বাংলা': 'নতুন পোস্ট',                                  'English': 'New Post'},
    'new_post_title':          {'বাংলা': 'নতুন পোস্ট',                                  'English': 'New Post'},
    'new_post_body':           {'বাংলা': 'একটি নতুন পোস্ট প্রকাশিত হয়েছে',             'English': 'A new post has been published'},
    'general':                 {'বাংলা': 'নোটিফিকেশন',                                  'English': 'Notification'},
    'general_body':            {'বাংলা': 'আপনার অ্যাকাউন্টে একটি কার্যক্রম হয়েছে',      'English': 'An activity occurred on your account'},
    'login_success_body':      {'বাংলা': 'আপনার অ্যাকাউন্টে সফলভাবে লগইন হয়েছে',       'English': 'You logged in successfully'},
    'login_failed_body':       {'বাংলা': 'ভুল পাসওয়ার্ড দিয়ে লগইনের চেষ্টা হয়েছে',    'English': 'A failed login attempt was detected'},
    'logout_body':             {'বাংলা': 'আপনি লগআউট করেছেন',                           'English': 'You have been logged out'},
    'profile_update_body':     {'বাংলা': 'আপনার প্রোফাইল তথ্য আপডেট হয়েছে',            'English': 'Your profile info was updated'},
    'password_change_body':    {'বাংলা': 'আপনার পাসওয়ার্ড সফলভাবে পরিবর্তন হয়েছে',    'English': 'Your password was changed successfully'},
    'email_change_req_body':   {'বাংলা': 'ইমেইল পরিবর্তনের অনুরোধ করা হয়েছে',         'English': 'An email change request was submitted'},
    'tapToView':               {'বাংলা': 'দেখুন',                                        'English': 'View'},
    'notifications':           {'বাংলা': 'নোটিফিকেশন',                                  'English': 'Notifications'},
    'notif_empty':             {'বাংলা': 'কোনো নোটিফিকেশন নেই',                         'English': 'No notifications yet'},
    'notif_error':             {'বাংলা': 'লোড করতে ব্যর্থ হয়েছে',                       'English': 'Failed to load notifications'},
    'retry':                   {'বাংলা': 'আবার চেষ্টা করুন',                             'English': 'Retry'},
    'delete_notif':            {'বাংলা': 'মুছে ফেলুন',                                  'English': 'Delete'},
    'delete_confirm_title':    {'বাংলা': 'নোটিফিকেশন মুছুন',                            'English': 'Delete Notification'},
    'delete_confirm_body':     {'বাংলা': 'এই নোটিফিকেশনটি মুছে ফেলবেন?',               'English': 'Delete this notification?'},
    'cancel':                  {'বাংলা': 'বাতিল',                                        'English': 'Cancel'},
    'delete_all':              {'বাংলা': 'সব মুছুন',                                     'English': 'Clear All'},
    'delete_all_confirm':      {'বাংলা': 'সব নোটিফিকেশন মুছে ফেলবেন?',                  'English': 'Delete all notifications?'},
    'new_notif_arrived':       {'বাংলা': 'নতুন নোটিফিকেশন এসেছে',                       'English': 'New notification arrived'},
  };

  String _tr(String key) {
    final scResult = SC.tr(key);
    if (scResult == key) {
      final lang = SC.languageNotifier.value;
      return _fallback[key]?[lang] ?? _fallback[key]?['বাংলা'] ?? key;
    }
    return scResult;
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 0,
    )..forward();
    _loadNotifs();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── REALTIME SUBSCRIPTION ────────────────────────────────────────
  void _subscribeRealtime() {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeChannel = _db
        .channel('notifications_$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq, // এখানে ঠিক করা হয়েছে
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        if (!mounted) return;
        final row    = payload.newRecord;
        final type   = row['type'] as String? ?? 'general';
        final config = _typeConfig[type] ?? _typeConfig['general']!;

        final newNotif = _Notif(
          id:          row['id'] as String,
          titleKey:    row['title_key'] as String? ?? type,
          bodyKey:     row['body_key']  as String? ?? 'general_body',
          type:        type,
          isRead:      row['is_read']   as bool? ?? false,
          time:        DateTime.parse(row['created_at'] as String).toLocal(),
          color:       _resolveColor(config['colorKey'] as String),
          icon:        config['icon'] as IconData,
          requestId:   row['request_id'] as String?,
          eventId:     row['event_id']?.toString(),
          noticeId:    row['notice_id']?.toString(),
          complaintId: row['complaint_id']?.toString(),
          postId:      row['post_id']?.toString(),
          senderName:  row['sender_name'] as String?,
        );

        setState(() {
          _notifs = [newNotif, ..._notifs]
            ..sort((a, b) => b.time.compareTo(a.time));
        });
        HapticFeedback.lightImpact();
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'notifications',
      callback: (payload) {
        if (!mounted) return;
        final oldId = payload.oldRecord['id'] as String?;
        if (oldId != null) {
          setState(() => _notifs.removeWhere((n) => n.id == oldId));
        }
      },
    )
        .subscribe();
  }

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

  Future<void> _loadNotifs() async {
    if (!mounted) return;
    setState(() { _loading = true; _hasError = false; });

    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) {
        setState(() { _loading = false; _hasError = true; });
        return;
      }

      final response = await _db
          .from('notifications')
          .select(
        'id, title_key, body_key, type, is_read, created_at, '
            'request_id, event_id, notice_id, complaint_id, post_id, sender_name',
      )
          .eq('user_id', userId)
      // ── newest first ──────────────────────────────────────────
          .order('created_at', ascending: false)
          .limit(100);

      if (!mounted) return;

      final rows = response as List;
      final list = rows.map((row) {
        final type   = row['type'] as String? ?? 'general';
        final config = _typeConfig[type] ?? _typeConfig['general']!;
        return _Notif(
          id:          row['id'] as String,
          titleKey:    row['title_key'] as String? ?? type,
          bodyKey:     row['body_key']  as String? ?? 'general_body',
          type:        type,
          isRead:      row['is_read']   as bool? ?? false,
          time:        DateTime.parse(row['created_at'] as String).toLocal(),
          color:       _resolveColor(config['colorKey'] as String),
          icon:        config['icon'] as IconData,
          requestId:   row['request_id'] as String?,
          eventId:     row['event_id']?.toString(),
          noticeId:    row['notice_id']?.toString(),
          complaintId: row['complaint_id']?.toString(),
          postId:      row['post_id']?.toString(),
          senderName:  row['sender_name'] as String?,
        );
      }).toList();

      // ensure sorted by newest first
      list.sort((a, b) => b.time.compareTo(a.time));

      setState(() { _notifs = list; _loading = false; });
      _fadeCtrl..reset()..forward();

      if (list.any((n) => !n.isRead)) {
        _markAllRead(userId);
      }
    } catch (e) {
      debugPrint('🔔 Notif load error: $e');
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _markAllRead(String userId) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      if (mounted) {
        setState(() {
          _notifs = _notifs.map((n) => n.copyWith(isRead: true)).toList();
        });
      }
    } catch (_) {}
  }

  // ─── DELETE SINGLE (tap the small icon on card) ───────────────────
  Future<void> _deleteNotifDirect(_Notif n) async {
    HapticFeedback.mediumImpact();
    // optimistic remove
    setState(() => _notifs.removeWhere((x) => x.id == n.id));
    try {
      await _db.from('notifications').delete().eq('id', n.id);
    } catch (e) {
      debugPrint('🗑️ Delete notif error: $e');
      // restore if failed
      if (mounted) {
        setState(() {
          _notifs = [..._notifs, n]..sort((a, b) => b.time.compareTo(a.time));
        });
      }
    }
  }

  // ─── DELETE ALL ───────────────────────────────────────────────────
  Future<void> _deleteAll() async {
    if (_notifs.isEmpty) return;
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SC.isDark ? const Color(0xFF0F1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_tr('delete_all'),
            style: TextStyle(
                color: SC.isDark ? Colors.white : const Color(0xFF1A2332),
                fontWeight: FontWeight.w800)),
        content: Text(_tr('delete_all_confirm'),
            style: TextStyle(
                color: SC.isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : const Color(0xFF4A5568))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_tr('cancel'),
                style: TextStyle(color: SC.cyan, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_tr('delete_all'),
                style: TextStyle(color: SC.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.heavyImpact();
    final backup = List<_Notif>.from(_notifs);
    setState(() => _notifs = []);
    try {
      await _db.from('notifications').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('🗑️ Delete all error: $e');
      if (mounted) setState(() => _notifs = backup);
    }
  }

  Future<void> _onNotifTap(_Notif n) async {
    HapticFeedback.lightImpact();

    if (!n.isRead) {
      try {
        await _db.from('notifications').update({'is_read': true}).eq('id', n.id);
        if (mounted) {
          setState(() {
            _notifs = _notifs
                .map((x) => x.id == n.id ? x.copyWith(isRead: true) : x)
                .toList();
          });
        }
      } catch (_) {}
    }

    if (!mounted) return;

    if (n.type == 'blood_request') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EmergencyRequestsPage()));

    } else if (n.type == 'event_notification') {
      if (n.eventId == null) return;
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => EventDetailsPage(eventId: int.parse(n.eventId!))));

    } else if (n.type == 'notice') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NoticePage()));

    } else if (n.type == 'complaint' || n.type == 'complaint_reply') {
      if (n.complaintId == null || _navigating) return;
      setState(() => _navigating = true);
      try {
        final data = await _db.from('complaints').select('''
              *, profiles!complaints_user_id_fkey (full_name, profile_image_url)
            ''').eq('id', n.complaintId!).single();
        if (!mounted) return;
        final profile   = data['profiles'];
        final complaint = Complaint.fromMap({
          ...data,
          'user_full_name':         profile?['full_name'],
          'user_profile_image_url': profile?['profile_image_url'],
        });
        final profileData = await _db
            .from('profiles').select('role')
            .eq('id', _db.auth.currentUser!.id).single();
        if (!mounted) return;
        final isAdmin = profileData['role'] == 'admin';
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => isAdmin
              ? ManageComplaintPage(complaint: complaint)
              : ComplaintDetailPage(complaint: complaint),
        ));
      } catch (e) {
        debugPrint('🔔 Complaint fetch error: $e');
        if (mounted) SC.toast(context, _tr('notif_error'), SC.red);
      } finally {
        if (mounted) setState(() => _navigating = false);
      }

    } else if (n.type == 'new_post') {
      if (n.postId == null || _navigating) return;
      setState(() => _navigating = true);
      try {
        final data = await _db.from('posts').select('''
              *, post_images (image_url, display_order), comments (count)
            ''').eq('id', n.postId!).single();
        if (!mounted) return;
        final post = Post.fromMap(data);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => PostDetailPage(post: post)));
      } catch (e) {
        debugPrint('🔔 Post fetch error: $e');
        if (mounted) SC.toast(context, _tr('notif_error'), SC.red);
      } finally {
        if (mounted) setState(() => _navigating = false);
      }
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    final lang = SC.languageNotifier.value;
    final isBn = lang == 'বাংলা';

    // ১. যদি সময়ের পার্থক্য নেগেটিভ হয় (সার্ভার টাইমের কারণে)
    // অথবা ৫ সেকেন্ডের কম হয়, তবে "Just now" দেখাবে।
    if (diff.isNegative || diff.inSeconds < 5) {
      return isBn ? 'এইমাত্র' : 'Just now';
    }

    // ২. ৬০ সেকেন্ডের কম হলে সেকেন্ড দেখাবে
    if (diff.inSeconds < 60) {
      return isBn ? '${diff.inSeconds} সেকেন্ড আগে' : '${diff.inSeconds}s ago';
    }

    // ৩. ৬০ মিনিটের কম হলে মিনিট দেখাবে
    if (diff.inMinutes < 60) {
      return isBn ? '${diff.inMinutes} মিনিট আগে' : '${diff.inMinutes}m ago';
    }

    // ৪. বাকি লজিক আপনার কোডের মতোই থাকবে...
    if (diff.inHours < 24) {
      return isBn ? '${diff.inHours} ঘণ্টা আগে' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 30) {
      return isBn ? '${diff.inDays} দিন আগে' : '${diff.inDays}d ago';
    }
    final months = (diff.inDays / 30).floor();
    if (months < 12) {
      return isBn ? '$months মাস আগে' : '${months}mo ago';
    }
    final years = (diff.inDays / 365).floor();
    return isBn ? '$years বছর আগে' : '${years}y ago';
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
    final isDark       = SC.isDark;
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF4A5568);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
            Positioned(
              top: -60, right: -60,
              child: SC.blob(220, SC.cyan.withValues(alpha: 0.04)),
            ),
            Column(
              children: [
                _buildAppBar(textColor),
                Expanded(
                  child: _loading || _navigating
                      ? Center(child: CircularProgressIndicator(color: SC.cyan))
                      : _hasError
                      ? _buildErrorState(subTextColor)
                      : _notifs.isEmpty
                      ? _buildEmptyState(subTextColor)
                      : RefreshIndicator(
                    color: SC.cyan,
                    backgroundColor: isDark ? SC.cardBg : Colors.white,
                    onRefresh: _loadNotifs,
                    child: FadeTransition(
                      opacity: _fadeCtrl,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        itemCount: _notifs.length,
                        itemBuilder: (ctx, i) => _buildCardByType(
                          _notifs[i], isDark,
                        ),
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

  Widget _buildCardByType(_Notif n, bool isDark) {
    final card = switch (n.type) {
      'blood_request'      => _BloodRequestCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onTap: _onNotifTap, onDelete: _deleteNotifDirect),
      'event_notification' => _EventCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onTap: _onNotifTap, onDelete: _deleteNotifDirect),
      'notice'             => _NoticeCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onTap: _onNotifTap, onDelete: _deleteNotifDirect),
      'complaint'          => _ComplaintCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onTap: _onNotifTap, onDelete: _deleteNotifDirect),
      'complaint_reply'    => _ComplaintReplyCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onTap: _onNotifTap, onDelete: _deleteNotifDirect),
      'new_post'           => _NewPostCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onTap: _onNotifTap, onDelete: _deleteNotifDirect),
      'login_success'      => _LoginSuccessCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onDelete: _deleteNotifDirect),
      'login_failed'       => _LoginFailedCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onDelete: _deleteNotifDirect),
      'logout'             => _LogoutCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onDelete: _deleteNotifDirect),
      'profile_update'     => _ProfileUpdateCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onDelete: _deleteNotifDirect),
      'password_change'    => _PasswordChangeCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onDelete: _deleteNotifDirect),
      'email_change_req'   => _EmailChangeCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onDelete: _deleteNotifDirect),
      _                    => _GeneralCard(n: n, isDark: isDark, tr: _tr, fmt: _formatTime, onDelete: _deleteNotifDirect),
    };

    // Swipe to delete still works as a secondary gesture
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (_) async {
        setState(() => _notifs.removeWhere((x) => x.id == n.id));
        try {
          await _db.from('notifications').delete().eq('id', n.id);
        } catch (e) {
          debugPrint('🗑️ Swipe delete error: $e');
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: SC.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SC.red.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.delete_rounded, color: SC.red, size: 26),
          const SizedBox(height: 4),
          Text(_tr('delete_notif'),
              style: TextStyle(color: SC.red, fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
      child: card,
    );
  }

  Widget _buildAppBar(Color textColor) {
    final unreadCount = _notifs.where((n) => !n.isRead).length;
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10, bottom: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tr('notifications'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: SC.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_notifs.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded,
                  color: SC.red.withValues(alpha: 0.8), size: 24),
              tooltip: _tr('delete_all'),
              onPressed: _deleteAll,
            )
          else
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor, size: 22),
              onPressed: _loading ? null : _loadNotifs,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color subTextColor) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.notifications_off_rounded,
            size: 56, color: subTextColor.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(_tr('notif_empty'),
            style: TextStyle(color: subTextColor, fontSize: 15)),
      ]),
    );
  }

  Widget _buildErrorState(Color subTextColor) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_rounded,
            size: 56, color: SC.red.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text(_tr('notif_error'),
            style: TextStyle(color: subTextColor, fontSize: 15)),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _loadNotifs,
          icon: Icon(Icons.refresh_rounded, color: SC.cyan),
          label: Text(_tr('retry'), style: TextStyle(color: SC.cyan)),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SMALL DELETE BUTTON — used on every card
// ══════════════════════════════════════════════════════════════════
class _DeleteBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _DeleteBtn({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: SC.red.withValues(alpha: isDark ? 0.15 : 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: SC.red.withValues(alpha: 0.25), width: 1),
        ),
        child: Icon(Icons.close_rounded, color: SC.red, size: 14),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SHARED BASE CARD HELPER
// ══════════════════════════════════════════════════════════════════
class _BaseCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final Color topColor;
  final Color bottomColor;
  final Widget child;
  final VoidCallback? onTap;

  const _BaseCard({
    required this.n,
    required this.isDark,
    required this.topColor,
    required this.bottomColor,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: n.isRead ? 0.03 : 0.05)
              : Colors.white.withValues(alpha: n.isRead ? 0.9 : 1.0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: n.isRead
                ? (isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07))
                : topColor.withValues(alpha: 0.45),
            width: n.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: n.isRead
                  ? Colors.black.withValues(alpha: isDark ? 0.2 : 0.05)
                  : topColor.withValues(alpha: 0.15),
              blurRadius: n.isRead ? 8 : 16,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(children: [
            if (!n.isRead)
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [topColor, bottomColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            child,
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// SENDER NAME CHIP
// ══════════════════════════════════════════════════════════════════
class _SenderChip extends StatelessWidget {
  final String? senderName;
  final Color color;

  const _SenderChip({required this.senderName, required this.color});

  @override
  Widget build(BuildContext context) {
    if (senderName == null || senderName!.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_outline_rounded, size: 11, color: color),
        const SizedBox(width: 4),
        Text(senderName!,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 1. 🩸 BLOOD REQUEST CARD
// ══════════════════════════════════════════════════════════════════
class _BloodRequestCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onTap;
  final Future<void> Function(_Notif) onDelete;

  const _BloodRequestCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onTap, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const red  = Color(0xFFFF2244);
    const pink = Color(0xFFFF6B8A);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: red, bottomColor: pink,
      onTap: () => onTap(n),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [red, pink],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: red.withValues(alpha: 0.4),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.bloodtype_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: red.withValues(alpha: 0.4)),
                    ),
                    child: const Text('URGENT',
                        style: TextStyle(color: red, fontSize: 9,
                            fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                  const Spacer(),
                  if (!n.isRead)
                    Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(color: red, shape: BoxShape.circle)),
                  _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
                ]),
                const SizedBox(height: 4),
                Text(tr(n.titleKey),
                    style: TextStyle(color: textColor, fontSize: 14,
                        fontWeight: FontWeight.w800)),
                _SenderChip(senderName: n.senderName, color: red),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: red.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: red.withValues(alpha: 0.15)),
            ),
            child: Text(tr(n.bodyKey),
                style: TextStyle(color: subColor, fontSize: 13, height: 1.4)),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.access_time_rounded, size: 12, color: subColor.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(fmt(n.time), style: TextStyle(color: subColor.withValues(alpha: 0.5), fontSize: 11)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [red, pink]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(tr('tapToView'), style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 2. 📅 EVENT CARD
// ══════════════════════════════════════════════════════════════════
class _EventCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onTap;
  final Future<void> Function(_Notif) onDelete;

  const _EventCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onTap, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF8B5CF6);
    const indigo = Color(0xFF6366F1);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: violet, bottomColor: indigo,
      onTap: () => onTap(n),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [violet, indigo],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: violet.withValues(alpha: 0.35),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.event_rounded, color: Colors.white, size: 22),
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 20, height: 1.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(tr(n.titleKey),
                      style: TextStyle(color: textColor, fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
                if (!n.isRead)
                  Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(color: violet, shape: BoxShape.circle)),
                _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
              ]),
              _SenderChip(senderName: n.senderName, color: violet),
              const SizedBox(height: 5),
              Text(tr(n.bodyKey),
                  style: TextStyle(color: subColor, fontSize: 13, height: 1.4)),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: violet.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: violet.withValues(alpha: 0.3)),
                  ),
                  child: Text(tr('tapToView'),
                      style: TextStyle(color: violet, fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Icon(Icons.access_time_rounded, size: 11, color: subColor.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(fmt(n.time), style: TextStyle(
                    color: subColor.withValues(alpha: 0.5), fontSize: 11)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 3. 📢 NOTICE CARD
// ══════════════════════════════════════════════════════════════════
class _NoticeCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onTap;
  final Future<void> Function(_Notif) onDelete;

  const _NoticeCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onTap, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF06B6D4);
    const teal = Color(0xFF14B8A6);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: cyan, bottomColor: teal,
      onTap: () => onTap(n),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [cyan.withValues(alpha: 0.15), teal.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cyan.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.campaign_rounded, color: cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr(n.titleKey),
                      style: TextStyle(color: textColor, fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  _SenderChip(senderName: n.senderName, color: cyan),
                ]),
              ),
              if (!n.isRead)
                Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(color: cyan, shape: BoxShape.circle)),
              _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
            ]),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(tr(n.bodyKey),
                style: TextStyle(color: subColor, fontSize: 13, height: 1.4)),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.access_time_rounded, size: 11, color: subColor.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(fmt(n.time), style: TextStyle(
                color: subColor.withValues(alpha: 0.5), fontSize: 11)),
            const Spacer(),
            GestureDetector(
              onTap: () => onTap(n),
              child: Row(children: [
                Text(tr('tapToView'),
                    style: const TextStyle(color: cyan, fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_ios_rounded, color: cyan, size: 11),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 4. 📋 COMPLAINT CARD
// ══════════════════════════════════════════════════════════════════
class _ComplaintCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onTap;
  final Future<void> Function(_Notif) onDelete;

  const _ComplaintCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onTap, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF97316);
    const amber  = Color(0xFFF59E0B);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: orange, bottomColor: amber,
      onTap: () => onTap(n),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: orange.withValues(alpha: 0.35), width: 1.5),
            ),
            child: const Icon(Icons.report_outlined, color: orange, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(tr(n.titleKey),
                      style: TextStyle(color: textColor, fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
                if (!n.isRead)
                  Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(color: orange, shape: BoxShape.circle)),
                _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
              ]),
              _SenderChip(senderName: n.senderName, color: orange),
              const SizedBox(height: 4),
              Text(tr(n.bodyKey),
                  style: TextStyle(color: subColor, fontSize: 12.5, height: 1.4)),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: orange.withValues(alpha: 0.3)),
                  ),
                  child: Text(tr('tapToView'),
                      style: TextStyle(color: orange, fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text(fmt(n.time), style: TextStyle(
                    color: subColor.withValues(alpha: 0.5), fontSize: 11)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 5. 💬 COMPLAINT REPLY CARD
// ══════════════════════════════════════════════════════════════════
class _ComplaintReplyCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onTap;
  final Future<void> Function(_Notif) onDelete;

  const _ComplaintReplyCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onTap, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const green   = Color(0xFF10B981);
    const emerald = Color(0xFF34D399);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: green, bottomColor: emerald,
      onTap: () => onTap(n),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [green, emerald],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: green.withValues(alpha: 0.3),
                    blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.reply_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr(n.titleKey),
                    style: TextStyle(color: textColor, fontSize: 14,
                        fontWeight: FontWeight.w800)),
                _SenderChip(senderName: n.senderName, color: green),
              ]),
            ),
            if (!n.isRead)
              Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(color: green, shape: BoxShape.circle)),
            _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: green.withValues(alpha: isDark ? 0.08 : 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: green.withValues(alpha: 0.2)),
            ),
            child: Text(tr(n.bodyKey),
                style: TextStyle(color: subColor, fontSize: 13, height: 1.4)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text(fmt(n.time), style: TextStyle(
                color: subColor.withValues(alpha: 0.5), fontSize: 11)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: green.withValues(alpha: 0.3)),
              ),
              child: Text(tr('tapToView'),
                  style: TextStyle(color: green, fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 6. 📝 NEW POST CARD
// ══════════════════════════════════════════════════════════════════
class _NewPostCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onTap;
  final Future<void> Function(_Notif) onDelete;

  const _NewPostCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onTap, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const sky  = Color(0xFF38BDF8);
    const cyan = Color(0xFF06B6D4);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: sky, bottomColor: cyan,
      onTap: () => onTap(n),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: sky.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sky.withValues(alpha: 0.3)),
            ),
            child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.article_rounded, color: sky, size: 26),
              if (!n.isRead)
                Positioned(
                  top: 8, right: 8,
                  child: Container(width: 7, height: 7,
                      decoration: const BoxDecoration(color: sky, shape: BoxShape.circle)),
                ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(tr(n.titleKey),
                      style: TextStyle(color: textColor, fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
                _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
              ]),
              _SenderChip(senderName: n.senderName, color: sky),
              const SizedBox(height: 4),
              Text(tr(n.bodyKey),
                  style: TextStyle(color: subColor, fontSize: 12.5, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                Text(fmt(n.time), style: TextStyle(
                    color: subColor.withValues(alpha: 0.5), fontSize: 11)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [sky, cyan]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tr('tapToView'),
                      style: const TextStyle(color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 7. ✅ LOGIN SUCCESS CARD
// ══════════════════════════════════════════════════════════════════
class _LoginSuccessCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onDelete;

  const _LoginSuccessCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const green   = Color(0xFF10B981);
    const emerald = Color(0xFF34D399);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: green, bottomColor: emerald,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: green.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.login_rounded, color: green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(n.titleKey),
                  style: TextStyle(color: textColor, fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(tr(n.bodyKey),
                  style: TextStyle(color: subColor, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
                const SizedBox(height: 6),
                if (!n.isRead)
                  Container(width: 7, height: 7, margin: const EdgeInsets.only(bottom: 4),
                      decoration: const BoxDecoration(color: green, shape: BoxShape.circle)),
                Text(fmt(n.time), style: TextStyle(
                    color: subColor.withValues(alpha: 0.6), fontSize: 10)),
              ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 8. ⚠️ LOGIN FAILED CARD
// ══════════════════════════════════════════════════════════════════
class _LoginFailedCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onDelete;

  const _LoginFailedCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const red  = Color(0xFFEF4444);
    const rose = Color(0xFFF87171);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: red, bottomColor: rose,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: red.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr(n.titleKey),
                    style: TextStyle(color: textColor, fontSize: 13.5,
                        fontWeight: FontWeight.w800)),
              ),
              if (!n.isRead)
                Container(width: 7, height: 7, margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(color: red, shape: BoxShape.circle)),
              _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(tr(n.bodyKey),
                style: TextStyle(color: subColor, fontSize: 12.5)),
          ),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight,
              child: Text(fmt(n.time), style: TextStyle(
                  color: subColor.withValues(alpha: 0.5), fontSize: 10))),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 9. 🚪 LOGOUT CARD
// ══════════════════════════════════════════════════════════════════
class _LogoutCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onDelete;

  const _LogoutCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF97316);
    const amber  = Color(0xFFFBBF24);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: orange, bottomColor: amber,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: orange.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.logout_rounded, color: orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(n.titleKey),
                  style: TextStyle(color: textColor, fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(tr(n.bodyKey), style: TextStyle(color: subColor, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
                const SizedBox(height: 6),
                Text(fmt(n.time), style: TextStyle(
                    color: subColor.withValues(alpha: 0.6), fontSize: 10)),
              ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 10. ✏️ PROFILE UPDATE CARD
// ══════════════════════════════════════════════════════════════════
class _ProfileUpdateCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onDelete;

  const _ProfileUpdateCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF06B6D4);
    const sky  = Color(0xFF38BDF8);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: cyan, bottomColor: sky,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [cyan.withValues(alpha: 0.2), sky.withValues(alpha: 0.1)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cyan.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.edit_rounded, color: cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(n.titleKey),
                  style: TextStyle(color: textColor, fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(tr(n.bodyKey), style: TextStyle(color: subColor, fontSize: 12)),
              const SizedBox(height: 4),
              Text(fmt(n.time), style: TextStyle(
                  color: subColor.withValues(alpha: 0.5), fontSize: 10)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
                const SizedBox(height: 6),
                if (!n.isRead)
                  Container(width: 7, height: 7,
                      decoration: const BoxDecoration(color: cyan, shape: BoxShape.circle)),
              ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 11. 🔒 PASSWORD CHANGE CARD
// ══════════════════════════════════════════════════════════════════
class _PasswordChangeCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onDelete;

  const _PasswordChangeCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const blue   = Color(0xFF3B82F6);
    const indigo = Color(0xFF6366F1);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: blue, bottomColor: indigo,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [blue, indigo],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(color: blue.withValues(alpha: 0.3),
                  blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(n.titleKey),
                  style: TextStyle(color: textColor, fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(tr(n.bodyKey), style: TextStyle(color: subColor, fontSize: 12)),
              const SizedBox(height: 5),
              Text(fmt(n.time), style: TextStyle(
                  color: subColor.withValues(alpha: 0.5), fontSize: 10)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
                const SizedBox(height: 6),
                if (!n.isRead)
                  Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: blue, shape: BoxShape.circle)),
              ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 12. ✉️ EMAIL CHANGE CARD
// ══════════════════════════════════════════════════════════════════
class _EmailChangeCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onDelete;

  const _EmailChangeCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFFA855F7);
    const violet = Color(0xFF8B5CF6);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: purple, bottomColor: violet,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Stack(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: purple.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.email_rounded, color: purple, size: 22),
            ),
            if (!n.isRead)
              Positioned(
                right: 0, top: 0,
                child: Container(width: 9, height: 9,
                    decoration: BoxDecoration(
                      color: purple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    )),
              ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(n.titleKey),
                  style: TextStyle(color: textColor, fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(tr(n.bodyKey), style: TextStyle(color: subColor, fontSize: 12)),
              const SizedBox(height: 4),
              Text(fmt(n.time), style: TextStyle(
                  color: subColor.withValues(alpha: 0.5), fontSize: 10)),
            ]),
          ),
          _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 13. 🔔 GENERAL CARD
// ══════════════════════════════════════════════════════════════════
class _GeneralCard extends StatelessWidget {
  final _Notif n;
  final bool isDark;
  final String Function(String) tr;
  final String Function(DateTime) fmt;
  final Future<void> Function(_Notif) onDelete;

  const _GeneralCard({
    required this.n, required this.isDark,
    required this.tr, required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF06B6D4);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF4A5568);

    return _BaseCard(
      n: n, isDark: isDark,
      topColor: cyan, bottomColor: cyan,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: cyan.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: cyan.withValues(alpha: 0.25)),
            ),
            child: Icon(n.icon, color: cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(n.titleKey),
                  style: TextStyle(color: textColor, fontSize: 13.5,
                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700)),
              const SizedBox(height: 2),
              Text(tr(n.bodyKey), style: TextStyle(color: subColor, fontSize: 12)),
              _SenderChip(senderName: n.senderName, color: cyan),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DeleteBtn(isDark: isDark, onTap: () => onDelete(n)),
                const SizedBox(height: 6),
                if (!n.isRead)
                  Container(width: 7, height: 7, margin: const EdgeInsets.only(bottom: 4),
                      decoration: const BoxDecoration(color: cyan, shape: BoxShape.circle)),
                Text(fmt(n.time), style: TextStyle(
                    color: subColor.withValues(alpha: 0.5), fontSize: 10)),
              ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// MODEL
// ══════════════════════════════════════════════════════════════════
class _Notif {
  final String   id;
  final String   titleKey;
  final String   bodyKey;
  final String   type;
  final bool     isRead;
  final DateTime time;
  final Color    color;
  final IconData icon;
  final String?  requestId;
  final String?  eventId;
  final String?  noticeId;
  final String?  complaintId;
  final String?  postId;
  final String?  senderName;

  const _Notif({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    required this.type,
    required this.isRead,
    required this.time,
    required this.color,
    required this.icon,
    this.requestId,
    this.eventId,
    this.noticeId,
    this.complaintId,
    this.postId,
    this.senderName,
  });

  _Notif copyWith({bool? isRead}) => _Notif(
    id:          id,
    titleKey:    titleKey,
    bodyKey:     bodyKey,
    type:        type,
    isRead:      isRead ?? this.isRead,
    time:        time,
    color:       color,
    icon:        icon,
    requestId:   requestId,
    eventId:     eventId,
    noticeId:    noticeId,
    complaintId: complaintId,
    postId:      postId,
    senderName:  senderName,
  );
}