import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:css/models/notice_model.dart';

class NoticeManagementPage extends StatefulWidget {
  const NoticeManagementPage({super.key});

  @override
  State<NoticeManagementPage> createState() => _NoticeManagementPageState();
}

class _NoticeManagementPageState extends State<NoticeManagementPage> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List<Notice> notices = [];
  String? _error;
  String _searchQuery = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchNotices();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // সার্চ ফিল্টার লজিক
  List<Notice> get _filteredNotices {
    if (_searchQuery.isEmpty) return notices;
    return notices
        .where((n) => n.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _fetchNotices() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _supabase
          .from('notices')
          .select()
          .order('publish_date', ascending: false);

      notices = (data as List).map((e) => Notice.fromMap(e)).toList();
      _animationController.forward(from: 0);
    } catch (e) {
      _error = 'বিজ্ঞপ্তি লোড করতে সমস্যা হয়েছে';
      debugPrint(e.toString());
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteNotice(Notice notice) async {
    final confirmed = await _showDeleteConfirmation(notice.title);
    if (!confirmed) return;

    try {
      _showLoadingDialog();

      if (notice.pdfUrl != null) {
        try {
          final fileName = notice.pdfUrl!.split('/').last;
          await _supabase.storage.from('notice-pdfs').remove(['pdfs/$fileName']);
        } catch (e) {
          debugPrint('PDF deletion error: $e');
        }
      }

      await _supabase.from('notices').delete().eq('id', notice.id);

      if (mounted) {
        Navigator.pop(context); // লোডিং ডায়ালগ বন্ধ করুন
        _showSuccessSnackBar('বিজ্ঞপ্তি সফলভাবে মুছে ফেলা হয়েছে');
      }

      _fetchNotices();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('বিজ্ঞপ্তি মুছতে ব্যর্থ হয়েছে');
      }
    }
  }

  Future<String?> _uploadPdfToSupabase(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) throw Exception('ফাইল পড়া যায়নি');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.name}';
      final filePath = 'pdfs/$fileName';

      await _supabase.storage.from('notice-pdfs').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'application/pdf',
          upsert: false,
        ),
      );

      return _supabase.storage.from('notice-pdfs').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('PDF upload error: $e');
      return null;
    }
  }

  void _showAddEditDialog({Notice? notice}) {
    final isEditing = notice != null;
    final titleCtrl = TextEditingController(text: notice?.title ?? '');
    DateTime selectedDate = notice?.publishDate ?? DateTime.now();
    String? uploadedPdfUrl = notice?.pdfUrl;
    PlatformFile? selectedPdfFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1CB5E0), Color(0xFF000046)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                      ),
                      child: Row(
                        children: [
                          Icon(isEditing ? Icons.edit_note : Icons.add_circle_outline, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(isEditing ? 'বিজ্ঞপ্তি সম্পাদনা' : 'নতুন বিজ্ঞপ্তি',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Spacer(),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('বিজ্ঞপ্তির শিরোনাম'),
                            TextField(
                              controller: titleCtrl,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white),
                              decoration: _glassInputDecoration('বিস্তারিত এখানে লিখুন...'),
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('প্রকাশের তারিখ'),
                            _buildDatePickerField(context, selectedDate, (date) => setDialogState(() => selectedDate = date)),
                            const SizedBox(height: 20),
                            _buildLabel('সংযুক্ত ডকুমেন্ট'),
                            _buildFileSection(selectedPdfFile, uploadedPdfUrl, setDialogState),
                            if (isUploading) ...[
                              const SizedBox(height: 20),
                              const LinearProgressIndicator(color: Colors.cyanAccent, backgroundColor: Colors.white10),
                            ]
                          ],
                        ),
                      ),
                    ),
                    _buildDialogActions(context, isUploading, isEditing, () async {
                      if (titleCtrl.text.isEmpty) { _showErrorSnackBar('শিরোনাম লিখুন'); return; }
                      setDialogState(() => isUploading = true);
                      try {
                        String? finalPdfUrl = uploadedPdfUrl;
                        if (selectedPdfFile != null) finalPdfUrl = await _uploadPdfToSupabase(selectedPdfFile!);
                        final data = {'title': titleCtrl.text.trim(), 'publish_date': selectedDate.toIso8601String(), 'pdf_url': finalPdfUrl};
                        if (isEditing) { await _supabase.from('notices').update(data).eq('id', notice.id); }
                        else { await _supabase.from('notices').insert(data); }
                        Navigator.pop(context);
                        _fetchNotices();
                        _showSuccessSnackBar(isEditing ? 'আপডেট হয়েছে' : 'যোগ হয়েছে');
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        _showErrorSnackBar('ত্রুটি ঘটেছে');
                      }
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
          else if (_error != null)
            SliverFillRemaining(child: _buildErrorState())
          else if (_filteredNotices.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              _buildNoticeList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.cyanAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: const Text('নতুন নোটিশ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F2027),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 90),
        title: const Text('বিজ্ঞপ্তি ব্যবস্থাপনা', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 1.2)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topRight, colors: [Color(0xFF0F2027), Color(0xFF2C5364)]),
          ),
          child: Stack(
            children: [
              Positioned(top: -50, right: -50, child: CircleAvatar(radius: 120, backgroundColor: Colors.cyanAccent.withOpacity(0.05))),
              const Center(child: Opacity(opacity: 0.05, child: Icon(Icons.campaign_rounded, size: 150, color: Colors.white))),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'বিজ্ঞপ্তি খুঁজুন...',
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final notice = _filteredNotices[index];
            return FadeTransition(
              opacity: _animationController,
              child: _buildNoticeCard(notice, index),
            );
          },
          childCount: _filteredNotices.length,
        ),
      ),
    );
  }

  Widget _buildNoticeCard(Notice notice, int index) {
    final isNew = DateTime.now().difference(notice.publishDate).inDays < 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(height: 5, decoration: BoxDecoration(
            gradient: LinearGradient(colors: index % 2 == 0 ? [Colors.cyanAccent, Colors.blue] : [Colors.purpleAccent, Colors.pink]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          )),
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: CircleAvatar(backgroundColor: Colors.white10, child: Text('${index + 1}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
            title: Text(notice.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                const SizedBox(width: 5),
                Text(_formatDate(notice.publishDate), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                if (isNew) ...[const SizedBox(width: 10), _cardBadge('NEW', Colors.redAccent)],
                if (notice.pdfUrl != null) ...[const SizedBox(width: 10), _cardBadge('PDF', Colors.blueAccent)],
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.black12, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(onPressed: () => _showAddEditDialog(notice: notice), icon: const Icon(Icons.edit_note, color: Colors.cyanAccent), label: const Text('এডিট', style: TextStyle(color: Colors.cyanAccent))),
              TextButton.icon(onPressed: () => _deleteNotice(notice), icon: const Icon(Icons.delete_outline, color: Colors.redAccent), label: const Text('ডিলিট', style: TextStyle(color: Colors.redAccent))),
            ]),
          )
        ],
      ),
    );
  }

  // --- Helper Methods ---
  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)));

  InputDecoration _glassInputDecoration(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
    filled: true, fillColor: Colors.black26,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.cyanAccent, width: 1)),
  );

  Widget _buildDatePickerField(BuildContext context, DateTime date, Function(DateTime) onPick) => InkWell(
    onTap: () async {
      final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
      if (picked != null) onPick(picked);
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [const Icon(Icons.calendar_month, color: Colors.cyanAccent, size: 20), const SizedBox(width: 12), Text(_formatDate(date), style: const TextStyle(color: Colors.white))]),
    ),
  );

  Widget _buildFileSection(PlatformFile? file, String? url, StateSetter setDialogState) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
    child: Column(children: [
      if (file != null || url != null) Text(file?.name ?? 'PDF Attached', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
      TextButton.icon(onPressed: () async {
        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
        if (result != null) setDialogState(() => file = result.files.first);
      }, icon: const Icon(Icons.upload_file, color: Colors.white70), label: const Text('SELECT PDF', style: TextStyle(color: Colors.white70))),
    ]),
  );

  Widget _buildDialogActions(BuildContext context, bool loading, bool isEditing, VoidCallback onSave) => Padding(
    padding: const EdgeInsets.all(24),
    child: Row(children: [
      Expanded(child: TextButton(onPressed: loading ? null : () => Navigator.pop(context), child: const Text('বাতিল', style: TextStyle(color: Colors.white38)))),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: ElevatedButton(onPressed: loading ? null : onSave, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(isEditing ? 'আপডেট' : 'যোগ করুন', style: const TextStyle(fontWeight: FontWeight.bold)))),
    ]),
  );

  Widget _cardBadge(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5), border: Border.all(color: color.withOpacity(0.3))), child: Text(text, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)));
  Widget _buildErrorState() => Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
  Widget _buildEmptyState() => const Center(child: Text('কোনো বিজ্ঞপ্তি নেই', style: TextStyle(color: Colors.white24)));
  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
  void _showLoadingDialog() => showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
  void _showSuccessSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.cyanAccent.shade700, behavior: SnackBarBehavior.floating));
  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));

  Future<bool> _showDeleteConfirmation(String title) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Text('Delete?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "$title"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    ) ?? false;
  }
}