import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../widgets/banner_slider.dart';

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
    return Column(
      children: [
        // AppBar থেকে দূরত্ব তৈরি করার জন্য এই গ্যাপটি দেওয়া হয়েছে
        const SizedBox(height: 23),

        Container(
          width: double.infinity,
          height: 240, // আপনার ডিজাইনের সাথে সামঞ্জস্য রেখে হাইট কিছুটা কমানো হয়েছে
          margin: const EdgeInsets.symmetric(horizontal: 0), // দুই পাশে সামান্য গ্যাপ
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25), // ব্যানারটি রাউন্ড শেপ করার জন্য
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25), // ইমেজগুলো যাতে কোণা দিয়ে বাইরে না যায়
            child: isLoading
                ? _buildGlassLoader()
                : banners.isEmpty
                ? _buildEmptyBanner()
                : _buildPremiumSlider(),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassLoader() {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.cyanAccent,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyBanner() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: Colors.white10, size: 40),
          SizedBox(height: 10),
          Text(
            'কোনো আপডেট পাওয়া যায়নি',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSlider() {
    return BannerSlider(
      banners: banners,
      height: 240,
      autoPlay: true,
      autoPlayInterval: const Duration(seconds: 5),
      showIndicator: true,
    );
  }
}