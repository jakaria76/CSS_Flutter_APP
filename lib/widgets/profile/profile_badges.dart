import 'package:flutter/material.dart';

class PositionBadge extends StatelessWidget {
  final String label;
  final Color accent;
  const PositionBadge({super.key, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.2),
      color: accent.withValues(alpha: 0.08),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.workspace_premium_rounded, color: accent, size: 13),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]),
  );
}

class TenureBadge extends StatelessWidget {
  final String? position;
  final String tenureLabel;
  final Color accent;
  const TenureBadge({
    super.key,
    required this.position,
    required this.tenureLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.2),
      color: accent.withValues(alpha: 0.08),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.history_edu_rounded, color: accent, size: 13),
      const SizedBox(width: 5),
      if (position != null)
        Flexible(
          child: Text(
            position!,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      if (tenureLabel.isNotEmpty) ...[
        Container(
          width: 1,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: accent.withValues(alpha: 0.35),
        ),
        Text(
          tenureLabel,
          style: TextStyle(
            color: accent.withValues(alpha: 0.75),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ]),
  );
}

class AdvisorBadge extends StatelessWidget {
  final String? designation;
  final String? institution;
  final Color accent;
  const AdvisorBadge({
    super.key,
    required this.designation,
    required this.institution,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final label = [
      if (designation != null && designation!.isNotEmpty) designation!,
      if (institution != null && institution!.isNotEmpty) institution!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.2),
        color: accent.withValues(alpha: 0.08),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.work_outline_rounded, color: accent, size: 13),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label.isNotEmpty ? label : 'Advisor',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}