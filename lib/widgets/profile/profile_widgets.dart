import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class OutlineBtn extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const OutlineBtn({
    super.key,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      side: BorderSide(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.18)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label,
        style: TextStyle(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
            fontSize: 14)),
  );
}

class SolidBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const SolidBtn({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label,
        style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14)),
  );
}

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final bool isDark;
  final VoidCallback onToggle;
  const PasswordField({
    super.key,
    required this.controller,
    required this.visible,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: !visible,
    style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1A2332),
        fontSize: 14),
    decoration: InputDecoration(
      hintText: SC.tr('enterYourPassword'),
      hintStyle: TextStyle(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.28),
          fontSize: 13),
      prefixIcon: Icon(Icons.lock_outline_rounded,
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.4),
          size: 18),
      suffixIcon: IconButton(
        icon: Icon(
          visible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.4),
          size: 18,
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: (isDark ? Colors.white : Colors.black)
          .withValues(alpha: 0.05),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
        const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
      ),
    ),
  );
}