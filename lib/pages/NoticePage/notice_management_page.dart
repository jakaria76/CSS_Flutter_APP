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

class _NoticeManagementPageState extends State<NoticeManagementPage>
    with SingleTickerProviderStateMixin {
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
      debugPrint('Fetch error: $e');
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
          final fileName = notice.pdfUrl!.split('/').last.split('?').first;
          await _supabase.storage.from('notice-pdfs').remove([fileName]);
        } catch (e) {
          debugPrint('File deletion error: $e');
        }
      }

      await _supabase.from('notices').delete().eq('id', notice.id);

      if (mounted) {
        Navigator.pop(context);
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

  Future<String?> _uploadFileToSupabase(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) {
        _showErrorSnackBar('ফাইল পড়া যায়নি');
        return null;
      }

      // Clean filename: remove special characters and Bangla characters
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? 'pdf';
      final cleanName = file.name
          .replaceAll(RegExp(r'[^\w\s.-]'), '') // Remove special chars
          .replaceAll(' ', '_') // Replace spaces
          .replaceAll(RegExp(r'[^\x00-\x7F]'), ''); // Remove non-ASCII (Bangla)

      final fileName = cleanName.isEmpty
          ? '$timestamp.$extension'
          : '${timestamp}_$cleanName';

      // Get content type based on extension
      String contentType;
      switch (extension.toLowerCase()) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
        case 'docx':
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'txt':
          contentType = 'text/plain';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      debugPrint('Uploading: $fileName (${bytes.length} bytes)');

      // Upload without 'documents/' prefix
      await _supabase.storage.from('notice-pdfs').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      final url = _supabase.storage.from('notice-pdfs').getPublicUrl(fileName);
      debugPrint('Upload successful: $url');
      return url;
    } catch (e) {
      debugPrint('Upload error: $e');
      _showErrorSnackBar('ফাইল আপলোড ব্যর্থ: $e');
      return null;
    }
  }

  void _showAddEditDialog({Notice? notice}) {
    final isEditing = notice != null;
    final titleCtrl = TextEditingController(text: notice?.title ?? '');
    DateTime selectedDate = notice?.publishDate ?? DateTime.now();
    String? uploadedFileUrl = notice?.pdfUrl;
    PlatformFile? selectedFile;
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
                constraints: const BoxConstraints(maxWidth: 550),
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
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1CB5E0), Color(0xFF000046)],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEditing ? Icons.edit_note : Icons.add_circle_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEditing ? 'বিজ্ঞপ্তি সম্পাদনা' : 'নতুন বিজ্ঞপ্তি',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white70),
                          ),
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
                            _buildDatePickerField(
                              context,
                              selectedDate,
                                  (date) => setDialogState(() => selectedDate = date),
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('সংযুক্ত ডকুমেন্ট'),
                            _buildFileSection(
                              selectedFile,
                              uploadedFileUrl,
                                  (file) {
                                setDialogState(() {
                                  selectedFile = file;
                                  if (file == null) uploadedFileUrl = null;
                                });
                              },
                            ),
                            if (isUploading) ...[
                              const SizedBox(height: 20),
                              const LinearProgressIndicator(
                                color: Colors.cyanAccent,
                                backgroundColor: Colors.white10,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'আপলোড হচ্ছে...',
                                style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    _buildDialogActions(
                      context,
                      isUploading,
                      isEditing,
                          () async {
                        if (titleCtrl.text.isEmpty) {
                          _showErrorSnackBar('শিরোনাম লিখুন');
                          return;
                        }

                        setDialogState(() => isUploading = true);

                        try {
                          String? finalFileUrl = uploadedFileUrl;

                          if (selectedFile != null) {
                            finalFileUrl = await _uploadFileToSupabase(selectedFile!);
                            if (finalFileUrl == null) {
                              setDialogState(() => isUploading = false);
                              return;
                            }
                          }

                          final data = {
                            'title': titleCtrl.text.trim(),
                            'publish_date': selectedDate.toIso8601String(),
                            'pdf_url': finalFileUrl,
                          };

                          if (isEditing) {
                            await _supabase
                                .from('notices')
                                .update(data)
                                .eq('id', notice.id);
                          } else {
                            await _supabase.from('notices').insert(data);
                          }

                          Navigator.pop(context);
                          _fetchNotices();
                          _showSuccessSnackBar(isEditing ? 'আপডেট হয়েছে' : 'যোগ হয়েছে');
                        } catch (e) {
                          setDialogState(() => isUploading = false);
                          _showErrorSnackBar('ত্রুটি ঘটেছে: $e');
                          debugPrint('Save error: $e');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
            )
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
        label: const Text(
          'নতুন নোটিশ',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
        title: const Text(
          'বিজ্ঞপ্তি ব্যবস্থাপনা',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: CircleAvatar(
                  radius: 120,
                  backgroundColor: Colors.cyanAccent.withOpacity(0.05),
                ),
              ),
              const Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.campaign_rounded, size: 150, color: Colors.white),
                ),
              ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
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
    final fileExtension = notice.pdfUrl?.split('.').last.split('?').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: index % 2 == 0
                    ? [Colors.cyanAccent, Colors.blue]
                    : [Colors.purpleAccent, Colors.pink],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: CircleAvatar(
              backgroundColor: Colors.white10,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              notice.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                      const SizedBox(width: 5),
                      Text(
                        _formatDate(notice.publishDate),
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                  if (isNew) _cardBadge('NEW', Colors.redAccent),
                  if (notice.pdfUrl != null)
                    _cardBadge(
                      fileExtension.toUpperCase(),
                      _getFileColor(fileExtension),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddEditDialog(notice: notice),
                  icon: const Icon(Icons.edit_note, color: Colors.cyanAccent),
                  label: const Text('এডিট', style: TextStyle(color: Colors.cyanAccent)),
                ),
                TextButton.icon(
                  onPressed: () => _deleteNotice(notice),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text('ডিলিট', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.redAccent;
      case 'doc':
      case 'docx':
        return Colors.blueAccent;
      case 'txt':
        return Colors.greenAccent;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    ),
  );

  InputDecoration _glassInputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
    filled: true,
    fillColor: Colors.black26,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.cyanAccent, width: 1),
    ),
  );

  Widget _buildDatePickerField(
      BuildContext context,
      DateTime date,
      Function(DateTime) onPick,
      ) =>
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) onPick(picked);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 12),
              Text(_formatDate(date), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

  Widget _buildFileSection(
      PlatformFile? file,
      String? url,
      Function(PlatformFile?) onPick,
      ) {
    final fileName = file?.name ?? (url?.split('/').last ?? '');
    final hasFile = file != null || url != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          if (hasFile)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                    onPressed: () => onPick(null),
                  ),
                ],
              ),
            ),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
                withData: true,
              );
              if (result != null && result.files.isNotEmpty) {
                onPick(result.files.first);
              }
            },
            icon: const Icon(Icons.upload_file),
            label: Text(hasFile ? 'CHANGE FILE' : 'SELECT FILE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.2),
              foregroundColor: Colors.cyanAccent,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supported: PDF, DOC, DOCX, TXT, JPG, PNG',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions(
      BuildContext context,
      bool loading,
      bool isEditing,
      VoidCallback onSave,
      ) =>
      Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: const Text('বাতিল', style: TextStyle(color: Colors.white38)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: loading ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? 'আপডেট' : 'যোগ করুন',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _cardBadge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildErrorState() => Center(
    child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
  );

  Widget _buildEmptyState() => const Center(
    child: Text('কোনো বিজ্ঞপ্তি নেই', style: TextStyle(color: Colors.white24)),
  );

  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  void _showLoadingDialog() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: CircularProgressIndicator(color: Colors.cyanAccent),
    ),
  );

  void _showSuccessSnackBar(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: Colors.cyanAccent.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

  void _showErrorSnackBar(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

  Future<bool> _showDeleteConfirmation(String title) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Text('Delete?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$title"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }
}