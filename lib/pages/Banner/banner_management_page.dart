import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:css/services/banner_service.dart';
import 'package:css/models/banner_model.dart';

class BannerManagementPage extends StatefulWidget {
  const BannerManagementPage({super.key});

  @override
  State<BannerManagementPage> createState() => _BannerManagementPageState();
}

class _BannerManagementPageState extends State<BannerManagementPage> with SingleTickerProviderStateMixin {
  final _service = BannerService();
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadBanners();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _service.fetchAllBanners();
      setState(() {
        _banners = data;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      _showErrorSnackBar('ব্যানার লোড করতে সমস্যা হয়েছে');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndAddBanner() async {
    final image = await _service.pickImage();
    if (image == null) return;

    _showLoadingDialog();

    try {
      final imageUrl = await _service.uploadBannerImage(image);
      Navigator.pop(context); // লোডিং বন্ধ করুন
      _showAddEditDialog(imageUrl: imageUrl);
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('ইমেজ আপলোড ব্যর্থ হয়েছে');
    }
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
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
          else if (_banners.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            _buildBannerList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndAddBanner,
        backgroundColor: Colors.cyanAccent,
        icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.black),
        label: const Text('নতুন ব্যানার', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        titlePadding: const EdgeInsets.only(bottom: 20),
        title: const Text('ব্যানার ব্যবস্থাপনা',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 1.2)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topRight, colors: [Color(0xFF0F2027), Color(0xFF2C5364)]),
          ),
          child: Stack(
            children: [
              Positioned(top: -50, right: -50, child: CircleAvatar(radius: 120, backgroundColor: Colors.cyanAccent.withOpacity(0.05))),
              const Center(child: Opacity(opacity: 0.05, child: Icon(Icons.art_track_rounded, size: 150, color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final banner = _banners[index];
            return FadeTransition(
              opacity: _animationController,
              child: _buildBannerCard(banner, index),
            );
          },
          childCount: _banners.length,
        ),
      ),
    );
  }

  Widget _buildBannerCard(BannerModel banner, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              banner.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(height: 150, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)),
            ),
          ),
          ListTile(
            title: Text(banner.title ?? 'No Title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Order: ${banner.sortOrder} • ${banner.isActive ? "Active" : "Inactive"}',
                style: TextStyle(color: banner.isActive ? Colors.cyanAccent : Colors.white38, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(banner.isActive ? Icons.visibility : Icons.visibility_off, color: banner.isActive ? Colors.greenAccent : Colors.white24),
                  onPressed: () => _toggleStatus(banner),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.cyanAccent),
                  onPressed: () => _showAddEditDialog(banner: banner),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteBanner(banner),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Dialogs ---

  void _showAddEditDialog({String? imageUrl, BannerModel? banner}) {
    final titleCtrl = TextEditingController(text: banner?.title);
    final subtitleCtrl = TextEditingController(text: banner?.subtitle);
    final linkCtrl = TextEditingController(text: banner?.linkUrl);
    final sortCtrl = TextEditingController(text: banner?.sortOrder.toString() ?? '0');
    bool isSaving = false;

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
                  gradient: const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF2C5364)]),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogHeader(banner == null ? 'নতুন ব্যানার' : 'ব্যানার এডিট', Icons.add_to_photos_rounded),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl != null || banner != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(imageUrl ?? banner!.imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
                              ),
                            const SizedBox(height: 20),
                            _buildLabel('ব্যানার শিরোনাম'),
                            TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: _glassInputDecoration('শিরোনাম লিখুন...')),
                            const SizedBox(height: 15),
                            _buildLabel('সাব-টাইটেল (ঐচ্ছিক)'),
                            TextField(controller: subtitleCtrl, style: const TextStyle(color: Colors.white), decoration: _glassInputDecoration('বিস্তারিত তথ্য...')),
                            const SizedBox(height: 15),
                            _buildLabel('লিঙ্ক URL (ঐচ্ছিক)'),
                            TextField(controller: linkCtrl, style: const TextStyle(color: Colors.white), decoration: _glassInputDecoration('https://...')),
                            const SizedBox(height: 15),
                            _buildLabel('ক্রমিক নম্বর'),
                            TextField(controller: sortCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _glassInputDecoration('0')),
                            if (isSaving) ...[const SizedBox(height: 20), const LinearProgressIndicator(color: Colors.cyanAccent)]
                          ],
                        ),
                      ),
                    ),
                    _buildDialogActions(context, isSaving, banner != null, () async {
                      setDialogState(() => isSaving = true);
                      try {
                        if (banner == null) {
                          await _service.createBanner(
                            imageUrl: imageUrl!,
                            title: titleCtrl.text.isEmpty ? null : titleCtrl.text,
                            subtitle: subtitleCtrl.text.isEmpty ? null : subtitleCtrl.text,
                            linkUrl: linkCtrl.text.isEmpty ? null : linkCtrl.text,
                            sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                          );
                        } else {
                          await _service.updateBanner(banner.copyWith(
                            title: titleCtrl.text,
                            subtitle: subtitleCtrl.text,
                            linkUrl: linkCtrl.text,
                            sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                          ));
                        }
                        Navigator.pop(context);
                        _loadBanners();
                        _showSuccessSnackBar(banner == null ? 'ব্যানার তৈরি হয়েছে' : 'ব্যানার আপডেট হয়েছে');
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        _showErrorSnackBar('সংরক্ষণ করতে সমস্যা হয়েছে');
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

  // --- Helpers ---

  Widget _buildDialogHeader(String title, IconData icon) => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1CB5E0), Color(0xFF000046)])),
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

  InputDecoration _glassInputDecoration(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
    filled: true, fillColor: Colors.black26,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.cyanAccent, width: 1)),
  );

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)));

  Widget _buildDialogActions(BuildContext context, bool loading, bool isEdit, VoidCallback onSave) => Padding(
    padding: const EdgeInsets.all(24),
    child: Row(children: [
      Expanded(child: TextButton(onPressed: loading ? null : () => Navigator.pop(context), child: const Text('বাতিল', style: TextStyle(color: Colors.white38)))),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: ElevatedButton(onPressed: loading ? null : onSave, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(isEdit ? 'আপডেট' : 'যোগ করুন', style: const TextStyle(fontWeight: FontWeight.bold)))),
    ]),
  );

  Future<void> _toggleStatus(BannerModel banner) async {
    try {
      await _service.toggleBannerStatus(banner.id, !banner.isActive);
      _loadBanners();
    } catch (e) { _showErrorSnackBar('স্ট্যাটাস আপডেট ব্যর্থ'); }
  }

  Future<void> _deleteBanner(BannerModel banner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Text('মুছে ফেলবেন?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ডিলিট', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deleteBanner(banner.id, banner.imageUrl);
        _loadBanners();
        _showSuccessSnackBar('ব্যানার মুছে ফেলা হয়েছে');
      } catch (e) { _showErrorSnackBar('মুছতে সমস্যা হয়েছে'); }
    }
  }

  void _showLoadingDialog() => showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
  void _showSuccessSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.cyanAccent.shade700, behavior: SnackBarBehavior.floating));
  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
  Widget _buildEmptyState() => const Center(child: Text('কোনো ব্যানার পাওয়া যায়নি', style: TextStyle(color: Colors.white24)));
}