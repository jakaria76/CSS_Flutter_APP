import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../widgets/banner_slider.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class BannerSection extends StatelessWidget {
  final bool isLoading;
  final List<BannerModel> banners;

  const BannerSection({
    super.key,
    required this.isLoading,
    required this.banners,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildSection(context),
      ),
    );
  }

  Widget _buildSection(BuildContext context) {
    final isDark       = SC.isDark;
    final loaderBg     = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final emptyBg      = isDark
        ? Colors.white.withValues(alpha: 0.02)
        : Colors.black.withValues(alpha: 0.02);
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final subTextColor = isDark ? Colors.white24 : Colors.black26;

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 0, right: 0),
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: isLoading
            ? _buildGlassLoader(loaderBg)
            : banners.isEmpty
            ? _buildEmptyBanner(emptyBg, borderColor, subTextColor)
            : _buildPremiumSlider(),
      ),
    );
  }

  Widget _buildGlassLoader(Color bgColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: SC.cyan,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyBanner(
      Color bgColor, Color borderColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined,
              color: textColor, size: 40),
          const SizedBox(height: 10),
          Text(
            SC.tr('no_banners'),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSlider() {
    return BannerSlider(
      banners:          banners,
      height:           200,
      autoPlay:         true,
      autoPlayInterval: const Duration(seconds: 5),
      showIndicator:    true,
    );
  }
}