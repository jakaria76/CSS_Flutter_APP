import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:css/models/gallery_image_model.dart';
import 'package:css/services/gallery_service.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> with TickerProviderStateMixin {
  final _galleryService = GalleryService();
  bool _loading = true;
  List<GalleryImage> _images = [];
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'সব';
  List<String> _categories = ['সব'];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categories = await _galleryService.getCategories();
      final images = await _galleryService.fetchGallery(
        category: _selectedCategory == 'সব' ? null : _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _categories = categories;
          _images = images;
          _loading = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "ছবি লোড করতে সমস্যা হয়েছে";
          _loading = false;
        });
      }
    }
  }

  List<GalleryImage> get _filteredImages {
    if (_searchQuery.isEmpty) return _images;
    return _images
        .where((img) => img.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Stack(
        children: [
          _buildBackgroundOrbs(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              _buildCategorySection(),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildErrorState())
              else if (_filteredImages.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  _buildMasonryGrid(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(top: 100, left: -50, child: _orb(300, Colors.cyanAccent.withOpacity(0.05))),
        Positioned(bottom: 100, right: -50, child: _orb(400, Colors.purpleAccent.withOpacity(0.05))),
      ],
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
      ],
    ),
  );

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0F2027),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 100,
              child: Opacity(opacity: 0.1, child: const Icon(Icons.auto_awesome, size: 100, color: Colors.cyanAccent)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(8)),
                    child: const Text('GALLERY',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 10),
                  const Text('স্মৃতির অ্যালবাম',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'আপনার স্মৃতির ছবি খুঁজুন...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.cyanAccent),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.3))),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return SliverToBoxAdapter(
      child: Container(
        height: 65,
        margin: const EdgeInsets.only(top: 10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final isSelected = _categories[index] == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = _categories[index]);
                  _loadData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white10),
                    boxShadow: isSelected ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                  ),
                  child: Center(
                    child: Text(
                      _categories[index],
                      style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMasonryGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemBuilder: (context, index) {
          final image = _filteredImages[index];
          return FadeTransition(
            opacity: _animationController,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _animationController,
                curve: Interval(index * 0.05 > 1.0 ? 1.0 : index * 0.05, 1.0, curve: Curves.easeOut),
              ),
              child: _buildImageCard(image, index),
            ),
          );
        },
        childCount: _filteredImages.length, // এখানে itemCount এর বদলে childCount হবে
      ),
    );
  }

  Widget _buildImageCard(GalleryImage image, int index) {
    return GestureDetector(
      onTap: () => _showImageDialog(image),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: image.id,
                  child: CachedNetworkImage(
                    imageUrl: image.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                        height: 150,
                        color: Colors.white10,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white24),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(image.title ?? 'Untitled',
                          maxLines: 2,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, height: 1.3)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 12, color: Colors.cyanAccent.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(DateFormat('dd MMM yyyy').format(image.createdAt),
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
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

  void _showImageDialog(GalleryImage image) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.9), // Colors.black90 এর পরিবর্তে
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => _buildDetailView(image),
      transitionBuilder: (ctx, anim1, anim2, child) =>
          FadeTransition(opacity: anim1, child: ScaleTransition(scale: anim1, child: child)),
    );
  }

  Widget _buildDetailView(GalleryImage image) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                      tag: image.id,
                      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: CachedNetworkImage(imageUrl: image.imageUrl))),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(image.title ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(DateFormat('dd MMMM yyyy').format(image.createdAt),
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 20),
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('বন্ধ করুন', style: TextStyle(color: Colors.white54))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() => Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
  Widget _buildEmptyState() =>
      const Center(child: Text('কোনো ছবি পাওয়া যায়নি', style: TextStyle(color: Colors.white24)));
}