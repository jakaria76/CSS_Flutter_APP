import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'package:css/pages/Blood/blood_groups_page.dart';

class BloodDashboardSectionWidget extends StatelessWidget {
  final bool isDark;
  final bool isLoading;
  final int totalDonors;
  final int readyDonors;

  const BloodDashboardSectionWidget({
    super.key,
    required this.isDark,
    required this.isLoading,
    required this.totalDonors,
    required this.readyDonors,
  });

  double get _eligibleRatio =>
      totalDonors == 0 ? 0 : (readyDonors / totalDonors).clamp(0.0, 1.0);

  // Green palette
  static const Color _green = Color(0xFF1DB954);
  static const Color _greenDeep = Color(0xFF0F7A38);
  static const Color _greenLight = Color(0xFF4ADE80);
  static const Color _greenMint = Color(0xFF00C9A7);

  @override
  Widget build(BuildContext context) {
    final Color cardBg = isDark ? const Color(0xFF111C16) : const Color(0xFFF0FBF4);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A2E1A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BloodGroupsPage()),
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? _green.withValues(alpha: 0.25)
                      : _green.withValues(alpha: 0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: isDark ? 0.12 : 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  if (!isDark)
                    BoxShadow(
                      color: _greenMint.withValues(alpha: 0.07),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeroSection(isDark, textColor),
                  _buildDivider(isDark),
                  _buildStatsGrid(isDark, textColor),
                  _buildProgressBar(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_green, _greenMint],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              )
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          SC.tr('bloodNetwork').toUpperCase(),
          style: const TextStyle(
            color: _green,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
            _green.withValues(alpha: 0.18),
            _greenMint.withValues(alpha: 0.05),
            Colors.transparent,
          ]
              : [
            _green.withValues(alpha: 0.08),
            _greenMint.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon with layered glow rings
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _green.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _green.withValues(alpha: 0.25),
                      _greenMint.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(Icons.water_drop_rounded, color: _greenLight, size: 17),
            ],
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isLoading
                    ? _LoadingPill(isDark: isDark, width: 110)
                    : RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$readyDonors ',
                        style: TextStyle(
                          color: isDark ? _greenLight : _greenDeep,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: SC.tr('readyDonors'),
                        style: const TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  SC.tr('donorsAvailableNow'),
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Arrow button
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _green.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: _green,
              size: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _green.withValues(alpha: isDark ? 0.2 : 0.12),
            _greenMint.withValues(alpha: isDark ? 0.15 : 0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            icon: Icons.people_alt_rounded,
            label: SC.tr('totalDonors'),
            value: isLoading ? '-' : totalDonors.toString(),
            color: const Color(0xFF1DB954),
            isDark: isDark,
          ),
          _verticalDivider(isDark),
          _statItem(
            icon: Icons.check_circle_rounded,
            label: SC.tr('eligibleNow'),
            value: isLoading ? '-' : readyDonors.toString(),
            color: const Color(0xFF00C9A7),
            isDark: isDark,
          ),
          _verticalDivider(isDark),
          _statItem(
            icon: Icons.bloodtype_rounded,
            label: SC.tr('bloodGroups'),
            value: '8',
            color: const Color(0xFF4ADE80),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _green.withValues(alpha: isDark ? 0.2 : 0.12),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final double ratio = isLoading ? 0.05 : _eligibleRatio;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                SC.tr('eligibleNow'),
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: _greenMint,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(ratio * 100).toInt()}%',
                    style: TextStyle(
                      color: isDark ? _greenLight : _greenDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: isDark ? 0.12 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_green, _greenMint],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  final bool isDark;
  final double width;
  const _LoadingPill({required this.isDark, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 22,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white10
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}