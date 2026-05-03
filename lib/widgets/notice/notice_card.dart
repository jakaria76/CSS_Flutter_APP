import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:css/models/notice_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class NoticeCard extends StatefulWidget {
  final Notice notice;
  final int index;
  final bool isDark;
  final Function(String) onOpen;
  final String Function(String?) getExt;
  final IconData Function(String) getIcon;
  final Color Function(String) getExtColor;

  const NoticeCard({
    super.key,
    required this.notice,
    required this.index,
    required this.isDark,
    required this.onOpen,
    required this.getExt,
    required this.getIcon,
    required this.getExtColor,
  });

  @override
  State<NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<NoticeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressAnim;
  bool _expanded = false;

  static const _accents = [
    [Color(0xFF00FFFF), Color(0xFF0077FF)],
    [Color(0xFF7B61FF), Color(0xFFFF61DC)],
    [Color(0xFF00E5A0), Color(0xFF00BFFF)],
    [Color(0xFFFFBE0B), Color(0xFFFF6B6B)],
    [Color(0xFFFF6B6B), Color(0xFFFF61DC)],
    [Color(0xFF06B6D4), Color(0xFF6366F1)],
  ];

  @override
  void initState() {
    super.initState();
    _pressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice    = widget.notice;
    final isDark    = widget.isDark;
    final ext       = widget.getExt(notice.pdfUrl);
    final hasFile   = notice.pdfUrl != null && notice.pdfUrl!.isNotEmpty;
    final fileColor = widget.getExtColor(ext);
    final isNew     = DateTime.now().difference(notice.publishDate).inDays < 3;
    final accent    = _accents[widget.index % _accents.length];
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark
        ? Colors.white.withOpacity(0.4)
        : Colors.black.withOpacity(0.45);

    return GestureDetector(
      onTapDown: (_) => _pressAnim.reverse(),
      onTapUp: (_) {
        _pressAnim.forward();
        setState(() => _expanded = !_expanded);
        HapticFeedback.lightImpact();
      },
      onTapCancel: () => _pressAnim.forward(),
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, child) =>
            Transform.scale(scale: _pressAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0C1525).withOpacity(0.95)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: accent[0].withOpacity(isDark ? 0.08 : 0.10),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                // Top accent bar
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: accent),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Index badge
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent[0].withOpacity(0.18),
                                  accent[1].withOpacity(0.10),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: accent[0].withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.index + 1}',
                                style: TextStyle(
                                  color: accent[0],
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Title + chips
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notice.title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 6,
                                  children: [
                                    _chip(
                                      icon: Icons.calendar_today_rounded,
                                      label: DateFormat('dd MMM yyyy')
                                          .format(notice.publishDate),
                                      color: subColor,
                                      bg: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.04),
                                      border: isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.black.withOpacity(0.07),
                                    ),
                                    if (isNew)
                                      _badge('NEW', const Color(0xFFFF6B6B)),
                                    if (hasFile)
                                      _badge(ext.toUpperCase(), fileColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Expand arrow
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: accent[0].withOpacity(0.7),
                              size: 22,
                            ),
                          ),
                        ],
                      ),

                      // Expanded file section
                      if (hasFile)
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 280),
                          crossFadeState: _expanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: const SizedBox(height: 0),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Column(
                              children: [
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Colors.transparent,
                                      accent[0].withOpacity(0.2),
                                      accent[1].withOpacity(0.2),
                                      Colors.transparent,
                                    ]),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    widget.onOpen(notice.pdfUrl!);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        fileColor.withOpacity(0.15),
                                        fileColor.withOpacity(0.05),
                                      ]),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: fileColor.withOpacity(0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: fileColor.withOpacity(0.15),
                                            borderRadius:
                                            BorderRadius.circular(11),
                                          ),
                                          child: Icon(
                                            widget.getIcon(ext),
                                            color: fileColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                SC.tr('noticeOpenFile'),
                                                style: TextStyle(
                                                  color: fileColor,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                ext.toUpperCase(),
                                                style: TextStyle(
                                                  color: fileColor
                                                      .withOpacity(0.6),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: fileColor.withOpacity(0.7),
                                          size: 18,
                                        ),
                                      ],
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
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required Color border,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    ),
  );
}