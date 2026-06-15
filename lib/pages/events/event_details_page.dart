import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:css/pages/events/event_register_page.dart';
import 'package:css/pages/events/event_registrations_page.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class EventDetailsPage extends StatefulWidget {
  final int eventId;
  const EventDetailsPage({super.key, required this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? event;
  List<Map<String, dynamic>> gallery = [];
  bool loading = true;
  String? error;
  String? userRole;
  Timer? _timer;
  Duration? remaining;

  Map<String, dynamic>? userRegistration;
  bool checkingRegistration = true;

  final MapController _mapController = MapController();
  LatLng? _eventLocation;
  List<Marker> _markers = [];

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─── Theme ────────────────────────────────────────────────────────────────
  bool get _isDark => SC.isDark;
  Color get _bg => _isDark ? const Color(0xFF060D1F) : const Color(0xFFF0F4FF);
  Color get _card =>
      _isDark ? const Color(0xFF0D1528) : Colors.white;
  Color get _textPrimary =>
      _isDark ? Colors.white : const Color(0xFF1A2332);
  Color get _textSub =>
      _isDark ? const Color(0xFFB0BEC5) : const Color(0xFF4A5568);
  Color get _border =>
      (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);

  static const _cyan   = Color(0xFF00E5FF);
  static const _purple = Color(0xFF7C4DFF);
  static const _amber  = Color(0xFFFFAB40);
  static const _green  = Color(0xFF00C853);
  static const _red    = Color(0xFFEF5350);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: _entryCtrl, curve: Curves.easeOutCubic));

    loadEvent();
    _checkUserRole();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ─── Data loaders ─────────────────────────────────────────────────────────
  Future<void> _checkUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final data = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    if (mounted) {
      setState(
              () => userRole = data?['role']?.toString().toLowerCase());
    }
  }

  Future<void> _checkUserRegistration() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => checkingRegistration = false);
      return;
    }
    try {
      final data = await supabase
          .from('event_registrations')
          .select()
          .eq('event_id', widget.eventId)
          .eq('user_id', user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          userRegistration =
          data != null ? Map<String, dynamic>.from(data) : null;
          checkingRegistration = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => checkingRegistration = false);
    }
  }

  Future<void> loadEvent() async {
    try {
      final e = await supabase
          .from('events')
          .select()
          .eq('id', widget.eventId)
          .maybeSingle();
      if (e == null) {
        setState(() {
          error = SC.tr('eventNotFound');
          loading = false;
        });
        return;
      }
      final imgs = await supabase
          .from('event_images')
          .select()
          .eq('event_id', widget.eventId);

      event = Map<String, dynamic>.from(e);
      gallery = List<Map<String, dynamic>>.from(imgs);

      _setupMapLocation();
      _setupCountdown();
      await _checkUserRegistration();
      _entryCtrl.forward();
    } catch (_) {
      error = SC.tr('failedLoadEvent');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _setupMapLocation() {
    final lat = event!['latitude'];
    final lng = event!['longitude'];
    if (lat != null && lng != null) {
      _eventLocation = LatLng(lat.toDouble(), lng.toDouble());
      _markers = [
        Marker(
          point: _eventLocation!,
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cyan.withValues(alpha: 0.2),
              border: Border.all(color: _cyan, width: 2),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: _cyan, size: 26),
          ),
        ),
      ];
    }
  }

  void _setupCountdown() {
    final start =
    DateTime.parse(event!['start_datetime']).toLocal();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = start.difference(DateTime.now());
      if (!mounted) return;
      setState(
              () => remaining = diff.isNegative ? Duration.zero : diff);
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _formatDate(String dt) {
    final d = DateTime.parse(dt).toLocal();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${months[d.month - 1]} ${d.year} • $h:$m $ap';
  }

  String _countdownText(Duration d) {
    if (d == Duration.zero) return SC.tr('eventStarted');
    return '${d.inDays}d  ${d.inHours % 24}h  '
        '${d.inMinutes % 60}m  ${d.inSeconds % 60}s';
  }

  Future<void> _openMap() async {
    final lat = event!['latitude'];
    final lng = event!['longitude'];
    if (lat == null || lng == null) return;
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  _PaymentInfo _paymentInfo(String? status) {
    switch (status) {
      case 'verified':
        return _PaymentInfo(
          label: SC.tr('paymentVerified'),
          sublabel: SC.tr('regConfirmedMsg'),
          icon: Icons.verified_rounded,
          color: _green,
          bg: _green.withValues(alpha: 0.08),
          border: _green.withValues(alpha: 0.3),
        );
      case 'rejected':
        return _PaymentInfo(
          label: SC.tr('paymentRejectedMsg'),
          sublabel: SC.tr('contactAdmin'),
          icon: Icons.cancel_rounded,
          color: _red,
          bg: _red.withValues(alpha: 0.08),
          border: _red.withValues(alpha: 0.3),
        );
      default:
        return _PaymentInfo(
          label: SC.tr('paymentPending'),
          sublabel: SC.tr('pendingVerification'),
          icon: Icons.hourglass_top_rounded,
          color: _amber,
          bg: _amber.withValues(alpha: 0.08),
          border: _amber.withValues(alpha: 0.3),
        );
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (_, __, ___) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (_, __, ___) => _scaffold(),
      ),
    );
  }

  Widget _scaffold() {
    if (loading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: _isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: _bg,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cyan.withValues(alpha: 0.1),
                    border: Border.all(
                        color: _cyan.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.event_rounded,
                      color: _cyan, size: 28),
                ),
                const SizedBox(height: 16),
                Text(SC.tr('loading'),
                    style: TextStyle(
                        color: _textSub.withValues(alpha: 0.6),
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    if (error != null || event == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: _isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: _bg,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _red.withValues(alpha: 0.1),
                    border: Border.all(
                        color: _red.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.event_busy_rounded,
                      color: _red, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  error ?? SC.tr('eventNotFound'),
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Text(SC.tr('goBack'),
                        style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
      _isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: _bg,
        body: Stack(children: [
          // Page bg gradient
          Container(
            decoration: BoxDecoration(
              gradient: _isDark
                  ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF060D1F), Color(0xFF0A0F1E)],
              )
                  : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0F4FF),
                  Color(0xFFE8EFFF),
                  Color(0xFFEFF6FF),
                ],
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _heroBanner(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoCard(),
                          if (!checkingRegistration &&
                              userRegistration != null) ...[
                            const SizedBox(height: 4),
                            _registrationCard(),
                          ],
                          if (userRole == 'admin') ...[
                            const SizedBox(height: 4),
                            _adminTile(),
                          ],
                          const SizedBox(height: 20),
                          _sectionLabel(SC.tr('aboutEvent')),
                          const SizedBox(height: 10),
                          Text(
                            event!['full_description'] ??
                                SC.tr('noDescription'),
                            style: TextStyle(
                              color: _textSub,
                              fontSize: 14,
                              height: 1.7,
                            ),
                          ),
                          if (_eventLocation != null) ...[
                            const SizedBox(height: 24),
                            _sectionLabel(SC.tr('mapLocation')),
                            const SizedBox(height: 10),
                            _mapSection(),
                            const SizedBox(height: 10),
                            _mapsButton(),
                          ],
                          if (gallery.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _sectionLabel(SC.tr('gallery')),
                            const SizedBox(height: 10),
                            _galleryRow(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky bottom CTA
          _bottomCta(),
        ]),
      ),
    );
  }

  // ─── HERO SLIVER ──────────────────────────────────────────────────────────
  SliverAppBar _heroBanner() {
    final banner = event!['banner_url'];
    final price = (event!['price'] ?? 0).toDouble();
    final isFree = price == 0;

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: _bg,
      elevation: 0,
      systemOverlayStyle:
      SystemUiOverlayStyle.light,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 14),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(children: [
          // Banner image / placeholder
          Hero(
            tag: 'event_${widget.eventId}',
            child: Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: _isDark
                    ? const Color(0xFF0F1A30)
                    : const Color(0xFFDDE8FF),
                image: banner != null
                    ? DecorationImage(
                  image: NetworkImage(banner),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: banner == null
                  ? Center(
                child: Icon(Icons.event_rounded,
                    size: 80,
                    color: _isDark
                        ? Colors.white12
                        : Colors.black12),
              )
                  : null,
            ),
          ),

          // Gradient overlay
          Container(
            height: 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.transparent,
                  (_isDark
                      ? const Color(0xFF060D1F)
                      : const Color(0xFFF0F4FF))
                      .withValues(alpha: 0.97),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Title + price badge at bottom
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isFree
                        ? _green.withValues(alpha: 0.15)
                        : _amber.withValues(alpha: 0.15),
                    border: Border.all(
                      color: isFree
                          ? _green.withValues(alpha: 0.4)
                          : _amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFree
                            ? Icons.celebration_rounded
                            : Icons.payments_rounded,
                        size: 11,
                        color: isFree ? _green : _amber,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isFree
                            ? SC.tr('freeEntry').toUpperCase()
                            : '৳ ${price.toInt()}',
                        style: TextStyle(
                          color: isFree ? _green : _amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Event title
                Text(
                  event!['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                          color: Colors.black54,
                          blurRadius: 12,
                          offset: Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ─── INFO CARD (date, venue, countdown) ──────────────────────────────────
  Widget _infoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _card,
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        _infoRow(
          icon: Icons.calendar_month_rounded,
          iconColor: _cyan,
          label: SC.tr('dateTime'),
          value: _formatDate(event!['start_datetime']),
          isFirst: true,
        ),
        _divider(),
        _infoRow(
          icon: Icons.location_on_rounded,
          iconColor: _purple,
          label: SC.tr('venue'),
          value: event!['venue'] ?? SC.tr('tbd'),
        ),
        if (remaining != null) ...[
          _divider(),
          _infoRow(
            icon: Icons.timer_outlined,
            iconColor: _amber,
            label: SC.tr('countdown'),
            value: _countdownText(remaining!),
            valueColor: _amber,
          ),
        ],
      ]),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool isFirst = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: iconColor.withValues(alpha: 0.1),
            border: Border.all(
                color: iconColor.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _textSub.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _divider() =>
      Divider(color: _border, height: 1, thickness: 0.5,
          indent: 16, endIndent: 16);

  // ─── REGISTRATION STATUS CARD ─────────────────────────────────────────────
  Widget _registrationCard() {
    final paymentStatus =
    userRegistration!['payment_status'] as String?;
    final isFree = (event!['price'] ?? 0) == 0;
    final info = _paymentInfo(paymentStatus);

    final txId = userRegistration!['transaction_id'];
    final payNum = userRegistration!['payment_number'];
    final screenshotUrl =
    userRegistration!['payment_screenshot_url'];

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: info.bg,
        border: Border.all(color: info.border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: info.color.withValues(alpha: 0.15),
                      border: Border.all(
                          color: info.color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(info.icon,
                        color: info.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: _cyan.withValues(alpha: 0.1),
                            border: Border.all(
                                color: _cyan.withValues(alpha: 0.28)),
                          ),
                          child: Text(
                            SC.tr('registered').toUpperCase(),
                            style: const TextStyle(
                              color: _cyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          info.label,
                          style: TextStyle(
                            color: info.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          info.sublabel,
                          style: TextStyle(
                            color: info.color.withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),

                if (isFree) ...[
                  _regDivider(),
                  Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: _green, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      SC.tr('regSuccessMsg'),
                      style: TextStyle(
                          color: _textPrimary.withValues(alpha: 0.8),
                          fontSize: 13),
                    ),
                  ]),
                ],

                if (!isFree) ...[
                  _regDivider(),
                  if (payNum != null)
                    _detailRow(Icons.phone_android_rounded,
                        SC.tr('paymentNumber'), payNum.toString()),
                  if (txId != null)
                    _detailRow(Icons.receipt_long_rounded,
                        SC.tr('transactionId'), txId.toString()),
                  if (screenshotUrl != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () =>
                          _showScreenshot(screenshotUrl.toString()),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: 0.1)),
                        ),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              screenshotUrl.toString(),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.white10,
                                    child: const Icon(
                                        Icons.broken_image_rounded,
                                        color: Colors.white30),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  SC.tr('payScreenshot'),
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  SC.tr('tapToView'),
                                  style: TextStyle(
                                    color: _textSub
                                        .withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.open_in_full_rounded,
                              color: _cyan.withValues(alpha: 0.6),
                              size: 17),
                        ]),
                      ),
                    ),
                  ],
                  _regDivider(),
                  _statusMessage(paymentStatus),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _regDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ]),
      ),
    ),
  );

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon,
            color: _textSub.withValues(alpha: 0.4), size: 15),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            color: _textSub.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _statusMessage(String? status) {
    IconData icon;
    Color color;
    String text;
    switch (status) {
      case 'verified':
        icon = Icons.celebration_rounded;
        color = _green;
        text = SC.tr('verifiedWelcome');
        break;
      case 'rejected':
        icon = Icons.info_outline_rounded;
        color = _red;
        text = SC.tr('rejectedMsg');
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = _amber;
        text = SC.tr('pendingMsg');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _textPrimary.withValues(alpha: 0.8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ]),
    );
  }

  // ─── ADMIN TILE ───────────────────────────────────────────────────────────
  Widget _adminTile() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventRegistrationsPage(
            eventId: widget.eventId,
            eventTitle: event!['title'] ?? 'Event',
            bannerUrl: event!['banner_url'],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _purple.withValues(alpha: 0.08),
          border: Border.all(color: _purple.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _purple.withValues(alpha: 0.15),
                border: Border.all(
                    color: _purple.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: _purple, size: 15),
            ),
            const SizedBox(width: 10),
            Text(
              SC.tr('viewRegistrations').toUpperCase(),
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: _purple.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }

  // ─── SECTION LABEL ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(children: [
      Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: _cyan,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _cyan,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    ]);
  }

  // ─── MAP ──────────────────────────────────────────────────────────────────
  Widget _mapSection() {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _eventLocation!,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
                flags:
                InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.css',
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
      ),
    );
  }

  Widget _mapsButton() {
    return GestureDetector(
      onTap: _openMap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: (_isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.04),
          border: Border.all(color: _border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.map_outlined,
              color: _textSub.withValues(alpha: 0.55), size: 17),
          const SizedBox(width: 8),
          Text(
            SC.tr('openGoogleMaps').toUpperCase(),
            style: TextStyle(
              color: _textSub,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ]),
      ),
    );
  }

  // ─── GALLERY ──────────────────────────────────────────────────────────────
  Widget _galleryRow() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: gallery.length,
        itemBuilder: (_, i) => Container(
          margin: EdgeInsets.only(right: i < gallery.length - 1 ? 12 : 0),
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            image: DecorationImage(
              image: NetworkImage(gallery[i]['image_url']),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // ─── SCREENSHOT DIALOG ────────────────────────────────────────────────────
  void _showScreenshot(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  SC.tr('close').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM CTA ───────────────────────────────────────────────────────────
  Widget _bottomCta() {
    final isClosed = remaining == Duration.zero;
    final registered = userRegistration != null;
    final payStatus =
    userRegistration?['payment_status'] as String?;
    final isVerified = payStatus == 'verified';
    final isPending = payStatus == 'pending';
    final isRejected = payStatus == 'rejected';
    final isFree = (event!['price'] ?? 0) == 0;

    Color btnBg;
    Color btnFg;
    String btnText;
    IconData btnIcon;
    VoidCallback? onTap;
    bool outlined = false;

    if (registered) {
      if (isFree || isVerified) {
        btnBg = _green;
        btnFg = const Color(0xFF003012);
        btnText = SC.tr('regConfirmed').toUpperCase();
        btnIcon = Icons.check_circle_rounded;
        onTap = null;
        outlined = true;
      } else if (isPending) {
        btnBg = _amber;
        btnFg = const Color(0xFF2A1A00);
        btnText = SC.tr('paymentPending').toUpperCase();
        btnIcon = Icons.hourglass_top_rounded;
        onTap = null;
        outlined = true;
      } else if (isRejected) {
        btnBg = _red;
        btnFg = Colors.white;
        btnText = SC.tr('paymentRejected').toUpperCase();
        btnIcon = Icons.cancel_rounded;
        onTap = null;
        outlined = true;
      } else {
        btnBg = _textSub.withValues(alpha: 0.25);
        btnFg = _textSub;
        btnText = SC.tr('alreadyRegistered').toUpperCase();
        btnIcon = Icons.how_to_reg_rounded;
        onTap = null;
      }
    } else if (isClosed) {
      btnBg = _textSub.withValues(alpha: 0.2);
      btnFg = _textSub.withValues(alpha: 0.5);
      btnText = SC.tr('registrationClosed').toUpperCase();
      btnIcon = Icons.lock_outline_rounded;
      onTap = null;
    } else {
      btnBg = _cyan;
      btnFg = const Color(0xFF001A26);
      btnText = SC.tr('registerNow').toUpperCase();
      btnIcon = Icons.app_registration_rounded;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventRegisterPage(
            eventId: event!['id'],
            price: (event!['price'] ?? 0).toDouble(),
          ),
        ),
      ).then((_) => _checkUserRegistration());
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            16, 20, 16, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _bg.withValues(alpha: 0),
              _bg.withValues(alpha: 0.88),
              _bg,
            ],
          ),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: outlined ? btnBg.withValues(alpha: 0.12) : btnBg,
              border: outlined
                  ? Border.all(
                  color: btnBg.withValues(alpha: 0.5), width: 1.5)
                  : null,
              boxShadow: onTap != null && !outlined
                  ? [
                BoxShadow(
                  color: btnBg.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(btnIcon,
                    color: outlined ? btnBg : btnFg, size: 20),
                const SizedBox(width: 10),
                Text(
                  btnText,
                  style: TextStyle(
                    color: outlined ? btnBg : btnFg,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────
class _PaymentInfo {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;

  const _PaymentInfo({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
  });
}