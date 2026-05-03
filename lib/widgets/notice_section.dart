import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notice_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

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

  // প্রতিটি notice item এর height
  static const double _itemHeight = 65.0;
  static const double _verticalPadding = 12.0; // top + bottom padding (6+6)
  static const int _maxNotices = 3;

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
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF4A5568);
    final cardColor = isDark ? const Color(0xFF0D1826) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.06);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    // দেখানো হবে সর্বোচ্চ ৩টা notice
    final displayedNotices = notices.take(_maxNotices).toList();

    // Dynamic height: notice count অনুযায়ী height হিসাব
    final double listHeight = isLoading
        ? _itemHeight + _verticalPadding
        : notices.isEmpty
        ? _itemHeight + _verticalPadding
        : (displayedNotices.length * _itemHeight) + _verticalPadding;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [SC.cyan, SC.blue],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    SC.tr('latest_notice'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!isLoading && notices.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: SC.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: SC.cyan.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        '${notices.length}',
                        style: TextStyle(
                          color: SC.cyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (!isLoading && notices.isNotEmpty)
                GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Text(
                          SC.tr('view_all'),
                          style: TextStyle(
                            color: SC.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: SC.cyan, size: 10),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Notice List Container ────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: listHeight,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: isDark
                  ? [
                BoxShadow(
                  color: SC.cyan.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: isLoading
                ? _buildLoader(subTextColor)
                : notices.isEmpty
                ? _buildEmpty(subTextColor)
                : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                padding:
                const EdgeInsets.symmetric(vertical: 6),
                itemCount: displayedNotices.length,
                separatorBuilder: (_, __) => Divider(
                  color: dividerColor,
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final notice = displayedNotices[index];
                  final isNew = DateTime.now()
                      .difference(notice.publishDate)
                      .inDays < 3;
                  return SizedBox(
                    height: _itemHeight,
                    child: _NoticeListItem(
                      notice: notice,
                      index: index,
                      isNew: isNew,
                      isDark: isDark,
                      onTap: onNoticeTap,
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader(Color subTextColor) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: SC.cyan,
            backgroundColor: subTextColor.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          SC.tr('loading_text'),
          style: TextStyle(color: subTextColor, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _buildEmpty(Color subTextColor) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_rounded,
            size: 32, color: subTextColor.withValues(alpha: 0.45)),
        const SizedBox(height: 8),
        Text(
          SC.tr('no_notice'),
          style: TextStyle(color: subTextColor, fontSize: 12),
        ),
      ],
    ),
  );
}

class _NoticeListItem extends StatelessWidget {
  final Notice notice;
  final int index;
  final bool isNew;
  final bool isDark;
  final VoidCallback onTap;
  final Color textColor;
  final Color subTextColor;

  const _NoticeListItem({
    required this.notice,
    required this.index,
    required this.isNew,
    required this.isDark,
    required this.onTap,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColors = [SC.cyan, SC.purple, SC.green, SC.amber];
    final iconColor = iconColors[index % iconColors.length];
    final hasFile = notice.pdfUrl != null && notice.pdfUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? iconColor.withValues(alpha: 0.18)
                    : iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isDark
                      ? iconColor.withValues(alpha: 0.35)
                      : iconColor.withValues(alpha: 0.2),
                ),
              ),
              child:
              Icon(Icons.campaign_rounded, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    notice.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${notice.publishDate.day}/${notice.publishDate.month}/${notice.publishDate.year}',
                    style: TextStyle(color: subTextColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? SC.red.withValues(alpha: 0.22)
                          : SC.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? SC.red.withValues(alpha: 0.5)
                            : SC.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      SC.tr('new_badge'),
                      style: TextStyle(
                        color: SC.red,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                if (hasFile) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.attach_file_rounded,
                      color: subTextColor.withValues(alpha: 0.6), size: 16),
                ],
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: subTextColor.withValues(alpha: 0.5), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}