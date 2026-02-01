import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/banner_model.dart';
import 'package:typewritertext/typewritertext.dart';

class BannerSlider extends StatefulWidget {
  final List<BannerModel> banners;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool showIndicator;

  const BannerSlider({
    super.key,
    required this.banners,
    this.height = 280,
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
    if (widget.banners.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      // ওপর থেকে কিছুটা নিচে নামানোর জন্য প্যাডিং
      padding: const EdgeInsets.only(top: 70, bottom: 0),
      child: Stack(
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
              enlargeFactor: 0.2, // স্লাইড বড় করার ফ্যাক্টর কিছুটা কমানো হয়েছে উইডথ বাড়াতে

              // ================= UPDATED WIDTH =================
              viewportFraction: 1, // ০.৮৫ থেকে ০.৯৫ করা হয়েছে যাতে উইডথ বেড়ে যায়
              // =================================================

              onPageChanged: (index, reason) => setState(() => _currentIndex = index),
            ),
            itemBuilder: (context, index, realIndex) {
              final banner = widget.banners[index];
              return _buildPremiumBannerCard(banner, index == _currentIndex);
            },
          ),

          // স্টাইলিশ নিয়ন ইন্ডিকেটর
          if (widget.showIndicator && widget.banners.length > 1)
            Positioned(
              bottom: 0,
              child: _buildIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumBannerCard(BannerModel banner, bool isActive) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.95, // ইন-অ্যাক্টিভ কার্ডের স্কেল
      duration: const Duration(milliseconds: 600),
      child: GestureDetector(
        onTap: () => _handleBannerTap(banner),
        child: Container(
          width: double.infinity, // স্লাইডারের এভেলেবল ফুল উইডথ নিবে
          margin: const EdgeInsets.symmetric(horizontal: 5), // স্লাইডগুলোর মধ্যে হালকা গ্যাপ
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25), // কর্নার রেডিয়াস সামঞ্জস্যপূর্ণ করা হয়েছে
            border: Border.all(
              color: isActive ? Colors.cyanAccent.withOpacity(0.3) : Colors.white10,
              width: 1.5,
            ),
            boxShadow: [
              if (isActive) // শুধু অ্যাক্টিভ কার্ডে গ্লো ইফেক্ট
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24), // বর্ডার থেকে ১ পিক্সেল কম রাখা হয়েছে ফিনিশিংয়ের জন্য
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ব্যাকগ্রাউন্ড ইমেজ জুম এনিমেশন
                AnimatedScale(
                  scale: isActive ? 1.0 : 1.1, // অ্যাক্টিভ হলে হালকা জুম আউট হয়ে ডিটেইল দেখাবে
                  duration: const Duration(seconds: 4),
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover, // পুরো কার্ড জুড়ে ফিট হবে
                    errorBuilder: (ctx, _, __) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                        ),
                      ),
                      child: const Icon(Icons.broken_image, color: Colors.white10, size: 40),
                    ),
                  ),
                ),

                // গ্রেডিয়েন্ট এবং টেক্সট প্যানেল
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
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.4),
            Colors.transparent,
            Colors.cyanAccent.withOpacity(0.05),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
      ),
    );
  }

   // নিশ্চিত করুন এই ইমপোর্টটি আছে

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // টাইটেল টাইপিং এনিমেশন
                        if (banner.title != null && isActive)
                          TypeWriterText(
                            // UniqueKey ব্যবহার করা হয়েছে যাতে স্লাইড চেঞ্জ হলেই টাইপিং শুরু হয়
                            key: UniqueKey(),
                            text: Text(
                              banner.title!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            duration: const Duration(milliseconds: 50),
                          )
                        else if (banner.title != null)
                          const SizedBox(height: 18),

                        if (banner.subtitle != null) ...[
                          const SizedBox(height: 2),

                          // সাবটাইটেল টাইপিং এনিমেশন
                          if (isActive)
                            TypeWriterText(
                              key: UniqueKey(), // নতুন কি মানেই নতুন করে টাইপিং শুরু
                              text: Text(
                                banner.subtitle!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              duration: const Duration(milliseconds: 30),
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
        bool isSelected = _currentIndex == entry.key;
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
                  ? const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent])
                  : LinearGradient(colors: [Colors.white24, Colors.white.withOpacity(0.1)]),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.5),
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
    return Container(
      height: widget.height,
      margin: const EdgeInsets.only(top: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2027),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white10),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_outlined, color: Colors.white10, size: 50),
            SizedBox(height: 10),
            Text('কোনো নতুন অফার নেই', style: TextStyle(color: Colors.white24)),
          ],
        ),
      ),
    );
  }
}