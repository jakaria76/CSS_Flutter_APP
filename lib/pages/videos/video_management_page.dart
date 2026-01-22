import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:css/services/video_service.dart';
import 'package:css/models/video_model.dart';

class VideoManagementPage extends StatefulWidget {
  const VideoManagementPage({super.key});

  @override
  State<VideoManagementPage> createState() => _VideoManagementPageState();
}

class _VideoManagementPageState extends State<VideoManagementPage> with SingleTickerProviderStateMixin {
  final service = VideoService();
  List<Video> videos = [];
  bool isLoading = true;
  String _searchQuery = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    loadVideos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadVideos() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      videos = await service.fetchVideos(admin: true);
      _animationController.forward(from: 0);
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Video> get _filteredVideos {
    if (_searchQuery.isEmpty) return videos;
    return videos.where((v) => v.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
          if (isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)))
          else if (_filteredVideos.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            _buildVideoList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.cyanAccent,
        icon: const Icon(Icons.video_call_rounded, color: Colors.black),
        label: const Text('নতুন ভিডিও', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: const Text('ভিডিও ব্যবস্থাপনা',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 1.2)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topRight, colors: [Color(0xFF0F2027), Color(0xFF2C5364)]),
          ),
          child: Stack(
            children: [
              Positioned(top: -50, right: -50, child: CircleAvatar(radius: 120, backgroundColor: Colors.cyanAccent.withOpacity(0.05))),
              const Center(child: Opacity(opacity: 0.05, child: Icon(Icons.video_library_rounded, size: 150, color: Colors.white))),
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
              hintText: 'ভিডিও খুঁজুন...',
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

  Widget _buildVideoList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final v = _filteredVideos[index];
            return FadeTransition(
              opacity: _animationController,
              child: _buildVideoCard(v, index),
            );
          },
          childCount: _filteredVideos.length,
        ),
      ),
    );
  }

  Widget _buildVideoCard(Video v, int index) {
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
              gradient: LinearGradient(colors: index % 2 == 0 ? [Colors.cyanAccent, Colors.blue] : [Colors.purpleAccent, Colors.pink]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: CircleAvatar(
              backgroundColor: Colors.white10,
              child: Icon(Icons.play_circle_fill, color: v.isActive ? Colors.cyanAccent : Colors.white24),
            ),
            title: Text(v.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(v.youtubeUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.black12, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(v.isActive ? Icons.visibility : Icons.visibility_off, color: v.isActive ? Colors.greenAccent : Colors.white24, size: 20),
                  onPressed: () => _toggleActive(v),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.cyanAccent, size: 20),
                  onPressed: () => _showAddEditDialog(video: v),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _deleteVideo(v),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- Dialogs & Helpers ---

  void _showAddEditDialog({Video? video}) {
    final titleCtrl = TextEditingController(text: video?.title);
    final urlCtrl = TextEditingController(text: video?.youtubeUrl);
    final sortCtrl = TextEditingController(text: video?.sortOrder.toString() ?? videos.length.toString());
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
                    _buildDialogHeader(video == null ? 'নতুন ভিডিও' : 'ভিডিও এডিট', Icons.video_collection_outlined),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('ভিডিও শিরোনাম'),
                            TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: _glassInputDecoration('শিরোনাম লিখুন...')),
                            const SizedBox(height: 20),
                            _buildLabel('ইউটিউব লিঙ্ক (URL)'),
                            TextField(controller: urlCtrl, style: const TextStyle(color: Colors.white), decoration: _glassInputDecoration('https://youtube.com/...')),
                            const SizedBox(height: 20),
                            _buildLabel('ক্রমিক নম্বর (Sort Order)'),
                            TextField(controller: sortCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _glassInputDecoration('0')),
                            if (isSaving) ...[const SizedBox(height: 20), const LinearProgressIndicator(color: Colors.cyanAccent, backgroundColor: Colors.white10)]
                          ],
                        ),
                      ),
                    ),
                    _buildDialogActions(context, isSaving, video != null, () async {
                      if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty) {
                        _showErrorSnackBar('সবগুলো ঘর পূরণ করুন');
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        if (video == null) {
                          await service.addVideo(title: titleCtrl.text, youtubeUrl: urlCtrl.text, sortOrder: int.tryParse(sortCtrl.text) ?? 0);
                        } else {
                          await service.updateVideo(id: video.id, title: titleCtrl.text, youtubeUrl: urlCtrl.text, sortOrder: int.tryParse(sortCtrl.text));
                        }
                        Navigator.pop(context);
                        loadVideos();
                        _showSuccessSnackBar(video == null ? 'যোগ করা হয়েছে' : 'আপডেট করা হয়েছে');
                      } catch (e) {
                        setDialogState(() => isSaving = false);
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

  Future<void> _deleteVideo(Video v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A6B),
        title: const Text('মুছে ফেলবেন?', style: TextStyle(color: Colors.white)),
        content: Text('আপনি কি নিশ্চিত যে "${v.title}" মুছে ফেলতে চান?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ডিলিট', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await service.deleteVideo(v.id);
        _showSuccessSnackBar('ভিডিও মুছে ফেলা হয়েছে');
        loadVideos();
      } catch (e) {
        _showErrorSnackBar('মুছতে ব্যর্থ হয়েছে');
      }
    }
  }

  Future<void> _toggleActive(Video v) async {
    try {
      await service.toggleActive(v.id, v.isActive);
      loadVideos();
    } catch (e) {
      _showErrorSnackBar('আপডেট ব্যর্থ হয়েছে');
    }
  }

  Widget _buildEmptyState() => const Center(child: Text('কোনো ভিডিও পাওয়া যায়নি', style: TextStyle(color: Colors.white24)));
  void _showSuccessSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.cyanAccent.shade700, behavior: SnackBarBehavior.floating));
  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
}