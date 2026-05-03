import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/gallery_image_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class GalleryPreviewSection extends StatefulWidget {
  final bool isLoading;
  final List<GalleryImage> images;
  final VoidCallback onViewAll;

  const GalleryPreviewSection({
    super.key,
    required this.isLoading,
    required this.images,
    required this.onViewAll,
  });

  @override
  State<GalleryPreviewSection> createState() => _GalleryPreviewSectionState();
}

class _GalleryPreviewSectionState extends State<GalleryPreviewSection> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  List<GalleryImage> get _previewImages => widget.images.take(6).toList();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000, viewportFraction: 0.88);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_previewImages.isEmpty) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoSlide() => _autoSlideTimer?.cancel();

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.cyanAccent, Colors.blueAccent],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                SC.tr('memories_album'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (widget.images.isNotEmpty)
                InkWell(
                  onTap: widget.onViewAll,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SC.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          SC.tr('view_all'),
                          style: TextStyle(
                            color: isDark ? SC.cyan : SC.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: isDark ? SC.cyan : SC.blue,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.isLoading)
          _buildLoadingState()
        else if (_previewImages.isEmpty)
          _buildEmptyState()
        else
          _buildSlider(),
        if (!widget.isLoading && _previewImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDotIndicators(),
        ],
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        physics: const NeverScrollableScrollPhysics(),
        controller: PageController(viewportFraction: 0.88),
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            decoration: BoxDecoration(
              color: (SC.isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: SizedBox(
                width: 26, height: 26,
                child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final subTextColor = SC.isDark ? Colors.white54 : Colors.black45;
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, color: subTextColor.withValues(alpha: 0.15), size: 40),
            const SizedBox(height: 10),
            Text(SC.tr('no_photos'), style: TextStyle(color: subTextColor.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider() {
    return GestureDetector(
      onPanDown: (_) => _stopAutoSlide(),
      onPanEnd: (_) => _startAutoSlide(),
      child: SizedBox(
        height: 210,
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (page) => setState(() => _currentPage = page % _previewImages.length),
          itemBuilder: (context, index) {
            final realIndex = index % _previewImages.length;
            final isCenter = realIndex == _currentPage;
            return AnimatedScale(
              scale: isCenter ? 1.0 : 0.94,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: _SlideCard(image: _previewImages[realIndex], index: realIndex, allImages: _previewImages),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_previewImages.length, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? SC.cyan : (SC.isDark ? Colors.white24 : Colors.black12),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _SlideCard extends StatefulWidget {
  final GalleryImage image;
  final int index;
  final List<GalleryImage> allImages;
  const _SlideCard({required this.image, required this.index, required this.allImages});
  @override
  State<_SlideCard> createState() => _SlideCardState();
}

class _SlideCardState extends State<_SlideCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: _FullScreenGalleryView(images: widget.allImages, initialIndex: widget.index, heroTagPrefix: 'preview_')))),
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'preview_${widget.image.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.image.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: (SC.isDark ? Colors.white : Colors.black).withValues(alpha: 0.05), child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.cyanAccent)))),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 36, 14, 14),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent])),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.image.title != null) Text(widget.image.title!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: SC.cyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: SC.cyan.withValues(alpha: 0.4), width: 0.8)),
                              child: Text(widget.image.category, style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle), child: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenGalleryView extends StatefulWidget {
  final List<GalleryImage> images;
  final int initialIndex;
  final String heroTagPrefix;
  const _FullScreenGalleryView({required this.images, required this.initialIndex, this.heroTagPrefix = ''});
  @override
  State<_FullScreenGalleryView> createState() => _FullScreenGalleryViewState();
}

class _FullScreenGalleryViewState extends State<_FullScreenGalleryView> with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;
  bool _isSharing = false;
  late AnimationController _controlsAnim;
  final TransformationController _transformController = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _controlsAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controlsAnim.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) => SC.toast(context, msg, isError ? SC.red : SC.cyan);

  Future<void> _downloadImage() async {
    final image = widget.images[_currentIndex];
    setState(() => _isDownloading = true);
    try {
      if (Platform.isAndroid && !(await Permission.photos.request().isGranted)) {
        _showPermissionDialog();
        return;
      }
      _showSnack(SC.tr('downloading'));
      final response = await http.get(Uri.parse(image.imageUrl));
      final dir = Platform.isAndroid ? Directory('/storage/emulated/0/Download') : await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/gallery_${image.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);
      _showSnack(SC.tr('download_success'));
    } catch (e) {
      _showSnack(SC.tr('failed'), isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _shareImage() async {
    final image = widget.images[_currentIndex];
    setState(() => _isSharing = true);
    try {
      _showSnack(SC.tr('share_preparing'));
      final response = await http.get(Uri.parse(image.imageUrl));
      final tempFile = File('${(await getTemporaryDirectory()).path}/share.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);
      await Share.shareXFiles([XFile(tempFile.path)], text: image.title ?? '');
    } catch (e) {
      _showSnack(SC.tr('failed'), isError: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SC.isDark ? SC.cardBg : Colors.white,
        title: Text(SC.tr('storage_perm_required'), style: TextStyle(color: SC.isDark ? Colors.white : Colors.black)),
        content: Text(SC.tr('storage_perm_msg'), style: TextStyle(color: SC.isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(SC.tr('cancel'))),
          ElevatedButton(onPressed: () => openAppSettings(), child: Text(SC.tr('open_settings'))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final List<String> months = [
      SC.tr('jan'), SC.tr('feb'), SC.tr('mar'), SC.tr('apr'), SC.tr('may'), SC.tr('jun'),
      SC.tr('jul'), SC.tr('aug'), SC.tr('sep'), SC.tr('oct'), SC.tr('nov'), SC.tr('dec')
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.images[_currentIndex];
    final isDark = SC.isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GestureDetector(
              onTap: () => _controlsAnim.isCompleted ? _controlsAnim.reverse() : _controlsAnim.forward(),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, index) => InteractiveViewer(child: Center(child: Hero(tag: 'preview_${widget.images[index].id}', child: CachedNetworkImage(imageUrl: widget.images[index].imageUrl)))),
              ),
            ),
            // Top Bar
            FadeTransition(
              opacity: _controlsAnim,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _glassBtn(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
                      _glassBtn(_isDownloading ? Icons.downloading : Icons.download, _downloadImage, color: SC.cyan),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Panel
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: FadeTransition(
                opacity: _controlsAnim,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (image.title != null) Text(image.title!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: SC.cyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Text(image.category, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11))),
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_month, color: Colors.white38, size: 14),
                          const SizedBox(width: 4),
                          Text(_formatDate(image.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _actionBtn(Icons.pinch, SC.tr('zoom_hint'), null),
                          const SizedBox(width: 8),
                          _actionBtn(Icons.download, SC.tr('download_label'), _downloadImage, isPrimary: true),
                          const SizedBox(width: 8),
                          _actionBtn(Icons.share, SC.tr('share_label'), _shareImage),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 18)),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback? onTap, {bool isPrimary = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isPrimary ? SC.cyan.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isPrimary ? SC.cyan.withValues(alpha: 0.4) : Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, color: isPrimary ? SC.cyan : Colors.white60, size: 18),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isPrimary ? SC.cyan : Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}