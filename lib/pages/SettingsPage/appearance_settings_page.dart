import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_constants.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage>
    with SingleTickerProviderStateMixin {
  String _themeMode = 'dark';
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
    )..forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _themeMode = p.getString('theme_mode') ?? 'dark';
    });
  }

  Future<void> _saveTheme(String val) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('theme_mode', val);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    final isDark       = SC.isDark;
    final textColor    = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF4A5568);
    final cardColor    = isDark ? SC.cardBg : Colors.white;
    final borderColor  = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          // ── Background ────────────────────────────────────────
          Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
          Positioned(
            top: -60, right: -60,
            child: SC.blob(240, SC.indigo.withValues(alpha: isDark ? 0.06 : 0.04)),
          ),
          Positioned(
            bottom: 150, left: -80,
            child: SC.blob(200, SC.cyan.withValues(alpha: isDark ? 0.04 : 0.03)),
          ),

          SafeArea(
            top: false,
            child: Column(children: [
              _buildAppBar(textColor, isDark),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 48),
                    children: [

                      // ── Section Header ──────────────────────────
                      _sectionLabel(
                        SC.tr('theme_section'),
                        Icons.palette_rounded,
                        SC.indigo,
                        textColor,
                      ),
                      const SizedBox(height: 12),

                      // ── Theme Cards ─────────────────────────────
                      _buildThemeCard(
                        isDark: isDark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ),
                      const SizedBox(height: 24),

                      // ── Info Note ───────────────────────────────
                      _buildInfoNote(isDark, textColor),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(Color textColor, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 12,
      ),
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ClipOval(
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.12),
                ),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            SC.tr('appearance_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 56),
      ]),
    );
  }

  // ── Theme Card Container ───────────────────────────────────────────────────
  Widget _buildThemeCard({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        // Dark Mode Option
        Expanded(
          child: _themeOption(
            value: 'dark',
            icon: Icons.dark_mode_rounded,
            label: SC.tr('dark_mode_label'),
            subtitle: SC.tr('dark_mode_sub'),
            color: SC.indigo,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        // Light Mode Option
        Expanded(
          child: _themeOption(
            value: 'light',
            icon: Icons.light_mode_rounded,
            label: SC.tr('light_mode_label'),
            subtitle: SC.tr('light_mode_sub'),
            color: SC.amber,
            isDark: isDark,
          ),
        ),
      ]),
    );
  }

  // ── Individual Theme Option ────────────────────────────────────────────────
  Widget _themeOption({
    required String value,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    final selected = _themeMode == value;

    final unselectedText = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.35);
    final unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.03);
    final unselectedBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: () {
        if (_themeMode == value) return;
        setState(() => _themeMode = value);
        _saveTheme(value);
        SC.themeModeNotifier.value = value;
        SC.toast(context, SC.tr('theme_set_msg'), color);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.13 : 0.09)
              : unselectedBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : unselectedBorder,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.18)
                    : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.35)
                      : Colors.transparent,
                ),
              ),
              child: Icon(
                icon,
                color: selected ? color : unselectedText,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),

            // Label
            Text(
              label,
              style: TextStyle(
                color: selected ? color : unselectedText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.28),
                fontSize: 10,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),

            // Selected indicator
            AnimatedOpacity(
              opacity: selected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: color, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Active',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info Note ──────────────────────────────────────────────────────────────
  Widget _buildInfoNote(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.indigo.withValues(alpha: isDark ? 0.07 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: SC.indigo.withValues(alpha: isDark ? 0.2 : 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: SC.indigo, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              SC.tr('appearance_info'),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(
      String title, IconData icon, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ]),
    );
  }
}