import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'settings_constants.dart';

class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _fadeController;
  final _db = Supabase.instance.client;

  // Loading states
  bool _isGeneratingPdf = false;
  bool _isGeneratingCsv = false;
  bool _isLoadingProfile = false;
  bool _isLoadingActivity = false;

  // Real data
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _activityData = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
    )..forward();
    _loadAllData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Supabase থেকে profile data load ──
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadProfile(),
      _loadActivity(),
    ]);
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;

      final res = await _db
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) setState(() => _profileData = res);
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadActivity() async {
    setState(() => _isLoadingActivity = true);
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;

      final res = await _db
          .from('account_activities')
          .select('activity_type, detail, device, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      if (mounted) setState(() => _activityData = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Activity load error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingActivity = false);
    }
  }

  // ── Profile Preview Dialog ──
  void _showProfilePreview() {
    if (_profileData == null) {
      SC.toast(context, SC.tr('no_data_found'), SC.orange);
      return;
    }
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF4A5568);
    final cardColor = isDark ? SC.cardBg : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subTextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                SC.tr('profile_preview'),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _profileData!.entries
                    .where((e) =>
                e.value != null &&
                    e.value.toString().isNotEmpty &&
                    e.value.toString() != 'null')
                    .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          e.key,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value.toString(),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Activity Preview Dialog ──
  void _showActivityPreview() {
    if (_activityData.isEmpty) {
      SC.toast(context, SC.tr('no_data_found'), SC.orange);
      return;
    }
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF4A5568);
    final cardColor = isDark ? SC.cardBg : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subTextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                SC.tr('activity_preview'),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _activityData.length,
                separatorBuilder: (_, __) => Divider(
                  color: subTextColor.withValues(alpha: 0.1),
                ),
                itemBuilder: (_, i) {
                  final a = _activityData[i];
                  final time = a['created_at'] != null
                      ? DateTime.parse(a['created_at']).toLocal()
                      : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                SC.tr(a['activity_type'] ?? ''),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (a['device'] != null)
                                Text(
                                  a['device'],
                                  style: TextStyle(
                                      color: subTextColor, fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        if (time != null)
                          Text(
                            '${time.day}/${time.month}/${time.year}',
                            style:
                            TextStyle(color: subTextColor, fontSize: 11),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Real PDF Generate & Share ──
  Future<void> _generateAndSharePdf() async {
    if (_profileData == null) {
      SC.toast(context, SC.tr('no_data_found'), SC.orange);
      return;
    }
    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('1A00E5FF'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Profile Data Export',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Profile section
            pw.Text(
              'Profile Information',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              children: _profileData!.entries
                  .where((e) =>
              e.value != null &&
                  e.value.toString().isNotEmpty &&
                  e.value.toString() != 'null')
                  .map(
                    (e) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        e.key,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        e.value.toString(),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              )
                  .toList(),
            ),

            // Activity section
            if (_activityData.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text(
                'Account Activity History',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  pw.TableRow(
                    decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                    children: ['Activity', 'Device', 'Date']
                        .map(
                          (h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                  ..._activityData.map((a) {
                    final time = a['created_at'] != null
                        ? DateTime.parse(a['created_at']).toLocal()
                        : null;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            a['activity_type'] ?? '',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            a['device'] ?? '—',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            time != null
                                ? '${time.day}/${time.month}/${time.year}'
                                : '—',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      );

      // PDF share/print
      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
        'profile_export_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) SC.toast(context, SC.tr('export_success'), SC.green);
    } catch (e) {
      if (mounted) SC.toast(context, SC.tr('export_error'), SC.red);
      debugPrint('PDF error: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // ── Real CSV Generate & Share ──
  Future<void> _generateAndShareCsv() async {
    if (_profileData == null && _activityData.isEmpty) {
      SC.toast(context, SC.tr('no_data_found'), SC.orange);
      return;
    }
    setState(() => _isGeneratingCsv = true);
    try {
      final buffer = StringBuffer();

      // Profile CSV
      buffer.writeln('=== PROFILE DATA ===');
      buffer.writeln('Field,Value');
      _profileData?.entries
          .where((e) =>
      e.value != null &&
          e.value.toString().isNotEmpty &&
          e.value.toString() != 'null')
          .forEach((e) {
        final value = e.value.toString().replaceAll(',', ';');
        buffer.writeln('${e.key},$value');
      });

      // Activity CSV
      if (_activityData.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('=== ACTIVITY HISTORY ===');
        buffer.writeln('Activity,Detail,Device,Date');
        for (final a in _activityData) {
          final time = a['created_at'] != null
              ? DateTime.parse(a['created_at']).toLocal()
              : null;
          buffer.writeln(
            '${a['activity_type'] ?? ''},'
                '${(a['detail'] ?? '').toString().replaceAll(',', ';')},'
                '${a['device'] ?? ''},'
                '${time != null ? '${time.day}/${time.month}/${time.year}' : ''}',
          );
        }
      }

      // File save করুন
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());

      // Share করুন
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Profile Data Export',
      );

      if (mounted) SC.toast(context, SC.tr('export_success'), SC.green);
    } catch (e) {
      if (mounted) SC.toast(context, SC.tr('export_error'), SC.red);
      debugPrint('CSV error: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingCsv = false);
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
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.50)
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
            // Background
            Container(
                decoration: BoxDecoration(gradient: SC.currentGradient)),
            Positioned(
              top: -80,
              right: -60,
              child: SC.blob(260, SC.cyan.withValues(alpha: 0.04)),
            ),
            Positioned(
              bottom: 200,
              left: -120,
              child: SC.blob(240, SC.blue.withValues(alpha: 0.04)),
            ),
            Column(
              children: [
                _buildAppBar(textColor),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
                      children: [
                        // ── Profile Data Section ──
                        _sectionHeader(
                          SC.tr('profile_data_section'),
                          Icons.person_rounded,
                          SC.cyan,
                          subTextColor,
                        ),
                        const SizedBox(height: 12),
                        _customCard(cardColor, borderColor, [
                          _customTile(
                            icon: Icons.preview_rounded,
                            iconColor: SC.cyan,
                            title: SC.tr('download_profile_info'),
                            subtitle: SC.tr('download_profile_sub'),
                            textColor: textColor,
                            subTextColor: subTextColor,
                            trailing: _isLoadingProfile
                                ? _loadingIndicator()
                                : _profileData != null
                                ? Icon(Icons.check_circle_rounded,
                                color: SC.green, size: 18)
                                : null,
                            onTap: _isLoadingProfile
                                ? null
                                : _showProfilePreview,
                          ),
                          _divider(borderColor),
                          _customTile(
                            icon: Icons.history_rounded,
                            iconColor: SC.blue,
                            title: SC.tr('activity_history'),
                            subtitle: SC.tr('activity_history_sub'),
                            textColor: textColor,
                            subTextColor: subTextColor,
                            trailing: _isLoadingActivity
                                ? _loadingIndicator()
                                : _activityData.isNotEmpty
                                ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: SC.blue
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_activityData.length}',
                                style: TextStyle(
                                  color: SC.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                                : null,
                            onTap: _isLoadingActivity
                                ? null
                                : _showActivityPreview,
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // ── Export Section ──
                        _sectionHeader(
                          SC.tr('export_section'),
                          Icons.upload_file_rounded,
                          SC.purple,
                          subTextColor,
                        ),
                        const SizedBox(height: 12),
                        _customCard(cardColor, borderColor, [
                          _customTile(
                            icon: Icons.picture_as_pdf_rounded,
                            iconColor: SC.red,
                            title: SC.tr('save_as_pdf'),
                            subtitle: SC.tr('save_as_pdf_sub'),
                            textColor: textColor,
                            subTextColor: subTextColor,
                            trailing: _isGeneratingPdf
                                ? _loadingIndicator()
                                : null,
                            onTap: _isGeneratingPdf
                                ? null
                                : _generateAndSharePdf,
                          ),
                          _divider(borderColor),
                          _customTile(
                            icon: Icons.table_chart_rounded,
                            iconColor: SC.green,
                            title: SC.tr('save_as_csv'),
                            subtitle: SC.tr('save_as_csv_sub'),
                            textColor: textColor,
                            subTextColor: subTextColor,
                            trailing: _isGeneratingCsv
                                ? _loadingIndicator()
                                : null,
                            onTap: _isGeneratingCsv
                                ? null
                                : _generateAndShareCsv,
                          ),
                        ]),
                      ],
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
          top: MediaQuery.of(context).padding.top + 10, bottom: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              SC.tr('export_data_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor, size: 22),
            onPressed: _loadAllData,
          ),
        ],
      ),
    );
  }

  // ── Section Header ──
  Widget _sectionHeader(
      String title, IconData icon, Color accent, Color subTextColor) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: subTextColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _customCard(
      Color cardColor, Color borderColor, List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(children: children),
      );

  Widget _customTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subTextColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) =>
      ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(color: subTextColor, fontSize: 12)),
        trailing: trailing,
        onTap: onTap,
      );

  Widget _divider(Color borderColor) =>
      Divider(height: 1, color: borderColor, indent: 18, endIndent: 18);

  Widget _loadingIndicator() => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(
        color: SC.cyan, strokeWidth: 2),
  );
}