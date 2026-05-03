import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:css/models/notice_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class AdminNoticeCard extends StatefulWidget {
  final Notice notice;
  final int index;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;

  const AdminNoticeCard({
    super.key,
    required this.notice,
    required this.index,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    this.onOpen,
  });

  @override
  State<AdminNoticeCard> createState() => _AdminNoticeCardState();
}

class _AdminNoticeCardState extends State<AdminNoticeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  bool _expanded = false;

  static const _accents = [
    [Color(0xFF00FFFF), Color(0xFF0077FF)],
    [Color(0xFF7B61FF), Color(0xFFFF61DC)],
    [Color(0xFF00E5A0), Color(0xFF00BFFF)],
    [Color(0xFFFFBE0B), Color(0xFFFF6B6B)],
    [Color(0xFFFF6B6B), Color(0xFFFF61DC)],
    [Color(0xFF06B6D4), Color(0xFF6366F1)],
  ];

  String _getExt(String? url) {
    if (url == null) return '';
    return url.split('.').last.split('?').first.toLowerCase();
  }

  Color _getColor(String ext) {
    switch (ext) {
      case 'pdf':  return const Color(0xFFFF6B6B);
      case 'doc':
      case 'docx': return const Color(0xFF4ECDC4);
      case 'txt':  return const Color(0xFF95E1D3);
      case 'jpg':
      case 'jpeg':
      case 'png':  return const Color(0xFFFFBE0B);
      default:     return const Color(0xFF8B8FA8);
    }
  }

  IconData _getIcon(String ext) {
    switch (ext) {
      case 'pdf':  return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx': return Icons.description_rounded;
      case 'txt':  return Icons.text_snippet_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':  return Icons.image_rounded;
      default:     return Icons.insert_drive_file_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice    = widget.notice;
    final isDark    = widget.isDark;
    final ext       = _getExt(notice.pdfUrl);
    final hasFile   = notice.pdfUrl != null && notice.pdfUrl!.isNotEmpty;
    final fileColor = _getColor(ext);
    final isNew     = DateTime.now().difference(notice.publishDate).inDays < 3;
    final accent    = _accents[widget.index % _accents.length];
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subColor  = isDark
        ? Colors.white.withOpacity(0.4)
        : Colors.black.withOpacity(0.45);

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        setState(() => _expanded = !_expanded);
        HapticFeedback.lightImpact();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) =>
            Transform.scale(scale: _pressCtrl.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C1525) : Colors.white,
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
            child: Column(children: [
              // Top accent bar
              Container(
                height: 3,
                decoration:
                BoxDecoration(gradient: LinearGradient(colors: accent)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(children: [
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
                            Wrap(spacing: 7, runSpacing: 6, children: [
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
                            ]),
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

                  // Expanded section
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 280),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox(height: 0),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(children: [
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

                        // File open button
                        if (hasFile && widget.onOpen != null)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              widget.onOpen!();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  fileColor.withOpacity(0.14),
                                  fileColor.withOpacity(0.05),
                                ]),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: fileColor.withOpacity(0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: fileColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getIcon(ext),
                                    color: fileColor,
                                    size: 18,
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
                                          color: fileColor.withOpacity(0.6),
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
                                  size: 16,
                                ),
                              ]),
                            ),
                          ),

                        // Edit & Delete buttons
                        Row(children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onEdit,
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B61FF)
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: const Color(0xFF7B61FF)
                                        .withOpacity(0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.edit_rounded,
                                      color: Color(0xFF7B61FF),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      SC.tr('noticeMgmtEdit'),
                                      style: const TextStyle(
                                        color: Color(0xFF7B61FF),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onDelete,
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B)
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: const Color(0xFFFF6B6B)
                                        .withOpacity(0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFFF6B6B),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      SC.tr('noticeMgmtDelete'),
                                      style: const TextStyle(
                                        color: Color(0xFFFF6B6B),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
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