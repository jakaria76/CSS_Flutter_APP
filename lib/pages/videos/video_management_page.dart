import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/services/video_service.dart';
import 'package:css/models/video_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class VideoManagementPage extends StatefulWidget {
  const VideoManagementPage({super.key});

  @override
  State<VideoManagementPage> createState() => _VideoManagementPageState();
}

class _VideoManagementPageState extends State<VideoManagementPage>
    with SingleTickerProviderStateMixin {
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
      SC.toast(context, 'Error: $e', SC.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Video> get _filteredVideos {
    if (_searchQuery.isEmpty) return videos;
    return videos
        .where((v) =>
        v.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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
    final bgColor = isDark ? SC.bgStart : const Color(0xFFF0F4FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(isDark, textColor),
            if (isLoading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: SC.cyan),
                ),
              )
            else if (_filteredVideos.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(textColor))
            else
              _buildVideoList(isDark, textColor),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(isDark: isDark),
          backgroundColor: SC.cyan,
          icon: const Icon(Icons.video_call_rounded, color: Colors.black),
          label: Text(
            SC.tr('newVideo'),
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, Color textColor) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? SC.bgStart : const Color(0xFFF0F4FF),
      leading: _buildBackButton(isDark, textColor),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 90),
        title: Text(
          SC.tr('videoManagement'),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textColor,
            letterSpacing: 1.2,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(gradient: SC.currentGradient),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: CircleAvatar(
                  radius: 120,
                  backgroundColor: SC.cyan.withValues(alpha: 0.05),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.video_library_rounded,
                      size: 150, color: textColor),
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
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: SC.tr('searchVideo'),
              hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.35)),
              prefixIcon: Icon(Icons.search, color: SC.cyan),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: SC.cyan.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(bool isDark, Color textColor) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
      ),
    );
  }

  Widget _buildVideoList(bool isDark, Color textColor) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final v = _filteredVideos[index];
            return FadeTransition(
              opacity: _animationController,
              child: _buildVideoCard(v, index, isDark, textColor),
            );
          },
          childCount: _filteredVideos.length,
        ),
      ),
    );
  }

  Widget _buildVideoCard(
      Video v, int index, bool isDark, Color textColor) {
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.07);
    final subTextColor =
    isDark ? Colors.white38 : const Color(0xFF4A5568).withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: index % 2 == 0
                    ? [SC.cyan, SC.blue]
                    : [SC.purple, SC.red],
              ),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: CircleAvatar(
              backgroundColor: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              child: Icon(
                Icons.play_circle_fill,
                color: v.isActive ? SC.cyan : subTextColor,
              ),
            ),
            title: Text(
              v.title,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            subtitle: Text(
              v.youtubeUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black12
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    v.isActive ? Icons.visibility : Icons.visibility_off,
                    color: v.isActive ? SC.green : subTextColor,
                    size: 20,
                  ),
                  onPressed: () => _toggleActive(v),
                ),
                IconButton(
                  icon: Icon(Icons.edit_note, color: SC.cyan, size: 20),
                  onPressed: () =>
                      _showAddEditDialog(video: v, isDark: isDark),
                ),
                IconButton(
                  icon:
                  Icon(Icons.delete_outline, color: SC.red, size: 20),
                  onPressed: () => _deleteVideo(v, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────

  void _showAddEditDialog({Video? video, required bool isDark}) {
    final titleCtrl = TextEditingController(text: video?.title);
    final urlCtrl = TextEditingController(text: video?.youtubeUrl);
    final sortCtrl = TextEditingController(
        text: video?.sortOrder.toString() ?? videos.length.toString());
    bool isSaving = false;

    final dialogBg = isDark ? SC.cardBg : Colors.white;
    final labelColor = isDark
        ? Colors.white38
        : const Color(0xFF4A5568).withValues(alpha: 0.6);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: dialogBg,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogHeader(
                      video == null
                          ? SC.tr('addVideo')
                          : SC.tr('editVideo'),
                      Icons.video_collection_outlined,
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(SC.tr('videoTitle'), labelColor),
                            TextField(
                              controller: titleCtrl,
                              style: TextStyle(color: textColor),
                              decoration: _inputDecoration(
                                SC.tr('videoTitleHint'),
                                isDark,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildLabel(SC.tr('youtubeUrl'), labelColor),
                            TextField(
                              controller: urlCtrl,
                              style: TextStyle(color: textColor),
                              decoration: _inputDecoration(
                                  'https://youtube.com/...', isDark),
                            ),
                            const SizedBox(height: 20),
                            _buildLabel(SC.tr('sortOrder'), labelColor),
                            TextField(
                              controller: sortCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor),
                              decoration: _inputDecoration('0', isDark),
                            ),
                            if (isSaving) ...[
                              const SizedBox(height: 20),
                              LinearProgressIndicator(
                                color: SC.cyan,
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.08),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _buildDialogActions(context, isSaving, video != null,
                        isDark, () async {
                          if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty) {
                            SC.toast(context, SC.tr('fillAllFields'), SC.red);
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          try {
                            if (video == null) {
                              await service.addVideo(
                                title: titleCtrl.text,
                                youtubeUrl: urlCtrl.text,
                                sortOrder:
                                int.tryParse(sortCtrl.text) ?? 0,
                              );
                            } else {
                              await service.updateVideo(
                                id: video.id,
                                title: titleCtrl.text,
                                youtubeUrl: urlCtrl.text,
                                sortOrder: int.tryParse(sortCtrl.text),
                              );
                            }
                            Navigator.pop(context);
                            loadVideos();
                            SC.toast(
                              context,
                              video == null
                                  ? SC.tr('videoAdded')
                                  : SC.tr('videoUpdated'),
                              SC.green,
                            );
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            SC.toast(context, SC.tr('errorOccurred'), SC.red);
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
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [SC.cyan, SC.blue]),
      borderRadius:
      const BorderRadius.vertical(top: Radius.circular(35)),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white70),
        ),
      ],
    ),
  );

  InputDecoration _inputDecoration(String hint, bool isDark) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.black26
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: SC.cyan, width: 1),
        ),
      );

  Widget _buildLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5),
    ),
  );

  Widget _buildDialogActions(BuildContext context, bool loading,
      bool isEdit, bool isDark, VoidCallback onSave) =>
      Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: Text(
                  SC.tr('cancelBtn'),
                  style: TextStyle(
                    color: isDark
                        ? Colors.white38
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: loading ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SC.cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEdit ? SC.tr('updateBtn') : SC.tr('addBtn'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _deleteVideo(Video v, bool isDark) async {
    final textColor =
    isDark ? Colors.white : const Color(0xFF1A2332);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? SC.cardBg : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(SC.tr('deleteVideoConfirm'),
            style: TextStyle(color: textColor)),
        content: Text(
          SC.tr('deleteVideoMsg'),
          style: TextStyle(
              color: textColor.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(SC.tr('cancelBtn')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(SC.tr('deleteBtn'),
                style: TextStyle(color: SC.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await service.deleteVideo(v.id);
        SC.toast(context, SC.tr('videoDeleted'), SC.green);
        loadVideos();
      } catch (e) {
        SC.toast(context, SC.tr('deleteFailed'), SC.red);
      }
    }
  }

  Future<void> _toggleActive(Video v) async {
    try {
      await service.toggleActive(v.id, v.isActive);
      loadVideos();
    } catch (e) {
      SC.toast(context, SC.tr('updateFailed'), SC.red);
    }
  }

  Widget _buildEmptyState(Color textColor) => Center(
    child: Text(
      SC.tr('noVideoFound'),
      style: TextStyle(
          color: textColor.withValues(alpha: 0.3), fontSize: 16),
    ),
  );
}