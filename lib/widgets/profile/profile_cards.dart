import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

// ── Loading Overlay ───────────────────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isDark;
  const LoadingOverlay({super.key, required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black54,
    child: Center(
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                  color: Color(0xFFEF5350), strokeWidth: 2.5)),
          const SizedBox(height: 18),
          Text(message,
              style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.65),
                  fontSize: 13)),
        ]),
      ),
    ),
  );
}

// ── Glass Card ────────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final bool isDark;
  const GlassCard({
    super.key,
    required this.child,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0F1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 1.5),
    ),
    child: child,
  );
}

// ── Tenure Card ───────────────────────────────────────────────────────────────

class TenureCard extends StatelessWidget {
  final String? previousPosition;
  final String tenureLabel;
  final Color textColor;
  final Color subTextColor;
  static const _purple = Color(0xFF9C27B0);

  const TenureCard({
    super.key,
    required this.previousPosition,
    required this.tenureLabel,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _purple.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: _purple.withValues(alpha: 0.3), width: 1.5),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _purple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.history_edu_rounded,
            color: _purple, size: 26),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(SC.tr('previousPosition'),
                  style: TextStyle(
                      color: subTextColor.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(
                  previousPosition ?? SC.tr('notProvided'),
                  style: TextStyle(
                    color: previousPosition != null
                        ? textColor.withValues(alpha: 0.92)
                        : textColor.withValues(alpha: 0.25),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  )),
              if (tenureLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tenureLabel,
                      style: const TextStyle(
                          color: _purple,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
      ),
    ]),
  );
}

// ── Note Card ─────────────────────────────────────────────────────────────────

class NoteCard extends StatelessWidget {
  final String note;
  final Color accent;
  final IconData icon;
  final String title;
  final Color textColor;

  const NoteCard({
    super.key,
    required this.note,
    required this.accent,
    required this.icon,
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18),
      border:
      Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: accent, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4)),
              const SizedBox(height: 6),
              Text(note,
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.78),
                      fontSize: 13,
                      height: 1.6)),
            ]),
      ),
    ]),
  );
}