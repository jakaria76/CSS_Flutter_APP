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

class _EventDetailsPageState extends State<EventDetailsPage> {
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

  @override
  void initState() {
    super.initState();
    loadEvent();
    _checkUserRole();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final data = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) setState(() => userRole = data?['role']?.toString().toLowerCase());
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
        setState(() { error = SC.tr('eventNotFound'); loading = false; });
        return;
      }
      final imgs = await supabase
          .from('event_images')
          .select()
          .eq('event_id', widget.eventId);

      event   = Map<String, dynamic>.from(e);
      gallery = List<Map<String, dynamic>>.from(imgs);

      _setupMapLocation();
      setupCountdown();
      await _checkUserRegistration();
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
          width: 80, height: 80,
          child: const Icon(Icons.location_on, size: 50, color: Colors.redAccent),
        )
      ];
    }
  }

  void setupCountdown() {
    final start = DateTime.parse(event!['start_datetime']).toLocal();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = start.difference(DateTime.now());
      if (!mounted) return;
      setState(() => remaining = diff.isNegative ? Duration.zero : diff);
    });
  }

  Map<String, dynamic> _getPaymentStatusInfo(String? status) {
    switch (status) {
      case 'verified':
        return {
          'label': SC.tr('paymentVerified'),
          'sublabel': SC.tr('regConfirmedMsg'),
          'icon': Icons.verified_rounded,
          'color': Colors.greenAccent,
          'bgColor': Colors.green.withOpacity(0.12),
          'borderColor': Colors.green.withOpacity(0.4),
        };
      case 'rejected':
        return {
          'label': SC.tr('paymentRejectedMsg'),
          'sublabel': SC.tr('contactAdmin'),
          'icon': Icons.cancel_rounded,
          'color': Colors.redAccent,
          'bgColor': Colors.red.withOpacity(0.12),
          'borderColor': Colors.red.withOpacity(0.4),
        };
      default:
        return {
          'label': SC.tr('paymentPending'),
          'sublabel': SC.tr('pendingVerification'),
          'icon': Icons.hourglass_top_rounded,
          'color': Colors.orangeAccent,
          'bgColor': Colors.orange.withOpacity(0.12),
          'borderColor': Colors.orange.withOpacity(0.4),
        };
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
    final isDark      = SC.isDark;
    final textColor   = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    if (loading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: isDark ? SC.bgStart : const Color(0xFFF0F4FF),
          body: Center(child: CircularProgressIndicator(color: SC.cyan)),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(gradient: SC.currentGradient)),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeroBanner(isDark),
                  _buildDetailsContent(isDark, textColor, subTextColor, borderColor),
                ],
              ),
            ),
            _buildStickyBottomSection(isDark, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(bool isDark) {
    final banner = event!['banner_url'];
    return Stack(
      children: [
        Hero(
          tag: 'event_${widget.eventId}',
          child: Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              image: banner != null
                  ? DecorationImage(
                  image: NetworkImage(banner), fit: BoxFit.cover)
                  : null,
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            ),
            child: banner == null
                ? Icon(Icons.image, size: 100,
                color: isDark ? Colors.white24 : Colors.black26)
                : null,
          ),
        ),
        Container(
          height: 350,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                isDark ? const Color(0xFF0F2027) : const Color(0xFFF0F4FF),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsContent(bool isDark, Color textColor, Color subTextColor,
      Color borderColor) {
    final price = (event!['price'] ?? 0).toDouble();
    final cardColor = isDark ? SC.cardBg : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _priceBadge(price),
          const SizedBox(height: 15),
          Text(event!['title'] ?? '',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 1)),
          const SizedBox(height: 15),
          _glassContainer(isDark, borderColor, cardColor,
              child: Column(
                children: [
                  _infoTile(Icons.calendar_month, SC.tr('dateTime'),
                      formatDate(event!['start_datetime']), textColor, subTextColor),
                  Divider(color: borderColor),
                  _infoTile(Icons.location_on, SC.tr('venue'),
                      event!['venue'] ?? SC.tr('tbd'), textColor, subTextColor),
                  if (remaining != null) ...[
                    Divider(color: borderColor),
                    _infoTile(Icons.timer_outlined, SC.tr('countdown'),
                        countdownText(remaining!), textColor, subTextColor,
                        color: SC.cyan),
                  ],
                ],
              )),
          if (!checkingRegistration) ...[
            const SizedBox(height: 20),
            _buildRegistrationStatusCard(isDark, textColor, borderColor),
          ],
          if (userRole == 'admin') ...[
            const SizedBox(height: 15),
            _adminAction(textColor),
          ],
          const SizedBox(height: 25),
          Text(SC.tr('aboutEvent').toUpperCase(),
              style: TextStyle(color: SC.cyan, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Text(
            event!['full_description'] ?? SC.tr('noDescription'),
            style: TextStyle(
                color: subTextColor, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 25),
          if (_eventLocation != null)
            _buildMapSection(isDark, textColor, borderColor),
          const SizedBox(height: 25),
          if (gallery.isNotEmpty)
            _buildGallery(textColor),
          const SizedBox(height: 20),
          if (_eventLocation != null)
            _glassButton(
              isDark: isDark,
              borderColor: borderColor,
              icon: Icons.map_outlined,
              label: SC.tr('openGoogleMaps').toUpperCase(),
              onTap: openMap,
            ),
          const SizedBox(height: 130),
        ],
      ),
    );
  }

  Widget _buildRegistrationStatusCard(
      bool isDark, Color textColor, Color borderColor) {
    if (userRegistration == null) return const SizedBox.shrink();
    final paymentStatus = userRegistration!['payment_status'] as String?;
    final isFree  = (event!['price'] ?? 0) == 0;
    final info    = _getPaymentStatusInfo(paymentStatus);

    final Color statusColor  = info['color'] as Color;
    final Color bgColor      = info['bgColor'] as Color;
    final Color bdrColor     = info['borderColor'] as Color;
    final IconData icon      = info['icon'] as IconData;
    final String label       = info['label'] as String;
    final String sublabel    = info['sublabel'] as String;

    final txId         = userRegistration!['transaction_id'];
    final payNum       = userRegistration!['payment_number'];
    final screenshotUrl = userRegistration!['payment_screenshot_url'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: bdrColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: SC.cyan.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: SC.cyan.withOpacity(0.3)),
                          ),
                          child: Text(SC.tr('registered').toUpperCase(),
                              style: TextStyle(
                                  color: SC.cyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                        ),
                        const SizedBox(height: 6),
                        Text(label,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 15)),
                        Text(sublabel,
                            style: TextStyle(
                                color: statusColor.withOpacity(0.7),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              if (isFree) ...[
                const SizedBox(height: 14),
                _statusDivider(),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(SC.tr('regSuccessMsg'),
                      style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13)),
                ]),
              ],
              if (!isFree) ...[
                const SizedBox(height: 16),
                _statusDivider(),
                const SizedBox(height: 14),
                if (payNum != null)
                  _detailRow(Icons.phone_android_outlined,
                      SC.tr('paymentNumber'), payNum.toString(), textColor),
                if (txId != null)
                  _detailRow(Icons.receipt_long_outlined,
                      SC.tr('transactionId'), txId.toString(), textColor),
                if (screenshotUrl != null) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showScreenshotDialog(screenshotUrl.toString()),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(screenshotUrl.toString(),
                              width: 60, height: 60, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 60, height: 60,
                                  color: Colors.white10,
                                  child: const Icon(Icons.image_outlined,
                                      color: Colors.white38))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(SC.tr('payScreenshot'),
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text(SC.tr('tapToView'),
                                  style: TextStyle(
                                      color: textColor.withValues(alpha: 0.4),
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.open_in_full_rounded,
                            color: SC.cyan.withOpacity(0.7), size: 18),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _statusDivider(),
                const SizedBox(height: 12),
                _buildStatusMessage(paymentStatus, textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(String? status, Color textColor) {
    switch (status) {
      case 'verified':
        return Row(children: [
          const Icon(Icons.celebration_rounded, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(SC.tr('verifiedWelcome'),
              style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13))),
        ]);
      case 'rejected':
        return Row(children: [
          const Icon(Icons.info_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(SC.tr('rejectedMsg'),
              style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13))),
        ]);
      default:
        return Row(children: [
          const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(SC.tr('pendingMsg'),
              style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13))),
        ]);
    }
  }

  Widget _detailRow(IconData icon, String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: textColor.withValues(alpha: 0.4), size: 16),
        const SizedBox(width: 10),
        Text('$label: ',
            style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 12, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: textColor,
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _statusDivider() => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.15),
        Colors.transparent,
      ]),
    ),
  );

  void _showScreenshotDialog(String url) {
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
                child: Image.network(url, fit: BoxFit.contain)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(SC.tr('close').toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyBottomSection(bool isDark, Color textColor) {
    final bool isClosed         = remaining == Duration.zero;
    final bool alreadyRegistered = userRegistration != null;
    final paymentStatus         = userRegistration?['payment_status'] as String?;
    final bool isVerified        = paymentStatus == 'verified';
    final bool isPending         = paymentStatus == 'pending';
    final bool isRejected        = paymentStatus == 'rejected';
    final bool isFree            = (event!['price'] ?? 0) == 0;

    Color btnColor;
    String btnText;
    VoidCallback? btnOnPressed;
    IconData btnIcon;

    if (alreadyRegistered) {
      if (isFree || isVerified) {
        btnColor      = Colors.greenAccent;
        btnText       = SC.tr('regConfirmed').toUpperCase();
        btnIcon       = Icons.check_circle_rounded;
        btnOnPressed  = null;
      } else if (isPending) {
        btnColor      = Colors.orangeAccent;
        btnText       = SC.tr('paymentPending').toUpperCase();
        btnIcon       = Icons.hourglass_top_rounded;
        btnOnPressed  = null;
      } else if (isRejected) {
        btnColor      = Colors.redAccent;
        btnText       = SC.tr('paymentRejected').toUpperCase();
        btnIcon       = Icons.cancel_rounded;
        btnOnPressed  = null;
      } else {
        btnColor      = Colors.grey;
        btnText       = SC.tr('alreadyRegistered').toUpperCase();
        btnIcon       = Icons.how_to_reg_rounded;
        btnOnPressed  = null;
      }
    } else if (isClosed) {
      btnColor      = Colors.grey;
      btnText       = SC.tr('registrationClosed').toUpperCase();
      btnIcon       = Icons.lock_outline_rounded;
      btnOnPressed  = null;
    } else {
      btnColor      = SC.cyan;
      btnText       = SC.tr('registerNow').toUpperCase();
      btnIcon       = Icons.app_registration_rounded;
      btnOnPressed  = () => Navigator.push(
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
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              (isDark ? SC.bgStart : const Color(0xFFF0F4FF)).withOpacity(0.85),
              isDark ? SC.bgStart : const Color(0xFFF0F4FF),
            ],
          ),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: const Color(0xFF0F2027),
            disabledBackgroundColor: btnColor.withOpacity(0.7),
            disabledForegroundColor: const Color(0xFF0F2027).withOpacity(0.7),
            padding: const EdgeInsets.all(18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: btnOnPressed != null ? 10 : 0,
            shadowColor: btnColor.withOpacity(0.3),
          ),
          onPressed: btnOnPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(btnIcon, size: 20),
              const SizedBox(width: 10),
              Text(btnText,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection(bool isDark, Color textColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(SC.tr('mapLocation').toUpperCase(),
            style: TextStyle(color: SC.cyan, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(color: SC.cyan.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)
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
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.css',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildGallery(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(SC.tr('gallery').toUpperCase(),
            style: TextStyle(color: SC.cyan, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: gallery.length,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(right: 15),
              width: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(gallery[index]['image_url']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _adminAction(Color textColor) {
    return InkWell(
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            SC.purple.withOpacity(0.3),
            SC.blue.withOpacity(0.3)
          ]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, color: textColor),
            const SizedBox(width: 10),
            Text(SC.tr('viewRegistrations').toUpperCase(),
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _glassContainer(bool isDark, Color borderColor, Color cardColor,
      {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _infoTile(IconData icon, String title, String subtitle,
      Color textColor, Color subTextColor, {Color? color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: (color ?? textColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color ?? subTextColor, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: subTextColor.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: TextStyle(
                      color: color ?? textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceBadge(double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: price > 0
            ? Colors.orange.withOpacity(0.2)
            : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: price > 0 ? Colors.orange : Colors.green),
      ),
      child: Text(
        price > 0 ? '৳ ${price.toInt()}' : SC.tr('freeEntry').toUpperCase(),
        style: TextStyle(
            color: price > 0 ? Colors.orange : Colors.greenAccent,
            fontWeight: FontWeight.w900,
            fontSize: 12),
      ),
    );
  }

  Widget _glassButton({
    required bool isDark,
    required Color borderColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final textColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor.withValues(alpha: 0.6), size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String formatDate(String dt) {
    final d = DateTime.parse(dt).toLocal();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year} • '
        '${d.hour % 12 == 0 ? 12 : d.hour % 12}:'
        '${d.minute.toString().padLeft(2, '0')} '
        '${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  String countdownText(Duration d) {
    if (d == Duration.zero) return SC.tr('eventStarted');
    return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
  }

  void openMap() async {
    final lat = event!['latitude'];
    final lng = event!['longitude'];
    if (lat == null || lng == null) return;
    final url =
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}