import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:css/models/gallery_image_model.dart';
import 'package:css/services/gallery_service.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with TickerProviderStateMixin {
  final _galleryService = GalleryService();
  bool _loading = true;
  List<GalleryImage> _images = [];
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = '';
  List<String> _categories = [];

  late AnimationController _animationController;
  late AnimationController _headerAnimController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _selectedCategory = SC.tr('all');
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final allLabel = SC.tr('all');
      final cats = await _galleryService.getCategories();
      final images = await _galleryService.fetchGallery(
        category: _selectedCategory == allLabel ? null : _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _categories = cats;
          _images = images;
          _loading = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = SC.tr('imageLoadError');
          _loading = false;
        });
      }
    }
  }

  List<GalleryImage> get _filteredImages {
    if (_searchQuery.isEmpty) return _images;
    return _images
        .where((img) =>
    img.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
        false)
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
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    final allLabel = SC.tr('all');
    // ─── "সব" যেন শুধু একবারই আসে ───
    final fullCategories = [allLabel, ..._categories.where((c) => c != allLabel)];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            _buildBackground(isDark),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(isDark, textColor, borderColor, fillColor),
                _buildCategorySection(isDark, textColor, fullCategories, allLabel),
                _buildStatsBar(isDark, textColor),
                if (_loading)
                  SliverFillRemaining(
                    child: _buildLoadingState(isDark, textColor),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    child: _buildErrorState(isDark, textColor),
                  )
                else if (_filteredImages.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(isDark, textColor),
                    )
                  else
                    _buildGrid(isDark, textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── BACKGROUND BLOBS ───────────────────────────────────────
  Widget _buildBackground(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                SC.cyan.withValues(alpha: isDark ? 0.08 : 0.05),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -120,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                SC.purple.withValues(alpha: isDark ? 0.07 : 0.04),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SLIVER APPBAR ──────────────────────────────────────────
  Widget _buildSliverAppBar(
      bool isDark,
      Color textColor,
      Color borderColor,
      Color fillColor,
      ) {
    return SliverAppBar(
      expandedHeight: 290,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: isDark ? SC.bgStart : const Color(0xFFF0F4FF),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: BoxDecoration(gradient: SC.currentGradient)),

            // ডেকোরেটিভ জ্যামিতিক আকার
            Positioned(
              right: -30,
              top: 30,
              child: Opacity(
                opacity: 0.05,
                child: Transform.rotate(
                  angle: -0.4,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: SC.cyan, width: 1.5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 60,
              child: Opacity(
                opacity: 0.04,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: SC.blue, width: 1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),

            // হেডার কন্টেন্ট
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FadeTransition(
                    opacity: _headerAnimController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _headerAnimController,
                        curve: Curves.easeOutCubic,
                      )),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ব্যাজ রো
                          Row(
                            children: [
                              _buildBadge(
                                SC.tr('galleryLabel'),
                                SC.cyan,
                                Colors.black,
                                solid: true,
                              ),
                              const SizedBox(width: 10),
                              _buildBadge(
                                '${_images.length} ${SC.tr('imagesCount')}',
                                isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.07),
                                textColor.withValues(alpha: 0.55),
                                borderColor: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // শিরোনাম
                          Text(
                            SC.tr('memories'),
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              height: 1.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                LinearGradient(colors: [SC.cyan, SC.blue])
                                    .createShader(bounds),
                            child: Text(
                              SC.tr('album'),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // সার্চ বার
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          color: (isDark ? SC.bgStart : const Color(0xFFF0F4FF))
              .withValues(alpha: 0.9),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: SC.tr('searchMemories'),
                  hintStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.25),
                    fontSize: 13,
                  ),
                  prefixIcon:
                  Icon(Icons.search_rounded, color: SC.cyan, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: textColor.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  )
                      : null,
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                    BorderSide(color: SC.cyan.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
      String text,
      Color bgColor,
      Color textClr, {
        bool solid = false,
        Color? borderColor,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textClr,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  // ─── CATEGORY CHIPS ─────────────────────────────────────────
  Widget _buildCategorySection(
      bool isDark,
      Color textColor,
      List<String> fullCategories,
      String allLabel,
      ) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: fullCategories.length,
          itemBuilder: (context, index) {
            final cat = fullCategories[index];
            final isSelected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat);
                _loadData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 10),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [SC.cyan, SC.blue])
                      : null,
                  color: isSelected
                      ? null
                      : isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: SC.cyan.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ]
                      : [],
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : textColor.withValues(alpha: 0.5),
                    fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── STATS BAR ──────────────────────────────────────────────
  Widget _buildStatsBar(bool isDark, Color textColor) {
    if (_loading || _filteredImages.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 12));
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: SC.cyan,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_filteredImages.length} ${SC.tr('imagesCount')}',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.35),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SC.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"$_searchQuery"',
                  style: TextStyle(color: SC.cyan, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── UNIFORM 2-COLUMN GRID ──────────────────────────────────
  Widget _buildGrid(bool isDark, Color textColor) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.72, // সব card একই সাইজ
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final delay = (index * 0.06).clamp(0.0, 1.0);
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: _animationController,
                curve: Interval(delay, 1.0, curve: Curves.easeOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(delay, 1.0, curve: Curves.easeOut),
                )),
                child: _GalleryImageCard(
                  image: _filteredImages[index],
                  index: index,
                  allImages: _filteredImages,
                  isDark: isDark,
                ),
              ),
            );
          },
          childCount: _filteredImages.length,
        ),
      ),
    );
  }

  // ─── STATE WIDGETS ──────────────────────────────────────────
  Widget _buildLoadingState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: SC.cyan,
              strokeWidth: 2.5,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            SC.tr('imageLoadingText'),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.35),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: SC.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border:
                Border.all(color: SC.red.withValues(alpha: 0.15)),
              ),
              child: Icon(Icons.wifi_off_rounded, color: SC.red, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [SC.cyan, SC.blue]),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: SC.cyan.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  SC.tr('tryAgain'),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.07),
              ),
            ),
            child: Icon(
              Icons.photo_library_outlined,
              color: textColor.withValues(alpha: 0.15),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            SC.tr('noImageFound'),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            SC.tr('noImageHint'),
            style: TextStyle(
              color: textColor.withValues(alpha: 0.25),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// GALLERY IMAGE CARD — uniform height, polished design
// ══════════════════════════════════════════════════════════════
class _GalleryImageCard extends StatefulWidget {
  final GalleryImage image;
  final int index;
  final List<GalleryImage> allImages;
  final bool isDark;

  const _GalleryImageCard({
    required this.image,
    required this.index,
    required this.allImages,
    required this.isDark,
  });

  @override
  State<_GalleryImageCard> createState() => _GalleryImageCardState();
}

class _GalleryImageCardState extends State<_GalleryImageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _openFullView() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (ctx, anim, _) => FadeTransition(
          opacity: anim,
          child: _FullGalleryViewer(
            images: widget.allImages,
            initialIndex: widget.index,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: _openFullView,
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── ছবির অংশ (flex 1) ──
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'gallery_${widget.image.id}',
                        child: CachedNetworkImage(
                          imageUrl: widget.image.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.04),
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.02)
                                      : Colors.black.withValues(alpha: 0.02),
                                ],
                              ),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: SC.cyan,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.black.withValues(alpha: 0.03),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: textColor.withValues(alpha: 0.12),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      // উপরের গ্রেডিয়েন্ট + ক্যাটাগরি ব্যাজ
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: SC.cyan,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            widget.image.category,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      // নিচে হালকা গ্রেডিয়েন্ট
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                (isDark ? SC.cardBg : Colors.white)
                                    .withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── তথ্যের অংশ (fixed height) ──
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.image.title ?? widget.image.category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 10,
                            color: textColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yy')
                                .format(widget.image.createdAt),
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.3),
                              fontSize: 10,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.open_in_full_rounded,
                            size: 11,
                            color: SC.cyan.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// FULL SCREEN VIEWER
// ══════════════════════════════════════════════════════════════
class _FullGalleryViewer extends StatefulWidget {
  final List<GalleryImage> images;
  final int initialIndex;

  const _FullGalleryViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullGalleryViewer> createState() => _FullGalleryViewerState();
}

class _FullGalleryViewerState extends State<_FullGalleryViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;
  bool _isDownloading = false;
  late AnimationController _uiAnim;
  late AnimationController _panelAnim;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _uiAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _panelAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _uiAnim.dispose();
    _panelAnim.dispose();
    super.dispose();
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    _showUI ? _uiAnim.forward() : _uiAnim.reverse();
    _showUI ? _panelAnim.forward() : _panelAnim.reverse();
  }

  Future<void> _downloadImage() async {
    final image = widget.images[_currentIndex];
    setState(() => _isDownloading = true);
    try {
      if (await Permission.storage.request().isGranted) {
        final response = await http.get(Uri.parse(image.imageUrl));
        final dir = await getExternalStorageDirectory();
        final file = File(
          '${dir!.path}/gallery_${image.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(response.bodyBytes);
        _showSnack(SC.tr('imageSaved'));
      } else {
        _showSnack(SC.tr('storagePermission'), isError: true);
      }
    } catch (_) {
      _showSnack(SC.tr('downloadFailed'), isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? SC.red : SC.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.images[_currentIndex];
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Image PageView ──
          GestureDetector(
            onTap: _toggleUI,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, index) {
                return InteractiveViewer(
                  minScale: 0.3,
                  maxScale: 6.0,
                  child: Center(
                    child: Hero(
                      tag: 'gallery_${widget.images[index].id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.images[index].imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => Center(
                          child: CircularProgressIndicator(
                            color: SC.cyan,
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image_outlined,
                                color: Colors.white24, size: 60),
                            const SizedBox(height: 12),
                            Text(SC.tr('imageNotLoaded'),
                                style:
                                const TextStyle(color: Colors.white24)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Top Bar ──
          FadeTransition(
            opacity: _uiAnim,
            child: SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildIconBtn(
                        Icons.close_rounded, () => Navigator.pop(context)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildIconBtn(
                      _isDownloading
                          ? Icons.downloading_rounded
                          : Icons.download_rounded,
                      _isDownloading ? null : _downloadImage,
                      color: SC.cyan,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Left Arrow ──
          if (_currentIndex > 0)
            FadeTransition(
              opacity: _uiAnim,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),

          // ── Right Arrow ──
          if (_currentIndex < widget.images.length - 1)
            FadeTransition(
              opacity: _uiAnim,
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),

          // ── Bottom Panel ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _panelAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: _panelAnim, curve: Curves.easeOut)),
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                          24, 20, 24, bottomPadding + 24),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32)),
                        border: Border(
                          top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.07)),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          if (image.title != null) ...[
                            Text(
                              image.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: SC.cyan.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                      SC.cyan.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  image.category,
                                  style: TextStyle(
                                    color: SC.cyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.calendar_month_outlined,
                                  size: 13,
                                  color:
                                  Colors.white.withValues(alpha: 0.35)),
                              const SizedBox(width: 5),
                              Text(
                                DateFormat('dd MMMM yyyy')
                                    .format(image.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionBtn(
                                  Icons.zoom_in_rounded,
                                  SC.tr('pinchZoom'),
                                  false,
                                      () => _showSnack(SC.tr('pinchZoomHint')),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionBtn(
                                  _isDownloading
                                      ? Icons.downloading_rounded
                                      : Icons.download_rounded,
                                  SC.tr('download'),
                                  true,
                                  _isDownloading ? null : _downloadImage,
                                  isLoading: _isDownloading,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionBtn(
                                  Icons.share_rounded,
                                  SC.tr('share'),
                                  false,
                                      () => _showSnack(SC.tr('shareComingSoon')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback? onTap,
      {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border:
          Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(
          icon,
          color: onTap == null ? Colors.white24 : color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildActionBtn(
      IconData icon,
      String label,
      bool isPrimary,
      VoidCallback? onTap, {
        bool isLoading = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(colors: [SC.cyan, SC.blue])
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: isPrimary && !isLoading
              ? [
            BoxShadow(
              color: SC.cyan.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isPrimary ? Colors.black : Colors.white,
              ),
            )
                : Icon(
              icon,
              size: 22,
              color: isPrimary ? Colors.black : Colors.white60,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.black : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}