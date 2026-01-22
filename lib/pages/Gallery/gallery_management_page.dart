import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // তারিখ ফরম্যাট করার জন্য যুক্ত করা হয়েছে
import 'package:css/models/gallery_image_model.dart';
import 'package:css/services/gallery_service.dart';

class GalleryManagementPage extends StatefulWidget {
  const GalleryManagementPage({super.key});

  @override
  State<GalleryManagementPage> createState() => _GalleryManagementPageState();
}

class _GalleryManagementPageState extends State<GalleryManagementPage> with SingleTickerProviderStateMixin {
  final _galleryService = GalleryService();
  bool _loading = true;
  List<GalleryImage> _images = [];
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
    _loadImages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<GalleryImage> get _filteredImages {
    if (_searchQuery.isEmpty) return _images;
    return _images.where((img) {
      final categoryMatch = img.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final titleMatch = img.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return categoryMatch || titleMatch;
    }).toList();
  }

  Future<void> _loadImages() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final images = await _galleryService.fetchGallery();
      _images = images;
      _animationController.forward(from: 0);
    } catch (e) {
      _error = 'গ্যালারি লোড করতে সমস্যা হয়েছে';
    }

    if (mounted) setState(() => _loading = false);
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
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
          else if (_error != null)
            SliverFillRemaining(child: _buildErrorState())
          else if (_filteredImages.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              _buildGalleryGrid(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        backgroundColor: Colors.cyanAccent,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.black),
        label: const Text('নতুন ছবি', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: const Text('গ্যালারি ব্যবস্থাপনা',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 1.2)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                colors: [Color(0xFF0F2027), Color(0xFF2C5364)]
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -50, right: -50, child: CircleAvatar(radius: 120, backgroundColor: Colors.cyanAccent.withOpacity(0.05))),
              const Center(child: Opacity(opacity: 0.05, child: Icon(Icons.photo_library_rounded, size: 150, color: Colors.white))),
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
              hintText: 'ক্যাটাগরি বা শিরোনাম খুঁজুন...',
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

  Widget _buildGalleryGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.68, // তারিখ যোগ করার কারণে একটু বাড়ানো হয়েছে
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final image = _filteredImages[index];
            return FadeTransition(
              opacity: _animationController,
              child: _buildImageCard(image, index),
            );
          },
          childCount: _filteredImages.length,
        ),
      ),
    );
  }

  Widget _buildImageCard(GalleryImage image, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: CachedNetworkImage(
                imageUrl: image.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.redAccent),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      image.category,
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    // তারিখ প্রদর্শনী
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 10, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yy').format(image.createdAt),
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (image.title != null)
                  Text(
                    image.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => _deleteImage(image),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    final titleCtrl = TextEditingController();
    String selectedCat = 'ইভেন্ট';
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
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
                  ),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogHeader('নতুন ছবি যোগ করুন', Icons.add_photo_alternate_outlined),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('ক্যাটাগরি নির্বাচন করুন'),
                            _buildGlassDropdown(selectedCat, (val) => setDialogState(() => selectedCat = val!)),
                            const SizedBox(height: 20),
                            _buildLabel('শিরোনাম (ঐচ্ছিক)'),
                            TextField(
                              controller: titleCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: _glassInputDecoration('ছবির শিরোনাম এখানে লিখুন...'),
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('ছবি নির্বাচন'),

                            InkWell(
                              onTap: isUploading ? null : () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  withData: true,
                                );
                                if (result != null && result.files.isNotEmpty) {
                                  setDialogState(() {
                                    selectedFile = result.files.first;
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.white10, style: BorderStyle.solid)
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.cloud_upload_outlined,
                                        color: selectedFile != null ? Colors.cyanAccent : Colors.white38,
                                        size: 30),
                                    const SizedBox(height: 10),
                                    Text(selectedFile?.name ?? 'ছবি নির্বাচন করুন',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: selectedFile != null ? Colors.white : Colors.white38, fontSize: 12)
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (isUploading) ...[
                              const SizedBox(height: 20),
                              const LinearProgressIndicator(color: Colors.cyanAccent, backgroundColor: Colors.white10),
                            ]
                          ],
                        ),
                      ),
                    ),
                    _buildDialogActions(context, isUploading, () async {
                      if (selectedFile == null) {
                        _showErrorSnackBar('একটি ছবি নির্বাচন করুন');
                        return;
                      }
                      setDialogState(() => isUploading = true);
                      try {
                        final url = await _galleryService.uploadImage(selectedFile!);
                        await _galleryService.addImageToGallery(
                          imageUrl: url,
                          category: selectedCat,
                          title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                        );
                        Navigator.pop(context);
                        _loadImages();
                        _showSuccessSnackBar('ছবি সফলভাবে আপলোড হয়েছে');
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        _showErrorSnackBar('আপলোড ব্যর্থ হয়েছে');
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

  Widget _buildDialogHeader(String title, IconData icon) => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF1CB5E0), Color(0xFF000046)]),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const Spacer(),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
      ],
    ),
  );

  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5))
  );

  InputDecoration _glassInputDecoration(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
    filled: true, fillColor: Colors.black26,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.cyanAccent, width: 1)),
  );

  Widget _buildGlassDropdown(String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF2C5364),
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white),
        items: ['ইভেন্ট', 'সেমিনার', 'কর্মশালা', 'প্রোগ্রাম'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDialogActions(BuildContext context, bool loading, VoidCallback onSave) => Padding(
    padding: const EdgeInsets.all(24),
    child: Row(children: [
      Expanded(child: TextButton(onPressed: loading ? null : () => Navigator.pop(context), child: const Text('বাতিল', style: TextStyle(color: Colors.white38)))),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: ElevatedButton(onPressed: loading ? null : onSave, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('আপলোড করুন', style: TextStyle(fontWeight: FontWeight.bold)))),
    ]),
  );

  Future<void> _deleteImage(GalleryImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Text('মুছে ফেলবেন?', style: TextStyle(color: Colors.white)),
        content: const Text('আপনি কি নিশ্চিত যে এই ছবিটি মুছে ফেলতে চান?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('মুছুন', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      try {
        await _galleryService.deleteImage(image.id, image.imageUrl);
        _loadImages();
        _showSuccessSnackBar('ছবি মুছে ফেলা হয়েছে');
      } catch (e) {
        _showErrorSnackBar('মুছতে ব্যর্থ হয়েছে');
      }
    }
  }

  Widget _buildErrorState() => Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
  Widget _buildEmptyState() => const Center(child: Text('কোনো ছবি পাওয়া যায়নি', style: TextStyle(color: Colors.white24)));
  void _showSuccessSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.cyanAccent.shade700, behavior: SnackBarBehavior.floating));
  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
}