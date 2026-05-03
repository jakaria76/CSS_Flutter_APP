import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/banner_model.dart';
import 'package:typewritertext/typewritertext.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class BannerSlider extends StatefulWidget {
  final List<BannerModel> banners;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool showIndicator;

  const BannerSlider({
    super.key,
    required this.banners,
    this.height = 240,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.showIndicator = true,
  });

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  Future<void> _handleBannerTap(BannerModel banner) async {
    if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) {
      final uri = Uri.parse(banner.linkUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.banners.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          carouselController: _controller,
          itemCount: widget.banners.length,
          options: CarouselOptions(
            height: widget.height,
            autoPlay: widget.autoPlay,
            autoPlayInterval: widget.autoPlayInterval,
            autoPlayAnimationDuration: const Duration(milliseconds: 1200),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            viewportFraction: 1,
            onPageChanged: (index, reason) =>
                setState(() => _currentIndex = index),
          ),
          itemBuilder: (context, index, realIndex) {
            final banner = widget.banners[index];
            return _buildPremiumBannerCard(
                banner, index == _currentIndex);
          },
        ),
        if (widget.showIndicator && widget.banners.length > 1)
          Positioned(
            bottom: 8,
            child: _buildIndicator(),
          ),
      ],
    );
  }

  Widget _buildPremiumBannerCard(BannerModel banner, bool isActive) {
    final isDark = SC.isDark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return AnimatedScale(
      scale: isActive ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 600),
      child: GestureDetector(
        onTap: () => _handleBannerTap(banner),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isActive
                  ? SC.cyan.withValues(alpha: 0.3)
                  : borderColor,
              width: 1.5,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: SC.cyan.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.0 : 1.1,
                  duration: const Duration(seconds: 4),
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, _, __) => Container(
                      decoration: BoxDecoration(
                        gradient: SC.currentGradient,
                      ),
                      child: Icon(
                        Icons.broken_image,
                        color: isDark
                            ? Colors.white10
                            : Colors.black12,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                _buildOverlaidGradient(),
                _buildGlassInfoPanel(banner, isActive),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlaidGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
            SC.cyan.withValues(alpha: 0.05),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildGlassInfoPanel(BannerModel banner, bool isActive) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 25,
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (banner.title != null && isActive)
                          TypeWriterText(
                            key: UniqueKey(),
                            text: Text(
                              banner.title!.toUpperCase(),
                              style: TextStyle(
                                color: SC.cyan,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            duration:
                            const Duration(milliseconds: 50),
                          )
                        else if (banner.title != null)
                          const SizedBox(height: 18),

                        if (banner.subtitle != null) ...[
                          const SizedBox(height: 2),
                          if (isActive)
                            TypeWriterText(
                              key: UniqueKey(),
                              text: Text(
                                banner.subtitle!,
                                style: TextStyle(
                                  color: Colors.white
                                      .withValues(alpha: 0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              duration:
                              const Duration(milliseconds: 30),
                            )
                          else
                            const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.banners.asMap().entries.map((entry) {
        final isSelected = _currentIndex == entry.key;
        return GestureDetector(
          onTap: () => _controller.animateToPage(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: isSelected ? 35 : 10,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: isSelected
                  ? LinearGradient(colors: [SC.cyan, SC.blue])
                  : LinearGradient(colors: [
                Colors.white24,
                Colors.white.withValues(alpha: 0.1)
              ]),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: SC.cyan.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
                  : [],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    final isDark    = SC.isDark;
    final textColor = isDark ? Colors.white24 : Colors.black26;

    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? SC.bgMid
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_outlined,
                color: textColor, size: 50),
            const SizedBox(height: 10),
            Text(SC.tr('no_new_offers'),
                style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}