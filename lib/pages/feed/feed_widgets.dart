import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

// ─── Background Orb ──────────────────────────────────────────────────────────
class BackgroundOrb extends StatelessWidget {
  final Color color;
  const BackgroundOrb({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

// ─── Caption Field ────────────────────────────────────────────────────────────
class CaptionField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;

  const CaptionField({
    super.key,
    required this.controller,
    required this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg     = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.09);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFF1A2332).withValues(alpha: 0.35);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: controller,
        maxLines: 5,
        minLines: 3,
        style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

// ─── Add Image Button ─────────────────────────────────────────────────────────
class AddImageButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? label;
  final bool isDark;

  const AddImageButton({
    super.key,
    required this.onTap,
    required this.isDark,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: SC.cyan.withValues(alpha: isDark ? 0.05 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SC.cyan.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_photo_alternate_rounded, color: SC.cyan, size: 22),
          const SizedBox(width: 10),
          Text(
            label ?? SC.tr('feedWidgetAddImage'),
            style: TextStyle(
              color: SC.cyan, fontWeight: FontWeight.w600, fontSize: 14,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const SectionLabel({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
          color: color, fontSize: 13,
          fontWeight: FontWeight.w600, letterSpacing: 0.3,
        ));
  }
}

// ─── Image Grid ───────────────────────────────────────────────────────────────
class ImageGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index) imageBuilder;
  final void Function(int index) onRemove;
  final Widget Function(int index)? badge;

  const ImageGrid({
    super.key,
    required this.itemCount,
    required this.imageBuilder,
    required this.onRemove,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (_, i) => Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageBuilder(i),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => onRemove(i),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
          if (badge != null)
            Positioned(bottom: 4, left: 4, child: badge!(i)),
        ],
      ),
    );
  }
}

// ─── New Badge ────────────────────────────────────────────────────────────────
class NewBadge extends StatelessWidget {
  const NewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: SC.cyan,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        SC.tr('feedWidgetNewBadge'),
        style: const TextStyle(
          color: Colors.black, fontSize: 9, fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Number Badge ─────────────────────────────────────────────────────────────
class NumberBadge extends StatelessWidget {
  final int number;
  const NumberBadge({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Image Picker Sheet ───────────────────────────────────────────────────────
class ImagePickerSheet extends StatelessWidget {
  final String title;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final bool isDark;

  const ImagePickerSheet({
    super.key,
    required this.title,
    required this.onGallery,
    required this.onCamera,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sheetBg   = isDark ? const Color(0xFF203A43) : const Color(0xFFF0F4FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final handleColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.15);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(title,
              style: TextStyle(
                color: textColor, fontSize: 16, fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 20),
          _PickerOption(
            icon: Icons.photo_library_rounded,
            label: SC.tr('feedWidgetGallery'),
            onTap: onGallery,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _PickerOption(
            icon: Icons.camera_alt_rounded,
            label: SC.tr('feedWidgetCamera'),
            onTap: onCamera,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg     = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          Icon(icon, color: SC.cyan, size: 22),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: textColor, fontSize: 14)),
        ]),
      ),
    );
  }
}