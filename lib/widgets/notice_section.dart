import 'package:flutter/material.dart';
import '../models/notice_model.dart';
import 'activity_tile.dart';

class NoticeSection extends StatelessWidget {
  final bool isLoading;
  final List<Notice> notices;
  final VoidCallback onViewAll;
  final VoidCallback onNoticeTap;

  const NoticeSection({
    super.key,
    required this.isLoading,
    required this.notices,
    required this.onViewAll,
    required this.onNoticeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "সর্বশেষ বিজ্ঞপ্তি",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              if (notices.isNotEmpty)
                GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "সব দেখুন",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: isLoading
                ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.cyanAccent,
                ),
              ),
            )
                : notices.isEmpty
                ? const Center(
              child: Text(
                "কোনো বিজ্ঞপ্তি নেই",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                ),
              ),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: notices.length,
                itemBuilder: (context, index) {
                  final notice = notices[index];
                  return ActivityTile(
                    icon: Icons.campaign_rounded,
                    title: notice.title,
                    subtitle:
                    "${notice.publishDate.day}/${notice.publishDate.month}/${notice.publishDate.year}",
                    time: index == 0 ? "NEW" : "",
                    iconColor: index % 2 == 0
                        ? Colors.orangeAccent
                        : Colors.cyanAccent,
                    hasPdf: notice.pdfUrl != null &&
                        notice.pdfUrl!.isNotEmpty,
                    onTap: onNoticeTap,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}