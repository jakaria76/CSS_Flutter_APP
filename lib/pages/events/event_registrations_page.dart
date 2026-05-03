import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class EventRegistrationsPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final String? bannerUrl;

  const EventRegistrationsPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.bannerUrl,
  });

  @override
  State<EventRegistrationsPage> createState() =>
      _EventRegistrationsPageState();
}

class _EventRegistrationsPageState extends State<EventRegistrationsPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  bool loading       = true;
  bool onlyVolunteers = false;
  List<Map<String, dynamic>> registrations = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
    fetchRegistrations();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> fetchRegistrations() async {
    try {
      if (mounted) setState(() => loading = true);
      final res = await supabase
          .from('event_registrations')
          .select()
          .eq('event_id', widget.eventId)
          .order('registered_at', ascending: true);
      if (mounted) {
        setState(() {
          registrations = List<Map<String, dynamic>>.from(res);
          loading = false;
        });
      }
    } catch (_) {
      SC.toast(context, SC.tr('failedLoadReg'), SC.red);
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> downloadCSV() async {
    try {
      SC.toast(context, SC.tr('preparingCsv'), SC.cyan);
      if (registrations.isEmpty) {
        SC.toast(context, SC.tr('noDataExport'), SC.red);
        return;
      }
      List<List<dynamic>> rows = [
        ['Serial No.','Full Name','Mobile','Email','Gender','Institute Name',
          'Class/Year','Why Join','Will Volunteer','Payment Method',
          'User Image URL','Registered At','User ID','Event ID']
      ];
      for (int i = 0; i < registrations.length; i++) {
        final reg = registrations[i];
        rows.add([
          (i + 1).toString(), reg['full_name'] ?? 'N/A',
          reg['mobile'] ?? 'N/A', reg['email'] ?? 'N/A',
          reg['gender'] ?? 'N/A', reg['institute_name'] ?? 'N/A',
          reg['class_name'] ?? 'N/A', reg['why_join'] ?? 'N/A',
          reg['will_volunteer'] == true ? 'Yes' : 'No',
          reg['payment_method'] ?? 'N/A', reg['user_image_url'] ?? 'N/A',
          reg['registered_at'] ?? 'N/A', reg['user_id'] ?? 'N/A',
          reg['event_id']?.toString() ?? 'N/A',
        ]);
      }
      String csv = const ListToCsvConverter().convert(rows);
      Directory? directory;
      String filePath = '';
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) await directory.create(recursive: true);
        final fileName =
            '${widget.eventTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
        filePath = '${directory.path}/$fileName';
      } else {
        directory = await getApplicationDocumentsDirectory();
        final fileName =
            '${widget.eventTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
        filePath = '${directory.path}/$fileName';
      }
      final file = File(filePath);
      await file.writeAsString(csv);
      SC.toast(context,
          '✅ ${registrations.length} registrations saved → ${file.uri.pathSegments.last}',
          SC.green);
    } catch (e) {
      SC.toast(context, '❌ ${SC.tr('failedUpdate')}: $e', SC.red);
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
    final isDark       = SC.isDark;
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final cardColor    = isDark ? SC.cardBg : Colors.white;

    final filtered = onlyVolunteers
        ? registrations.where((r) => r['will_volunteer'] == true).toList()
        : registrations;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            children: [
              Text(SC.tr('registrations').toUpperCase(),
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 15,
                      color: SC.blue)),
              Text(widget.eventTitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.4)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  SC.cyan.withOpacity(0.1),
                  SC.blue.withOpacity(0.1)
                ]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SC.cyan.withOpacity(0.3)),
              ),
              child:
              Icon(Icons.arrow_back_ios_new, color: SC.cyan, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: SC.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.refresh, color: SC.cyan, size: 20),
              ),
              onPressed: fetchRegistrations,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: SC.currentGradient),
          child: Stack(
            children: [
              Positioned(
                  top: -100, right: -100,
                  child: _animatedOrb(300, SC.cyan.withOpacity(0.08))),
              Positioned(
                  bottom: -150, left: -100,
                  child: _animatedOrb(350, SC.purple.withOpacity(0.06))),
              Positioned(
                  top: 200, left: -50,
                  child: _animatedOrb(200, SC.blue.withOpacity(0.05))),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: loading
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: SC.cyan, strokeWidth: 3),
                        const SizedBox(height: 20),
                        Text(SC.tr('loadingReg'),
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.5),
                                fontSize: 14)),
                      ],
                    ),
                  )
                      : Column(
                    children: [
                      _buildPremiumHeader(filtered.length, textColor,
                          subTextColor, borderColor, cardColor, isDark),
                      const SizedBox(height: 15),
                      Expanded(
                        child: filtered.isEmpty
                            ? _buildEmptyState(textColor, subTextColor)
                            : RefreshIndicator(
                          color: SC.cyan,
                          onRefresh: fetchRegistrations,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                20, 0, 20, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildPremiumCard(
                                    filtered[index],
                                    index + 1,
                                    isDark,
                                    textColor,
                                    subTextColor,
                                    borderColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: registrations.isEmpty
            ? null
            : _buildFloatingButtons(),
      ),
    );
  }

  Widget _buildPremiumHeader(int count, Color textColor, Color subTextColor,
      Color borderColor, Color cardColor, bool isDark) {
    final volunteerCount =
        registrations.where((r) => r['will_volunteer'] == true).length;
    final attendeeCount = registrations.length - volunteerCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                cardColor.withOpacity(isDark ? 0.08 : 0.95),
                cardColor.withOpacity(isDark ? 0.03 : 0.85),
              ]),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: SC.cyan.withOpacity(0.1),
                    blurRadius: 30, spreadRadius: 5)
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [SC.cyan, SC.blue]),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: SC.cyan.withOpacity(0.3),
                              blurRadius: 15, spreadRadius: 1)
                        ],
                      ),
                      child: const Icon(Icons.groups_3_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(SC.tr('totalRegistrations').toUpperCase(),
                              style: TextStyle(
                                  color: subTextColor.withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('${registrations.length}',
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 32,
                                      height: 1)),
                              const SizedBox(width: 8),
                              Text(SC.tr('participants'),
                                  style: TextStyle(
                                      color: textColor.withValues(alpha: 0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildCompactFilter(textColor),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: borderColor),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            Icons.volunteer_activism_rounded,
                            volunteerCount.toString(),
                            SC.tr('volunteers'),
                            LinearGradient(
                                colors: [SC.green, Colors.green.shade700]))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            Icons.people_alt_rounded,
                            attendeeCount.toString(),
                            SC.tr('attendees'),
                            LinearGradient(
                                colors: [SC.orange, Colors.deepOrange]))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Gradient gradient) {
    final mainColor = gradient.colors.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mainColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: mainColor, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: mainColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 24)),
          Text(label,
              style: TextStyle(
                  color: mainColor.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCompactFilter(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onlyVolunteers
            ? SC.green.withOpacity(0.15)
            : textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: onlyVolunteers
              ? SC.green.withOpacity(0.5)
              : textColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volunteer_activism_rounded,
              color: onlyVolunteers ? SC.green : textColor.withValues(alpha: 0.4),
              size: 16),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: onlyVolunteers,
              activeColor: SC.green,
              onChanged: (v) => setState(() => onlyVolunteers = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(Map<String, dynamic> data, int index, bool isDark,
      Color textColor, Color subTextColor, Color borderColor) {
    final isVolunteer = data['will_volunteer'] == true;
    final imageUrl    = data['user_image_url'];
    final hasImage    = imageUrl != null && imageUrl.toString().isNotEmpty;
    final cardColor   = isDark ? SC.cardBg : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isVolunteer
                    ? SC.green.withOpacity(0.4)
                    : borderColor,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(colors: [
                                SC.cyan.withOpacity(0.3),
                                SC.blue.withOpacity(0.3),
                              ]),
                              border: Border.all(
                                  color: SC.cyan.withOpacity(0.5), width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: hasImage
                                  ? Image.network(imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.person_rounded,
                                          color: textColor.withValues(alpha: 0.3),
                                          size: 30))
                                  : Icon(Icons.person_rounded,
                                  color: textColor.withValues(alpha: 0.3),
                                  size: 30),
                            ),
                          ),
                          Positioned(
                            bottom: -2, right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [SC.cyan, SC.blue]),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF0A0E27)
                                        : Colors.white,
                                    width: 2),
                              ),
                              child: Text('#$index',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['full_name'] ?? 'N/A',
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            if (data['gender'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: textColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(data['gender'],
                                    style: TextStyle(
                                        color: textColor.withValues(alpha: 0.6),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                      if (isVolunteer)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [SC.green, Colors.green.shade700]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.volunteer_activism,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('VOL',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(Icons.phone_rounded, data['mobile'], SC.cyan),
                  _buildInfoItem(Icons.email_rounded, data['email'], SC.blue),
                  _buildInfoItem(Icons.school_rounded, data['institute_name'], SC.purple),
                  _buildInfoItem(Icons.class_rounded, data['class_name'], SC.orange),
                  if (data['why_join'] != null &&
                      data['why_join'].toString().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: textColor.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote_rounded,
                              color: SC.cyan.withOpacity(0.5), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(data['why_join'],
                                style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  if (data['payment_status'] != null) ...[
                    const SizedBox(height: 12),
                    _buildPaymentStatusSection(
                        data, isDark, textColor, subTextColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusSection(Map<String, dynamic> data, bool isDark,
      Color textColor, Color subTextColor) {
    final status        = data['payment_status'] ?? 'pending';
    final screenshotUrl = data['payment_screenshot_url'];
    final txId          = data['transaction_id'];
    final payNum        = data['payment_number'];

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'verified':
        statusColor = SC.green;
        statusIcon  = Icons.verified_rounded;
        statusText  = SC.tr('paymentVerified');
        break;
      case 'rejected':
        statusColor = SC.red;
        statusIcon  = Icons.cancel_rounded;
        statusText  = SC.tr('paymentRejectedMsg');
        break;
      default:
        statusColor = SC.orange;
        statusIcon  = Icons.hourglass_top_rounded;
        statusText  = SC.tr('paymentPendingStatus');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Text(statusText,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
            ],
          ),
          if (payNum != null || txId != null) ...[
            const SizedBox(height: 10),
            if (payNum != null)
              _payDetailRow(Icons.phone_android_outlined,
                  SC.tr('paymentNumber'), payNum, textColor),
            if (txId != null)
              _payDetailRow(Icons.receipt_long_outlined,
                  SC.tr('transactionId'), txId, textColor),
          ],
          if (screenshotUrl != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showScreenshotDialog(screenshotUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: SC.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SC.cyan.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_rounded, color: SC.cyan, size: 16),
                    const SizedBox(width: 8),
                    Text(SC.tr('screenshotView'),
                        style: TextStyle(
                            color: SC.cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        _updatePaymentStatus(data['id'], 'verified'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: SC.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SC.green.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: SC.green, size: 18),
                          const SizedBox(width: 6),
                          Text(SC.tr('paymentVerify').toUpperCase(),
                              style: TextStyle(
                                  color: SC.green,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        _updatePaymentStatus(data['id'], 'rejected'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: SC.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SC.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_rounded, color: SC.red, size: 18),
                          const SizedBox(width: 6),
                          Text(SC.tr('paymentReject').toUpperCase(),
                              style: TextStyle(
                                  color: SC.red,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _payDetailRow(
      IconData icon, String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: textColor.withValues(alpha: 0.4), size: 14),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.5), fontSize: 12)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePaymentStatus(int registrationId, String status) async {
    try {
      await supabase
          .from('event_registrations')
          .update({'payment_status': status})
          .eq('id', registrationId);
      fetchRegistrations();
      SC.toast(
        context,
        status == 'verified' ? SC.tr('verifySuccess') : SC.tr('rejectSuccess'),
        status == 'verified' ? SC.green : SC.red,
      );
    } catch (e) {
      SC.toast(context, '${SC.tr('failedUpdate')}: $e', SC.red);
    }
  }

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 12),
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

  Widget _buildInfoItem(IconData icon, dynamic value, Color color) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value.toString(),
                style: TextStyle(
                    color: SC.isDark ? Colors.white : const Color(0xFF1A2332),
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [SC.green, Colors.green.shade700]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: SC.green.withOpacity(0.4),
              blurRadius: 20, spreadRadius: 2)
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: downloadCSV,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.file_download_rounded,
            color: Colors.white, size: 24),
        label: Text(SC.tr('exportCsv'),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1)),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: textColor.withValues(alpha: 0.04),
              boxShadow: [
                BoxShadow(
                    color: SC.cyan.withOpacity(0.1),
                    blurRadius: 30, spreadRadius: 5)
              ],
            ),
            child: Icon(
              onlyVolunteers
                  ? Icons.volunteer_activism_outlined
                  : Icons.groups_outlined,
              size: 80,
              color: textColor.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            onlyVolunteers
                ? SC.tr('noVolunteers')
                : SC.tr('noRegistrations'),
            style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            onlyVolunteers
                ? SC.tr('turnOffFilter')
                : SC.tr('regAppearHere'),
            style: TextStyle(
                color: subTextColor.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _animatedOrb(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
    ),
  );
}