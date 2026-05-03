import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/committee_member_model.dart';
import '../pages/Profile/profile_page.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class CommitteeCard extends StatefulWidget {
  final CommitteeMember member;
  final VoidCallback? onViewProfile;

  const CommitteeCard({
    super.key,
    required this.member,
    this.onViewProfile,
  });

  @override
  State<CommitteeCard> createState() => _CommitteeCardState();
}

class _CommitteeCardState extends State<CommitteeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.972).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (widget.onViewProfile != null) {
      widget.onViewProfile!();
    } else {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => ProfilePage(id: widget.member.id),
          transitionsBuilder: (_, a, __, child) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0.04, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 320),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDark = SC.isDark;
    final cardBg = isDark ? SC.cardBg : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    final isTop = widget.member.category == 'Top' || widget.member.category == 'শীর্ষ';

    // Accent colors based on priority
    final Color accent = isTop ? SC.amber : SC.cyan;
    final Color accentDim = isTop ? SC.orange : SC.blue;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _ctrl.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _ctrl.reverse();
        _handleTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed ? accent.withValues(alpha: 0.45) : borderColor,
              width: 1.0,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo area ─────────────────────────────────
              _buildPhotoArea(accent, isTop, isDark, cardBg),

              // ── Info area ──────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Position badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: accent.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          widget.member.position,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 7),

                      // Name
                      Text(
                        widget.member.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: -0.1,
                        ),
                      ),

                      const Spacer(),

                      // CTA Button
                      _buildCTA(accent, accentDim, isTop),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoArea(Color accent, bool isTop, bool isDark, Color cardBg) {
    final placeholderBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: placeholderBg),

          if (widget.member.imagePath != null && widget.member.imagePath!.isNotEmpty)
            Image.network(
              widget.member.imagePath!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _placeholder(accent, placeholderBg),
            )
          else
            _placeholder(accent, placeholderBg),

          // Bottom gradient overlay
          Positioned(
            bottom: 0, left: 0, right: 0, height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    cardBg.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top-right badge for top leaders
          if (isTop)
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: SC.amber,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)
                    ]
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 10, color: Colors.black),
                    const SizedBox(width: 3),
                    Text(
                      SC.tr('leadership_label'),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(Color accent, Color bg) {
    return Container(
      color: bg,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 52,
          color: accent.withValues(alpha: 0.18),
        ),
      ),
    );
  }

  Widget _buildCTA(Color accent, Color accentDim, bool isTop) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accentDim],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  SC.tr('view_profile_btn'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isTop ? Colors.black : Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: isTop ? Colors.black : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}