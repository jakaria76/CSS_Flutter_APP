import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

/// Diagonal line + dot grid background painter.
/// Used in both NoticePage and NoticeManagementPage headers.
class NoticeDiagonalPainter extends CustomPainter {
  final bool isDark;
  const NoticeDiagonalPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..strokeWidth = 0.6
      ..color = (isDark ? const Color(0xFF00FFFF) : SC.cyan)
          .withOpacity(isDark ? 0.05 : 0.06);

    const spacing = 36.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }

    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black)
          .withOpacity(isDark ? 0.04 : 0.05)
      ..style = PaintingStyle.fill;

    for (double x = 20; x < size.width; x += 36) {
      for (double y = 20; y < size.height; y += 36) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(NoticeDiagonalPainter old) => old.isDark != isDark;
}