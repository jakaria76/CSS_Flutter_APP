import 'package:flutter/material.dart';
import '../../models/profile_model.dart';
import '../../models/member_type.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/widgets/profile/profile_badges.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final Animation<double> pulseAnimation;
  final Color textColor;
  final Color subTextColor;
  final Color cardColor;
  final Color accentColor;

  static const _blue   = Color(0xFF4A90E2);
  static const _red    = Color(0xFFEF5350);
  static const _orange = Color(0xFFFF8A65);
  static const _green  = Color(0xFF4CAF50);
  static const _amber  = Color(0xFFFFB300);
  static const _purple = Color(0xFF9C27B0);
  static const _teal   = Color(0xFF26A69A);

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.pulseAnimation,
    required this.textColor,
    required this.subTextColor,
    required this.cardColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 120, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top section: image + info ──────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImage(),
                    const SizedBox(width: 14),
                    Expanded(child: _buildInfo()),
                  ],
                ),
              ),

              // ── Gradient divider ───────────────────────────────────────
              _buildGradientDivider(),

              // ── Stats section ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _buildInlineStats(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gradient divider ──────────────────────────────────────────────────────
  Widget _buildGradientDivider() => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          accentColor.withValues(alpha: 0.35),
          accentColor.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.8, 1.0],
      ),
    ),
  );

  // ── Profile Image ─────────────────────────────────────────────────────────
  Widget _buildImage() => AnimatedBuilder(
    animation: pulseAnimation,
    builder: (_, __) {
      final t = pulseAnimation.value;
      return Stack(
        children: [
          // Glow behind image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.22 + t * 0.10),
                    blurRadius: 18 + t * 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          // Gradient border frame
          Container(
            width: 96,
            height: 116,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  _blue.withValues(alpha: 0.6),
                  accentColor.withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: profile.profileImageUrl != null
                  ? Image.network(
                profile.profileImageUrl!,
                width: 92,
                height: 112,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              )
                  : _imagePlaceholder(),
            ),
          ),
          // Online dot indicator
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
                border: Border.all(color: cardColor, width: 2),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _imagePlaceholder() => Container(
    width: 92,
    height: 112,
    color: accentColor.withValues(alpha: 0.08),
    child: Icon(Icons.person_rounded,
        size: 42, color: accentColor.withValues(alpha: 0.30)),
  );

  // ── Name + Badge + Pills ──────────────────────────────────────────────────
  Widget _buildInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      // Name
      Text(
        profile.fullName ?? SC.tr('memberName'),
        style: TextStyle(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          height: 1.2,
        ),
      ),

      if ((profile.fullNameBn ?? '').isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(
          profile.fullNameBn!,
          style: TextStyle(
            color: subTextColor.withValues(alpha: 0.55),
            fontSize: 12.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],

      const SizedBox(height: 10),

      // Badge
      _buildBadge(),

      const SizedBox(height: 7),

      // Member type pill
      _buildMemberTypePill(),

      const SizedBox(height: 8),

      // Member since small tag
      if (profile.memberSince != null)
        _buildSinceTag(),
    ],
  );

  Widget _buildBadge() {
    if (profile.isAdvisor) {
      return AdvisorBadge(
        designation: profile.designation,
        institution: profile.institution,
        accent: accentColor,
      );
    } else if (profile.isPreviousMember) {
      return TenureBadge(
        position: profile.previousPosition,
        tenureLabel: profile.tenureLabel,
        accent: accentColor,
      );
    }
    return PositionBadge(
      label: profile.committeePosition ?? SC.tr('volunteer'),
      accent: accentColor,
    );
  }

  Widget _buildMemberTypePill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          accentColor.withValues(alpha: 0.18),
          accentColor.withValues(alpha: 0.06),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: accentColor.withValues(alpha: 0.30),
        width: 0.8,
      ),
    ),
    child: Text(
      MemberType.label(profile.memberType),
      style: TextStyle(
        color: accentColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _buildSinceTag() {
    final d = profile.memberSince!;
    final label = '${SC.tr('memberSince')} ${d.year}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_rounded,
            size: 10, color: subTextColor.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: subTextColor.withValues(alpha: 0.5),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Inline Stats ──────────────────────────────────────────────────────────
  Widget _buildInlineStats() {
    final items = <_StatItem>[];

    // Blood group
    items.add(_StatItem(
      icon: Icons.water_drop_rounded,
      color: _red,
      label: SC.tr('bloodGroup'),
      value: profile.bloodGroup ?? '—',
    ));

    // Donations
    items.add(_StatItem(
      icon: Icons.favorite_rounded,
      color: _orange,
      label: SC.tr('donations'),
      value: '${profile.totalDonationCount ?? 0}',
    ));

    // 3rd stat based on type
    if (profile.isAdvisor) {
      items.add(_StatItem(
        icon: Icons.stars_rounded,
        color: _amber,
        label: SC.tr('expertise'),
        value: _shortWord(profile.expertise),
      ));
    } else if (profile.isPreviousMember) {
      items.add(_StatItem(
        icon: Icons.history_edu_rounded,
        color: _purple,
        label: SC.tr('tenure'),
        value: profile.tenureLabel.isNotEmpty ? profile.tenureLabel : '—',
      ));
    } else {
      final elig = profile.donationEligibility ?? '';
      final isElig = elig.toLowerCase().contains('eligible');
      items.add(_StatItem(
        icon: Icons.verified_rounded,
        color: isElig ? _green : _red,
        label: SC.tr('status'),
        value: isElig ? SC.tr('eligible') : (elig.isEmpty ? '—' : elig),
      ));
    }

    return Column(
      children: [
        // ── Stat chips row ─────────────────────────────────────────────
        Row(
          children: items.map((item) {
            final isLast = item == items.last;
            return Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildStatChip(item)),
                  if (!isLast)
                    Container(
                      width: 1,
                      height: 36,
                      color: accentColor.withValues(alpha: 0.12),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                ],
              ),
            );
          }).toList(),
        ),

        // ── Location rows ──────────────────────────────────────────────
        if (_hasLocation()) ...[
          const SizedBox(height: 12),
          _buildLocationDivider(),
          const SizedBox(height: 10),
          _buildLocationRows(),
        ],
      ],
    );
  }

  Widget _buildStatChip(_StatItem item) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: item.color.withValues(alpha: 0.12),
          border: Border.all(
            color: item.color.withValues(alpha: 0.20),
            width: 0.8,
          ),
        ),
        child: Icon(item.icon, color: item.color, size: 16),
      ),
      const SizedBox(height: 5),
      Text(
        item.value,
        style: TextStyle(
          color: item.color,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 2),
      Text(
        item.label,
        style: TextStyle(
          color: subTextColor.withValues(alpha: 0.65),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  Widget _buildLocationDivider() => Row(
    children: [
      Expanded(
        child: Container(
          height: 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              accentColor.withValues(alpha: 0.20),
            ]),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          Icons.location_on_rounded,
          size: 12,
          color: accentColor.withValues(alpha: 0.40),
        ),
      ),
      Expanded(
        child: Container(
          height: 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              accentColor.withValues(alpha: 0.20),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ],
  );

  Widget _buildLocationRows() {
    final rows = <Widget>[];

    // Present address (locationDms এর বদলে)
    if (profile.presentAddress != null && profile.presentAddress!.isNotEmpty) {
      rows.add(_locationRow(
        icon: Icons.home_work_rounded,
        color: _teal,
        value: profile.presentAddress!,
      ));
    }

    // District + Upazila
    final place = [
      if (profile.upazila != null && profile.upazila!.isNotEmpty)
        profile.upazila!,
      if (profile.district != null && profile.district!.isNotEmpty)
        profile.district!,

    ].join(', ');
    if (place.isNotEmpty) {
      rows.add(_locationRow(
        icon: Icons.home_rounded,
        color: _blue,
        value: place,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      children: rows
          .expand((w) => [w, const SizedBox(height: 7)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _locationRow({
    required IconData icon,
    required Color color,
    required String value,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.10),
            ),
            child: Icon(icon, color: color, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.78),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  // locationDms এর বদলে presentAddress চেক করছে
  bool _hasLocation() =>
      (profile.presentAddress != null && profile.presentAddress!.isNotEmpty) ||
          (profile.district != null && profile.district!.isNotEmpty) ||
          (profile.upazila != null && profile.upazila!.isNotEmpty);

  String _shortWord(String? s) {
    if (s == null || s.isEmpty) return '—';
    final first = s.split(RegExp(r'[,،]')).first.trim();
    return first.length > 8 ? '${first.substring(0, 8)}…' : first;
  }
}

// ── Stat Item Model ───────────────────────────────────────────────────────────
class _StatItem {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
}