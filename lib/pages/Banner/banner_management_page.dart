import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/services/banner_service.dart';
import 'package:css/models/banner_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class BannerManagementPage extends StatefulWidget {
  const BannerManagementPage({super.key});
  @override
  State<BannerManagementPage> createState() => _BannerManagementPageState();
}

class _BannerManagementPageState extends State<BannerManagementPage>
    with SingleTickerProviderStateMixin {
  final _service = BannerService();
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
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
      setState(() => _banners = data);
      _animationController.forward(from: 0);
    } catch (e) {
      SC.toast(context, SC.tr('bannerLoadFail'), SC.red);
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
      if (mounted) Navigator.pop(context);
      _showAddEditDialog(imageUrl: imageUrl);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      SC.toast(context, SC.tr('bannerUploadFail'), SC.red);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────
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
    final isDark     = SC.isDark;
    final bgColor    = isDark ? const Color(0xFF0F2027) : const Color(0xFFF0F4FF);
    final cardColor  = isDark ? Colors.white.withOpacity(0.03) : Colors.white;
    final borderC    = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.08);
    final textColor  = isDark ? Colors.white : const Color(0xFF1A2332);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(isDark, textColor),
            if (_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: isDark ? Colors.cyanAccent : SC.cyan),
                ),
              )
            else if (_banners.isEmpty)
              SliverFillRemaining(child: _buildEmptyState(isDark))
            else
              _buildBannerList(isDark, cardColor, borderC, textColor),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _pickAndAddBanner,
          backgroundColor: isDark ? Colors.cyanAccent : SC.cyan,
          icon: Icon(Icons.add_photo_alternate_rounded,
              color: isDark ? Colors.black : Colors.white),
          label: Text(SC.tr('bannerNew'),
              style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, Color textColor) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0F2027) : const Color(0xFFF0F4FF),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 20),
        title: Text(SC.tr('bannerPageTitle'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: textColor,
                letterSpacing: 1.2)),
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                begin: Alignment.topRight,
                colors: [Color(0xFF0F2027), Color(0xFF2C5364)])
                : LinearGradient(
                begin: Alignment.topRight,
                colors: [const Color(0xFFE8F4FD), const Color(0xFFF0F4FF)]),
          ),
          child: Stack(children: [
            Positioned(
              top: -50, right: -50,
              child: CircleAvatar(
                radius: 120,
                backgroundColor: (isDark ? Colors.cyanAccent : SC.cyan)
                    .withOpacity(0.05),
              ),
            ),
            Center(
              child: Opacity(
                opacity: 0.05,
                child: Icon(Icons.art_track_rounded,
                    size: 150,
                    color: isDark ? Colors.white : const Color(0xFF1A2332)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBannerList(
      bool isDark, Color cardColor, Color borderC, Color textColor) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final banner = _banners[index];
            return FadeTransition(
              opacity: _animationController,
              child: _buildBannerCard(
                  banner, index, isDark, cardColor, borderC, textColor),
            );
          },
          childCount: _banners.length,
        ),
      ),
    );
  }

  Widget _buildBannerCard(BannerModel banner, int index, bool isDark,
      Color cardColor, Color borderC, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderC),
        boxShadow: isDark
            ? []
            : [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Image.network(
            banner.imageUrl,
            height: 150, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(
              height: 150,
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              child: Icon(Icons.broken_image,
                  color: isDark ? Colors.white24 : Colors.grey.shade400),
            ),
          ),
        ),
        ListTile(
          title: Text(banner.title ?? 'No Title',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          subtitle: Text(
            'Order: ${banner.sortOrder} • ${banner.isActive ? "Active" : "Inactive"}',
            style: TextStyle(
                color: banner.isActive
                    ? (isDark ? Colors.cyanAccent : SC.cyan)
                    : (isDark ? Colors.white38 : Colors.grey),
                fontSize: 12),
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: Icon(
                banner.isActive ? Icons.visibility : Icons.visibility_off,
                color: banner.isActive ? Colors.greenAccent : (isDark ? Colors.white24 : Colors.grey),
              ),
              onPressed: () => _toggleStatus(banner),
            ),
            IconButton(
              icon: Icon(Icons.edit_note,
                  color: isDark ? Colors.cyanAccent : SC.cyan),
              onPressed: () => _showAddEditDialog(banner: banner),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteBanner(banner),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────
  void _showAddEditDialog({String? imageUrl, BannerModel? banner}) {
    final isDark       = SC.isDark;
    final titleCtrl    = TextEditingController(text: banner?.title);
    final subtitleCtrl = TextEditingController(text: banner?.subtitle);
    final linkCtrl     = TextEditingController(text: banner?.linkUrl);
    final sortCtrl     = TextEditingController(
        text: banner?.sortOrder.toString() ?? '0');
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
                  gradient: isDark
                      ? const LinearGradient(
                      colors: [Color(0xFF0F2027), Color(0xFF2C5364)])
                      : LinearGradient(colors: [
                    Colors.white,
                    const Color(0xFFF0F4FF)
                  ]),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _buildDialogHeader(
                      banner == null
                          ? SC.tr('bannerAddTitle')
                          : SC.tr('bannerEditTitle'),
                      Icons.add_to_photos_rounded,
                      isDark),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null || banner != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                  imageUrl ?? banner!.imageUrl,
                                  height: 120, width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                          const SizedBox(height: 20),
                          _buildLabel(SC.tr('bannerTitleLabel'), isDark),
                          TextField(
                            controller: titleCtrl,
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A2332)),
                            decoration: _glassInputDecoration(
                                SC.tr('bannerTitleHint'), isDark),
                          ),
                          const SizedBox(height: 15),
                          _buildLabel(SC.tr('bannerSubtitleLabel'), isDark),
                          TextField(
                            controller: subtitleCtrl,
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A2332)),
                            decoration: _glassInputDecoration(
                                SC.tr('bannerSubtitleHint'), isDark),
                          ),
                          const SizedBox(height: 15),
                          _buildLabel(SC.tr('bannerLinkLabel'), isDark),
                          TextField(
                            controller: linkCtrl,
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A2332)),
                            decoration: _glassInputDecoration('https://...', isDark),
                          ),
                          const SizedBox(height: 15),
                          _buildLabel(SC.tr('bannerSortLabel'), isDark),
                          TextField(
                            controller: sortCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A2332)),
                            decoration: _glassInputDecoration('0', isDark),
                          ),
                          if (isSaving) ...[
                            const SizedBox(height: 20),
                            LinearProgressIndicator(
                                color: isDark ? Colors.cyanAccent : SC.cyan),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _buildDialogActions(context, isSaving, banner != null,
                      isDark, () async {
                        setDialogState(() => isSaving = true);
                        try {
                          if (banner == null) {
                            await _service.createBanner(
                              imageUrl:  imageUrl!,
                              title:     titleCtrl.text.isEmpty ? null : titleCtrl.text,
                              subtitle:  subtitleCtrl.text.isEmpty ? null : subtitleCtrl.text,
                              linkUrl:   linkCtrl.text.isEmpty ? null : linkCtrl.text,
                              sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                            );
                          } else {
                            await _service.updateBanner(banner.copyWith(
                              title:     titleCtrl.text,
                              subtitle:  subtitleCtrl.text,
                              linkUrl:   linkCtrl.text,
                              sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                            ));
                          }
                          if (mounted) Navigator.pop(context);
                          _loadBanners();
                          SC.toast(
                              context,
                              banner == null
                                  ? SC.tr('bannerCreated')
                                  : SC.tr('bannerUpdated'),
                              SC.green);
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          SC.toast(context, SC.tr('bannerSaveFail'), SC.red);
                        }
                      }),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(String title, IconData icon, bool isDark) =>
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF1CB5E0), Color(0xFF000046)])),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ]),
      );

  InputDecoration _glassInputDecoration(String hint, bool isDark) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.3)),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
                color: isDark ? Colors.cyanAccent : SC.cyan, width: 1)),
      );

  Widget _buildLabel(String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text,
        style: TextStyle(
            color: isDark
                ? Colors.white38
                : Colors.black.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5)),
  );

  Widget _buildDialogActions(BuildContext context, bool loading, bool isEdit,
      bool isDark, VoidCallback onSave) =>
      Padding(
        padding: const EdgeInsets.all(24),
        child: Row(children: [
          Expanded(
            child: TextButton(
              onPressed: loading ? null : () => Navigator.pop(context),
              child: Text(SC.tr('bannerCancel'),
                  style: TextStyle(
                      color: isDark
                          ? Colors.white38
                          : Colors.black.withOpacity(0.4))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: loading ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.cyanAccent : SC.cyan,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isEdit ? SC.tr('bannerUpdate') : SC.tr('bannerAdd'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ]),
      );

  Future<void> _toggleStatus(BannerModel banner) async {
    try {
      await _service.toggleBannerStatus(banner.id, !banner.isActive);
      _loadBanners();
    } catch (e) {
      SC.toast(context, SC.tr('bannerStatusFail'), SC.red);
    }
  }

  Future<void> _deleteBanner(BannerModel banner) async {
    final isDark = SC.isDark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xFF1B2A6B) : Colors.white,
        title: Text(SC.tr('bannerDeleteTitle'),
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1A2332))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(SC.tr('bannerCancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(SC.tr('bannerDeleteConfirm'),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deleteBanner(banner.id, banner.imageUrl);
        _loadBanners();
        SC.toast(context, SC.tr('bannerDeleted'), SC.green);
      } catch (e) {
        SC.toast(context, SC.tr('bannerDeleteFail'), SC.red);
      }
    }
  }

  void _showLoadingDialog() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: CircularProgressIndicator(
          color: SC.isDark ? Colors.cyanAccent : SC.cyan),
    ),
  );

  Widget _buildEmptyState(bool isDark) => Center(
    child: Text(SC.tr('bannerEmpty'),
        style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26)),
  );
}