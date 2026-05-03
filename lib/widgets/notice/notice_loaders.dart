import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

/// Animated pulse loader shown while notices are fetching.
class NoticePulseLoader extends StatefulWidget {
  final Color accentColor;
  final bool isDark;

  const NoticePulseLoader({
    super.key,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<NoticePulseLoader> createState() => _NoticePulseLoaderState();
}

class _NoticePulseLoaderState extends State<NoticePulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accentColor
                  .withOpacity(0.05 + 0.08 * _anim.value),
              border: Border.all(
                color: widget.accentColor
                    .withOpacity(0.2 + 0.4 * _anim.value),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.15 * _anim.value),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.campaign_rounded,
              color: widget.accentColor
                  .withOpacity(0.4 + 0.5 * _anim.value),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            SC.tr('noticeLoading'),
            style: TextStyle(
              color: (widget.isDark ? Colors.white : Colors.black)
                  .withOpacity(0.25 + 0.25 * _anim.value),
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}