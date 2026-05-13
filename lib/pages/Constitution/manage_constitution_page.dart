import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:css/models/constitution_model.dart';
import 'package:css/services/constitution_service.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class ManageConstitutionPage extends StatefulWidget {
  const ManageConstitutionPage({super.key});

  @override
  State<ManageConstitutionPage> createState() => _ManageConstitutionPageState();
}

class _ManageConstitutionPageState extends State<ManageConstitutionPage>
    with TickerProviderStateMixin {
  final _service = ConstitutionService();

  bool _loading = true;
  List<ConstitutionFile> _files = [];
  String? _error;

  late AnimationController _listAnim;
  late AnimationController _pulseAnim;
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulseAnim =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fetch();
  }

  @override
  void dispose() {
    _listAnim.dispose();
    _pulseAnim.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────
  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _files = await _service.fetchFiles();
      _listAnim.forward(from: 0);
    } catch (e) {
      _error = 'Constitution ফাইল লোড করতে সমস্যা হয়েছে';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(ConstitutionFile file) async {
    final confirmed = await _showDeleteDialog(file.name);
    if (!confirmed) return;

    _showProgress('মুছে ফেলা হচ্ছে...');
    try {
      await _service.deleteFile(file.id);
      if (mounted) {
        Navigator.pop(context);
        SC.toast(context, 'সফলভাবে মুছে ফেলা হয়েছে', SC.green);
      }
      _fetch();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        SC.toast(context, 'মুছতে ব্যর্থ হয়েছে', SC.red);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (_, __, ___) => _buildPage(),
    );
  }

  Widget _buildPage() {
    final isDark      = SC.isDark;
    final bg          = isDark ? const Color(0xFF070C16) : const Color(0xFFF0F4FF);
    final accent      = isDark ? const Color(0xFF00FFFF) : SC.cyan;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(children: [
          // Background orbs
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Stack(children: [
              Positioned(
                top: -100, right: -80,
                child: _orb(280, accent,
                    (isDark ? 0.06 : 0.03) + _pulseAnim.value * 0.02),
              ),
              Positioned(
                bottom: 200, left: -60,
                child: _orb(200, const Color(0xFF7B61FF),
                    (isDark ? 0.05 : 0.02) + _pulseAnim.value * 0.02),
              ),
            ]),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(isDark, accent),
              if (_loading)
                SliverFillRemaining(
                  child: Center(child: _buildLoader(isDark, accent)),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildError(isDark, accent))
              else if (_files.isEmpty)
                  SliverFillRemaining(child: _buildEmpty(isDark, accent))
                else
                  _buildList(isDark, accent),
            ],
          ),
        ]),
        floatingActionButton: AnimatedBuilder(
          animation: _fabAnim,
          builder: (_, child) => Transform.scale(
            scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut).value,
            child: child,
          ),
          child: GestureDetector(
            onTap: _showUploadDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF00FFFF), const Color(0xFF0077FF)]
                      : [SC.cyan, SC.blue],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.upload_file_rounded,
                    color: isDark ? Colors.black : Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'PDF আপলোড',
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orb(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)]),
    ),
  );

  // ── AppBar ─────────────────────────────────────────────────────
  Widget _buildAppBar(bool isDark, Color accent) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final bg        = isDark ? const Color(0xFF070C16) : const Color(0xFFF0F4FF);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: bg,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.08)),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 16),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _fetch,
          child: Container(
            margin: const EdgeInsets.all(10),
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.black.withOpacity(0.08)),
            ),
            child: Icon(Icons.refresh_rounded, color: accent, size: 18),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(bottom: 16, left: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ADMIN PANEL',
                style: TextStyle(
                    color: accent, fontSize: 8,
                    fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Constitution পরিচালনা',
              style: TextStyle(
                  color: textColor, fontSize: 18,
                  fontWeight: FontWeight.w900, letterSpacing: -0.3),
            ),
          ],
        ),
        background: _buildHeaderBg(isDark, accent),
      ),
    );
  }

  Widget _buildHeaderBg(bool isDark, Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1F3A), Color(0xFF070C16)])
            : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDEEEFB), Color(0xFFF0F4FF)]),
      ),
      child: Stack(children: [
        Positioned(
          right: 20, bottom: 60,
          child: Opacity(
            opacity: isDark ? 0.06 : 0.05,
            child: Icon(Icons.menu_book_rounded, size: 160, color: accent),
          ),
        ),
        Positioned(
          bottom: 56, left: 20,
          child: Row(children: [
            _stat('${_files.length}', 'মোট ফাইল', accent, isDark),
          ]),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                const Color(0xFF7B61FF),
                accent,
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _stat(String value, String label, Color color, bool isDark) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 26,
                fontWeight: FontWeight.w900, letterSpacing: -1)),
        Text(label,
            style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.black.withOpacity(0.4),
                fontSize: 10, fontWeight: FontWeight.w600)),
      ]);

  // ── List ───────────────────────────────────────────────────────
  Widget _buildList(bool isDark, Color accent) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (ctx, i) {
            final f     = _files[i];
            final delay = (i * 0.07).clamp(0.0, 0.5);
            return AnimatedBuilder(
              animation: _listAnim,
              builder: (_, child) {
                final p = Curves.easeOutCubic.transform(
                    ((_listAnim.value - delay) / (1 - delay)).clamp(0.0, 1.0));
                return Opacity(
                  opacity: p,
                  child: Transform.translate(
                      offset: Offset(0, 28 * (1 - p)), child: child),
                );
              },
              child: _buildFileCard(f, isDark, accent),
            );
          },
          childCount: _files.length,
        ),
      ),
    );
  }

  Widget _buildFileCard(ConstitutionFile file, bool isDark, Color accent) {
    final cardBg = isDark ? const Color(0xFF0C1525) : Colors.white;
    final border = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.07);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: !isDark
            ? [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4))]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              // PDF icon
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.25)),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFFFF6B6B), size: 26),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1A2332),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(file.uploadedAt),
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.35)
                            : Colors.black.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Delete button
              GestureDetector(
                onTap: () => _delete(file),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFF6B6B).withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFFF6B6B), size: 20),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Upload Dialog ──────────────────────────────────────────────
  void _showUploadDialog() {
    final isDark  = SC.isDark;
    final accent  = isDark ? const Color(0xFF00FFFF) : SC.cyan;
    final nameCtrl = TextEditingController(text: 'CSS Constitution');
    PlatformFile? selectedFile;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0C1525) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 16, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(0.7),
                          isDark ? const Color(0xFF0C1525) : Colors.white,
                        ],
                        end: Alignment.centerRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.upload_file_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Constitution PDF আপলোড',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white70, size: 18),
                        ),
                      ),
                    ]),
                  ),

                  // Form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name field
                          _fieldLabel('ফাইলের নাম', isDark),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameCtrl,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1A2332),
                              fontSize: 14,
                            ),
                            decoration: _fieldDeco(
                                'যেমন: CSS Constitution 2024', isDark, accent),
                          ),
                          const SizedBox(height: 22),

                          // File picker
                          _fieldLabel('PDF ফাইল', isDark),
                          const SizedBox(height: 8),

                          if (selectedFile != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color:
                                const Color(0xFF00E5A0).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF00E5A0)
                                        .withOpacity(0.25)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF00E5A0), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selectedFile!.name,
                                    style: const TextStyle(
                                        color: Color(0xFF00E5A0),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setD(() => selectedFile = null),
                                  child: const Icon(Icons.close_rounded,
                                      color: Color(0xFFFF6B6B), size: 18),
                                ),
                              ]),
                            ),
                          ],

                          GestureDetector(
                            onTap: () async {
                              final res =
                              await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                                withData: true,
                              );
                              if (res != null && res.files.isNotEmpty) {
                                setD(() => selectedFile = res.files.first);
                              }
                            },
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.03)
                                    : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: accent.withOpacity(0.2)),
                              ),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file_rounded,
                                        color: accent, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      selectedFile != null
                                          ? 'অন্য ফাইল বেছে নিন'
                                          : 'PDF ফাইল বেছে নিন',
                                      style: TextStyle(
                                          color: accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
                                    ),
                                  ]),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text('শুধুমাত্র PDF',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.black.withOpacity(0.25),
                                    fontSize: 10,
                                    letterSpacing: 0.5)),
                          ),

                          if (saving) ...[
                            const SizedBox(height: 18),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                  color: accent,
                                  backgroundColor: accent.withOpacity(0.1),
                                  minHeight: 4),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text('আপলোড হচ্ছে...',
                                  style: TextStyle(
                                      color: accent,
                                      fontSize: 12,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: saving ? null : () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.08)),
                            ),
                            child: Center(
                              child: Text('বাতিল',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: saving
                              ? null
                              : () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              SC.toast(context, 'নাম দিন', SC.red);
                              return;
                            }
                            if (selectedFile == null) {
                              SC.toast(context,
                                  'PDF ফাইল বেছে নিন', SC.red);
                              return;
                            }
                            setD(() => saving = true);
                            try {
                              final url = await _service
                                  .uploadPdf(selectedFile!);
                              if (url == null) {
                                SC.toast(context,
                                    'আপলোড ব্যর্থ হয়েছে', SC.red);
                                setD(() => saving = false);
                                return;
                              }
                              await _service.createFile(
                                name:   nameCtrl.text.trim(),
                                pdfUrl: url,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetch();
                              SC.toast(context,
                                  'সফলভাবে আপলোড হয়েছে', SC.green);
                            } catch (e) {
                              setD(() => saving = false);
                              SC.toast(context, 'Error: $e', SC.red);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient:
                              LinearGradient(colors: [accent, SC.blue]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: accent.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Center(
                              child: saving
                                  ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      strokeWidth: 2))
                                  : Text('আপলোড করুন',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  Widget _fieldLabel(String text, bool isDark) => Text(
    text.toUpperCase(),
    style: TextStyle(
        color: isDark
            ? Colors.white.withOpacity(0.35)
            : Colors.black.withOpacity(0.4),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5),
  );

  InputDecoration _fieldDeco(String hint, bool isDark, Color accent) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.3),
            fontSize: 14),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent, width: 1.5)),
        contentPadding: const EdgeInsets.all(16),
      );

  Widget _buildLoader(bool isDark, Color accent) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
          width: 48, height: 48,
          child: CircularProgressIndicator(
              color: accent,
              backgroundColor: accent.withOpacity(0.05),
              strokeWidth: 2.5)),
      const SizedBox(height: 14),
      Text('লোড হচ্ছে...',
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
              fontSize: 12, letterSpacing: 1.2)),
    ],
  );

  Widget _buildError(bool isDark, Color accent) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.3))),
        child: const Icon(Icons.wifi_off_rounded,
            color: Color(0xFFFF6B6B), size: 36),
      ),
      const SizedBox(height: 16),
      Text(_error!,
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5),
              fontSize: 14)),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _fetch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent, SC.blue]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5))
              ]),
          child: Text('আবার চেষ্টা করুন',
              style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
      ),
    ]),
  );

  Widget _buildEmpty(bool isDark, Color accent) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Opacity(
        opacity: 0.12,
        child: Icon(Icons.menu_book_rounded,
            size: 90, color: isDark ? Colors.white : Colors.black),
      ),
      const SizedBox(height: 14),
      Text('কোনো Constitution ফাইল নেই',
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.4),
              fontSize: 14)),
      const SizedBox(height: 6),
      Text('নিচের বাটনে ক্লিক করে PDF আপলোড করুন',
          style: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.18)
                  : Colors.black.withOpacity(0.25),
              fontSize: 12)),
    ]),
  );

  Future<bool> _showDeleteDialog(String name) async {
    final isDark = SC.isDark;
    return await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C1525) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.25)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3))),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFFF6B6B), size: 30),
            ),
            const SizedBox(height: 18),
            Text('ফাইল মুছবেন?',
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A2332),
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              '"$name"\nCloudinary থেকেও permanently মুছে যাবে।',
              style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.45)
                      : Colors.black.withOpacity(0.5),
                  fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.08))),
                    child: Center(
                      child: Text('বাতিল',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black54,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFFF4444)
                      ]),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFFF6B6B).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Center(
                      child: Text('মুছুন',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    ) ??
        false;
  }

  void _showProgress(String msg) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: SC.isDark ? const Color(0xFF0C1525) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: SC.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 44, height: 44,
              child: CircularProgressIndicator(
                  color: SC.isDark ? const Color(0xFF00FFFF) : SC.cyan,
                  strokeWidth: 2.5)),
          const SizedBox(height: 14),
          Text(msg,
              style: TextStyle(
                  color: SC.isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13)),
        ]),
      ),
    ),
  );
}