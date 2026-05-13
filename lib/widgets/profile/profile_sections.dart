import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

// ── Section Container ─────────────────────────────────────────────────────────

class ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final List<Widget> rows;
  final Color cardColor;
  final Color borderColor;
  final bool isDark;

  const ProfileSection({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.rows,
    required this.cardColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8))
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06))),
        ),
        child: Row(children: [
          Container(
              width: 3,
              height: 22,
              decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.3)),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(children: rows),
      ),
    ]),
  );
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color textColor;
  final Color subTextColor;
  final bool isDark;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
    required this.subTextColor,
    required this.isDark,
  });

  bool get _filled =>
      value != null &&
          value!.isNotEmpty &&
          value != 'null' &&
          value != ' · ';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08)),
        ),
        child: Icon(icon,
            size: 16,
            color: subTextColor.withValues(alpha: 0.5)),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 1),
            Text(label,
                style: TextStyle(
                    color: subTextColor.withValues(alpha: 0.45),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7)),
            const SizedBox(height: 3),
            Text(
              _filled ? value! : SC.tr('notProvided'),
              style: TextStyle(
                color: _filled
                    ? textColor.withValues(alpha: 0.92)
                    : textColor.withValues(alpha: 0.25),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ]),
  );
}

// ── Sub Header ────────────────────────────────────────────────────────────────

class ProfileSubHeader extends StatelessWidget {
  final String text;
  final bool isDark;
  static const _cyan = Color(0xFF00E5FF);

  const ProfileSubHeader({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
    child: Row(children: [
      Text(text.toUpperCase(),
          style: TextStyle(
              color: _cyan.withValues(alpha: 0.65),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6)),
      const SizedBox(width: 10),
      Expanded(
          child: Container(
              height: 1,
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.07))),
    ]),
  );
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;
  final Color surfaceColor;
  final Color subTextColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    required this.surfaceColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding:
      const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: accent.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(height: 10),
        Text(value,
            style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: subTextColor.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

// ── Danger Zone ───────────────────────────────────────────────────────────────

class DangerZone extends StatelessWidget {
  final VoidCallback onDelete;
  final Color subTextColor;
  static const _red = Color(0xFFEF5350);

  const DangerZone({
    super.key,
    required this.onDelete,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _red.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
          color: _red.withValues(alpha: 0.25), width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.warning_amber_rounded, color: _red, size: 18),
        const SizedBox(width: 8),
        Text(SC.tr('dangerZone'),
            style: const TextStyle(
                color: _red,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.3)),
      ]),
      const SizedBox(height: 10),
      Text(SC.tr('dangerZoneDesc'),
          style: TextStyle(
              color: subTextColor.withValues(alpha: 0.5),
              fontSize: 13,
              height: 1.55)),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_forever_rounded,
              size: 18, color: _red),
          label: Text(SC.tr('deleteMyAccount'),
              style: const TextStyle(
                  color: _red,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: _red, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ]),
  );
}