import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/pages/SettingsPage/notification_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {

  // ── Typewriter ──
  List<String> get _titles => [
    SC.tr('cssTitle1'),
    SC.tr('cssTitle2'),
    SC.tr('cssTitle3'),
  ];

  int _currentIndex = 0;
  String _displayedText = '';
  bool _isDeleting = false;
  bool _cursorVisible = true;
  Timer? _typeTimer;
  Timer? _cursorTimer;

  // ── Notification ──
  int _unreadCount = 0;
  RealtimeChannel? _notifChannel;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
    _startCursorBlink();
    SC.languageNotifier.addListener(_onLanguageChanged);

    // Notification
    _loadUnreadCount();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    SC.languageNotifier.removeListener(_onLanguageChanged);
    _notifChannel?.unsubscribe();
    super.dispose();
  }

  // ── Typewriter methods ──
  void _onLanguageChanged() {
    _typeTimer?.cancel();
    if (mounted) {
      setState(() {
        _displayedText = '';
        _isDeleting = false;
        _currentIndex = 0;
      });
    }
    Future.delayed(const Duration(milliseconds: 300), _startTypewriter);
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });
  }

  void _startTypewriter() {
    _typeTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        final currentTitle = _titles[_currentIndex];
        if (!_isDeleting) {
          if (_displayedText.length < currentTitle.length) {
            _displayedText =
                currentTitle.substring(0, _displayedText.length + 1);
          } else {
            timer.cancel();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _isDeleting = true;
                _startTypewriter();
              }
            });
          }
        } else {
          if (_displayedText.isNotEmpty) {
            _displayedText =
                _displayedText.substring(0, _displayedText.length - 1);
          } else {
            _isDeleting = false;
            _currentIndex = (_currentIndex + 1) % _titles.length;
            timer.cancel();
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) _startTypewriter();
            });
          }
        }
      });
    });
  }

  // ── Notification methods ──
  Future<void> _loadUnreadCount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      debugPrint('🔔 Unread count: ${(response as List).length}');

      if (mounted) {
        setState(() => _unreadCount = (response as List).length);
      }
    } catch (e) {
      debugPrint('🔔 Count error: $e');
    }
  }
  void _subscribeRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _notifChannel = Supabase.instance.client
        .channel('notif_appbar_$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (_) => _loadUnreadCount(),
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (_) => _loadUnreadCount(),
    )
        .subscribe();
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildAppBar(),
      ),
    );
  }

  Widget _buildAppBar() {
    final isDark = SC.isDark;
    final bgColor = isDark ? const Color(0xFF132D46) : Colors.white;
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final iconBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final iconColor = isDark ? Colors.cyanAccent : SC.blue;
    final cursorColor = isDark ? Colors.cyanAccent : SC.blue;
    final gradientColors = isDark
        ? [Colors.white, Colors.cyanAccent]
        : [const Color(0xFF1A2332), SC.blue];
    final badgeBorder = isDark
        ? const Color(0xFF132D46)
        : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,

        // ── Drawer (Left) button ──
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: iconBorder),
              ),
              child: Icon(Icons.menu_rounded, color: iconColor, size: 22),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
          ),
        ),

        // ── Typewriter title ──
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: gradientColors,
                ).createShader(bounds),
                child: Text(
                  _displayedText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            // Blinking cursor
            AnimatedOpacity(
              opacity: _cursorVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 2,
                height: 18,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: cursorColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),

        // ── Notification bell (Right) ──
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: iconBorder),
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationPage(),
                      ),
                    );
                    // Page থেকে ফিরলে count refresh
                    _loadUnreadCount();
                  },
                ),

                // ── Badge ──
                if (_unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IgnorePointer(
                      child: AnimatedScale(
                        scale: _unreadCount > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: SC.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: badgeBorder,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            _unreadCount > 99 ? '99+' : '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}