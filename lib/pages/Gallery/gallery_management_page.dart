import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:css/models/gallery_image_model.dart';
import 'package:css/services/gallery_service.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class GalleryManagementPage extends StatefulWidget {
  const GalleryManagementPage({super.key});

  @override
  State<GalleryManagementPage> createState() =>
      _GalleryManagementPageState();
}

class _GalleryManagementPageState extends State<GalleryManagementPage>
    with SingleTickerProviderStateMixin {
  final _galleryService = GalleryService();
  bool _loading = true;
  List<GalleryImage> _images = [];
  String? _error;
  String _searchQuery = '';
  late AnimationController _animationController;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadImages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<GalleryImage> get _filteredImages {
    if (_searchQuery.isEmpty) return _images;
    return _images.where((img) {
      return (img.category
          .toLowerCase()
          .contains(_searchQuery.toLowerCase())) ||
          (img.title
              ?.toLowerCase()
              .contains(_searchQuery.toLowerCase()) ??
              false);
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
      if (mounted) {
        setState(() {
          _images = images;
          _loading = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = SC.tr('galleryLoadError');
          _loading = false;
        });
      }
    }
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
        body: Stack(
          children: [
            _buildBackground(isDark),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(isDark, textColor),
                _buildStatsRow(isDark, textColor),
                if (_loading)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: SC.cyan, strokeWidth: 2),
                          const SizedBox(height: 16),
                          Text(SC.tr('loading'),
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.4),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                      child: _buildErrorState(isDark, textColor))
                else if (_filteredImages.isEmpty)
                    SliverFillRemaining(
                        child: _buildEmptyState(isDark, textColor))
                  else
                    _buildGalleryGrid(isDark, textColor),
              ],
            ),
          ],
        ),
        floatingActionButton: _buildFAB(isDark),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                SC.cyan.withValues(alpha: isDark ? 0.06 : 0.04),
                Colors.transparent
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                SC.purple.withValues(alpha: isDark ? 0.05 : 0.03),
                Colors.transparent
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFAB(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [SC.cyan, SC.blue]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: SC.cyan.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showUploadDialog(isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_photo_alternate_rounded,
                    color: Colors.black, size: 22),
                const SizedBox(width: 10),
                Text(
                  SC.tr('newImage'),
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, Color textColor) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? SC.bgStart : const Color(0xFFF0F4FF),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child:
          Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: SC.currentGradient),
          child: Stack(
            children: [
              Positioned(
                bottom: 100,
                left: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: SC.cyan.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            SC.tr('admin').toUpperCase(),
                            style: TextStyle(
                                color: SC.cyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: 3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      SC.tr('gallery'),
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          height: 1.0),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                          colors: [SC.cyan, SC.blue])
                          .createShader(bounds),
                      child: Text(
                        SC.tr('management'),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 20,
                top: 60,
                child: Opacity(
                  opacity: 0.06,
                  child: Icon(Icons.photo_library_rounded,
                      size: 120, color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          color: (isDark ? SC.bgStart : const Color(0xFFF0F4FF))
              .withValues(alpha: 0.8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: SC.tr('searchCategoryTitle'),
              hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.25),
                  fontSize: 13),
              prefixIcon:
              Icon(Icons.search, color: SC.cyan, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                child: Icon(Icons.close_rounded,
                    color: textColor.withValues(alpha: 0.35),
                    size: 18),
              )
                  : null,
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: SC.cyan.withValues(alpha: 0.4))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, Color textColor) {
    if (_loading || _images.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 4));
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            _StatChip(
              label: SC.tr('totalImages'),
              value: '${_images.length}',
              icon: Icons.photo_rounded,
              isDark: isDark,
              textColor: textColor,
            ),
            const SizedBox(width: 10),
            _StatChip(
              label: SC.tr('categories'),
              value: '${_images.map((e) => e.category).toSet().length}',
              icon: Icons.category_rounded,
              isDark: isDark,
              textColor: textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(bool isDark, Color textColor) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final image = _filteredImages[index];
            final delay = (index * 0.07).clamp(0.0, 1.0);
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: _animationController,
                curve: Interval(delay, 1.0, curve: Curves.easeOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(0, 0.15), end: Offset.zero)
                    .animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(delay, 1.0, curve: Curves.easeOut),
                )),
                child: _ManagementImageCard(
                  image: image,
                  onDelete: () => _deleteImage(image, isDark),
                  isDark: isDark,
                  textColor: textColor,
                ),
              ),
            );
          },
          childCount: _filteredImages.length,
        ),
      ),
    );
  }

  void _showUploadDialog(bool isDark) {
    final titleCtrl = TextEditingController();
    String selectedCat = SC.tr('categories').isNotEmpty
        ? 'ইভেন্ট'
        : 'Event'; // keeps existing category list logic
    PlatformFile? selectedFile;
    bool isUploading = false;

    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.4);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                begin: const Offset(0, 0.1), end: Offset.zero)
                .animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: StatefulBuilder(
              builder: (ctx2, setDialogState) => Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter:
                        ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          constraints:
                          const BoxConstraints(maxWidth: 480),
                          decoration: BoxDecoration(
                            color: isDark
                                ? SC.cardBg.withValues(alpha: 0.95)
                                : Colors.white.withValues(alpha: 0.97),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black
                                    .withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [SC.cyan, SC.blue]),
                                  borderRadius:
                                  const BorderRadius.vertical(
                                      top: Radius.circular(32)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                        BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: Colors.white,
                                          size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      SC.tr('addNewImage'),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () =>
                                          Navigator.pop(ctx2),
                                      child: Container(
                                        padding:
                                        const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    _dialogLabel(
                                        SC.tr('selectCategory'),
                                        labelColor),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white
                                            .withValues(alpha: 0.05)
                                            : Colors.black
                                            .withValues(alpha: 0.04),
                                        borderRadius:
                                        BorderRadius.circular(14),
                                        border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                alpha: 0.08)
                                                : Colors.black.withValues(
                                                alpha: 0.08)),
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectedCat,
                                        isExpanded: true,
                                        dropdownColor: isDark
                                            ? SC.cardBg
                                            : Colors.white,
                                        underline: const SizedBox(),
                                        style: TextStyle(
                                            color: textColor,
                                            fontSize: 14),
                                        icon: Icon(
                                            Icons
                                                .keyboard_arrow_down_rounded,
                                            color: SC.cyan),
                                        items: [
                                          'ইভেন্ট',
                                          'সেমিনার',
                                          'কর্মশালা',
                                          'প্রোগ্রাম'
                                        ]
                                            .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e)))
                                            .toList(),
                                        onChanged: (val) =>
                                            setDialogState(
                                                    () => selectedCat = val!),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _dialogLabel(
                                        SC.tr('titleOptional'),
                                        labelColor),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: titleCtrl,
                                      style: TextStyle(
                                          color: textColor, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText:
                                        SC.tr('imageTitleHint'),
                                        hintStyle: TextStyle(
                                            color: textColor.withValues(
                                                alpha: 0.25),
                                            fontSize: 13),
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.white
                                            .withValues(alpha: 0.05)
                                            : Colors.black
                                            .withValues(alpha: 0.04),
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                            borderSide:
                                            BorderSide.none),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                            borderSide: BorderSide(
                                                color: SC.cyan
                                                    .withValues(
                                                    alpha: 0.4))),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _dialogLabel(
                                        SC.tr('selectImage'),
                                        labelColor),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: isUploading
                                          ? null
                                          : () async {
                                        final result =
                                        await FilePicker.platform
                                            .pickFiles(
                                          type: FileType.image,
                                          withData: true,
                                        );
                                        if (result != null &&
                                            result.files.isNotEmpty) {
                                          setDialogState(() =>
                                          selectedFile =
                                              result.files.first);
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 250),
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: selectedFile != null
                                              ? SC.cyan
                                              .withValues(alpha: 0.06)
                                              : isDark
                                              ? Colors.white
                                              .withValues(alpha: 0.03)
                                              : Colors.black
                                              .withValues(
                                              alpha: 0.03),
                                          borderRadius:
                                          BorderRadius.circular(18),
                                          border: Border.all(
                                            color: selectedFile != null
                                                ? SC.cyan.withValues(
                                                alpha: 0.35)
                                                : isDark
                                                ? Colors.white.withValues(
                                                alpha: 0.07)
                                                : Colors.black.withValues(
                                                alpha: 0.07),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              selectedFile != null
                                                  ? Icons
                                                  .check_circle_rounded
                                                  : Icons
                                                  .cloud_upload_outlined,
                                              color: selectedFile != null
                                                  ? SC.cyan
                                                  : textColor.withValues(
                                                  alpha: 0.25),
                                              size: 36,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              selectedFile?.name ??
                                                  SC.tr('clickToSelect'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: selectedFile !=
                                                      null
                                                      ? textColor.withValues(
                                                      alpha: 0.7)
                                                      : textColor.withValues(
                                                      alpha: 0.25),
                                                  fontSize: 13),
                                            ),
                                            if (selectedFile != null)
                                              Padding(
                                                padding:
                                                const EdgeInsets.only(
                                                    top: 6),
                                                child: Text(
                                                  '${((selectedFile!.size) / 1024).toStringAsFixed(1)} KB',
                                                  style: TextStyle(
                                                      color: SC.cyan
                                                          .withValues(
                                                          alpha: 0.6),
                                                      fontSize: 11),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isUploading) ...[
                                      const SizedBox(height: 20),
                                      ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          color: SC.cyan,
                                          backgroundColor: isDark
                                              ? Colors.white10
                                              : Colors.black
                                              .withValues(alpha: 0.08),
                                          minHeight: 3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Center(
                                        child: Text(
                                          SC.tr('uploading'),
                                          style: TextStyle(
                                              color: textColor.withValues(
                                                  alpha: 0.4),
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: isUploading
                                                ? null
                                                : () =>
                                                Navigator.pop(ctx2),
                                            child: Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 15),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white
                                                    .withValues(
                                                    alpha: 0.05)
                                                    : Colors.black
                                                    .withValues(
                                                    alpha: 0.05),
                                                borderRadius:
                                                BorderRadius.circular(
                                                    14),
                                                border: Border.all(
                                                    color: isDark
                                                        ? Colors.white
                                                        .withValues(
                                                        alpha: 0.07)
                                                        : Colors.black
                                                        .withValues(
                                                        alpha: 0.07)),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  SC.tr('cancelBtn'),
                                                  style: TextStyle(
                                                      color:
                                                      textColor.withValues(
                                                          alpha: 0.4),
                                                      fontWeight:
                                                      FontWeight.w600),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: GestureDetector(
                                            onTap: isUploading
                                                ? null
                                                : () async {
                                              if (selectedFile ==
                                                  null) {
                                                SC.toast(
                                                    context,
                                                    SC.tr(
                                                        'selectImageFirst'),
                                                    SC.red);
                                                return;
                                              }
                                              setDialogState(() =>
                                              isUploading = true);
                                              try {
                                                final url =
                                                await _galleryService
                                                    .uploadImage(
                                                    selectedFile!);
                                                await _galleryService
                                                    .addImageToGallery(
                                                  imageUrl: url,
                                                  category:
                                                  selectedCat,
                                                  title: titleCtrl
                                                      .text
                                                      .trim()
                                                      .isEmpty
                                                      ? null
                                                      : titleCtrl.text
                                                      .trim(),
                                                );
                                                if (mounted)
                                                  Navigator.pop(ctx2);
                                                _loadImages();
                                                SC.toast(
                                                    context,
                                                    SC.tr(
                                                        'uploadSuccess'),
                                                    SC.green);
                                              } catch (e) {
                                                setDialogState(() =>
                                                isUploading =
                                                false);
                                                SC.toast(
                                                    context,
                                                    SC.tr(
                                                        'uploadFailed'),
                                                    SC.red);
                                              }
                                            },
                                            child: Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 15),
                                              decoration: BoxDecoration(
                                                gradient: isUploading
                                                    ? null
                                                    : LinearGradient(
                                                    colors: [
                                                      SC.cyan,
                                                      SC.blue
                                                    ]),
                                                color: isUploading
                                                    ? isDark
                                                    ? Colors.white10
                                                    : Colors.black
                                                    .withValues(
                                                    alpha: 0.08)
                                                    : null,
                                                borderRadius:
                                                BorderRadius.circular(
                                                    14),
                                                boxShadow: isUploading
                                                    ? null
                                                    : [
                                                  BoxShadow(
                                                    color: SC.cyan
                                                        .withValues(
                                                        alpha: 0.3),
                                                    blurRadius: 12,
                                                    offset:
                                                    const Offset(
                                                        0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: isUploading
                                                    ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                  CircularProgressIndicator(
                                                      color: SC
                                                          .cyan,
                                                      strokeWidth:
                                                      2),
                                                )
                                                    : Text(
                                                  SC.tr('uploadBtn'),
                                                  style: const TextStyle(
                                                      color:
                                                      Colors.black,
                                                      fontWeight:
                                                      FontWeight
                                                          .w800,
                                                      fontSize: 15),
                                                ),
                                              ),
                                            ),
                                          ),
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
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dialogLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5),
    );
  }

  Future<void> _deleteImage(GalleryImage image, bool isDark) async {
    final textColor =
    isDark ? Colors.white : const Color(0xFF1A2332);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark
                    ? SC.cardBg.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: SC.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: SC.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child:
                    Icon(Icons.delete_rounded, color: SC.red, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(SC.tr('deleteImageConfirm'),
                      style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    SC.tr('deleteImageMsg'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textColor.withValues(alpha: 0.45),
                        fontSize: 13,
                        height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black
                                  .withValues(alpha: 0.06),
                              borderRadius:
                              BorderRadius.circular(14),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white
                                      .withValues(alpha: 0.08)
                                      : Colors.black
                                      .withValues(alpha: 0.08)),
                            ),
                            child: Center(
                                child: Text(SC.tr('cancelBtn'),
                                    style: TextStyle(
                                        color: textColor.withValues(
                                            alpha: 0.6),
                                        fontWeight:
                                        FontWeight.w600))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: BoxDecoration(
                              color: SC.red,
                              borderRadius:
                              BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                    SC.red.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Center(
                                child: Text(SC.tr('deleteImageBtn'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                        FontWeight.w800))),
                          ),
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
    ) ??
        false;

    if (confirmed) {
      try {
        await _galleryService.deleteImage(image.id, image.imageUrl);
        _loadImages();
        SC.toast(context, SC.tr('imageDeleted'), SC.green);
      } catch (e) {
        SC.toast(context, SC.tr('deleteFailed'), SC.red);
      }
    }
  }

  Widget _buildErrorState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: SC.red.withValues(alpha: 0.08),
                shape: BoxShape.circle),
            child:
            Icon(Icons.wifi_off_rounded, color: SC.red, size: 36),
          ),
          const SizedBox(height: 16),
          Text(_error!,
              style: TextStyle(color: SC.red, fontSize: 14)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loadImages,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient:
                LinearGradient(colors: [SC.cyan, SC.blue]),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(SC.tr('retryText'),
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              color: textColor.withValues(alpha: 0.1), size: 70),
          const SizedBox(height: 16),
          Text(SC.tr('noImageFound'),
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.25),
                  fontSize: 15)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _showUploadDialog(isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient:
                LinearGradient(colors: [SC.cyan, SC.blue]),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(SC.tr('addFirstImage'),
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════
// MANAGEMENT IMAGE CARD
// ════════════════════════════════════
class _ManagementImageCard extends StatefulWidget {
  final GalleryImage image;
  final VoidCallback onDelete;
  final bool isDark;
  final Color textColor;

  const _ManagementImageCard({
    required this.image,
    required this.onDelete,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<_ManagementImageCard> createState() =>
      _ManagementImageCardState();
}

class _ManagementImageCardState extends State<_ManagementImageCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = widget.textColor;
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final borderColor = _hovered
        ? SC.cyan.withValues(alpha: 0.3)
        : isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(
                    alpha: isDark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.image.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04),
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: SC.cyan),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04),
                        child: Icon(Icons.broken_image_outlined,
                            color:
                            textColor.withValues(alpha: 0.2)),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: 0.08)),
                        ),
                        child: Text(
                          widget.image.category,
                          style: TextStyle(
                              color: SC.cyan,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.03)
                    ]
                        : [
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.02)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.image.title != null)
                      Text(
                        widget.image.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 10,
                            color:
                            textColor.withValues(alpha: 0.3)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yy')
                              .format(widget.image.createdAt),
                          style: TextStyle(
                              color:
                              textColor.withValues(alpha: 0.3),
                              fontSize: 10),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color:
                              SC.red.withValues(alpha: 0.1),
                              borderRadius:
                              BorderRadius.circular(9),
                              border: Border.all(
                                  color: SC.red
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Icon(
                                Icons.delete_outline_rounded,
                                color: SC.red,
                                size: 16),
                          ),
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
    );
  }
}

// ════════════════════════════════════
// STAT CHIP
// ════════════════════════════════════
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final Color textColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: SC.cyan, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.35),
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}