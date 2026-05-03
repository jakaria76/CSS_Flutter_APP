import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_constants.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() =>
      _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage>
    with SingleTickerProviderStateMixin {
  String _themeMode   = 'dark';
  double _fontSize    = 14.0;
  bool   _compactMode = false;

  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
        value: 0)
      ..forward();
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
      _themeMode   = p.getString('theme_mode') ?? 'dark';
      _fontSize    = p.getDouble('font_size')  ?? 14.0;
      _compactMode = p.getBool('compact_mode') ?? false;
    });
  }

  Future<void> _savePref(String key, dynamic val) async {
    final p = await SharedPreferences.getInstance();
    if (val is String) await p.setString(key, val);
    if (val is double) await p.setDouble(key, val);
    if (val is bool)   await p.setBool(key, val);
  }

  static const _themeOptions = [
    _ThemeOpt('dark',   Icons.dark_mode_rounded,    SC.indigo, 'ডার্ক মোড',  'কম আলোতে চোখের আরাম'),
    _ThemeOpt('light',  Icons.light_mode_rounded,   SC.amber,  'লাইট মোড',  'উজ্জ্বল পরিবেশের জন্য'),

  ];

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder — theme change হলে এই page ও সাথে সাথে rebuild হবে
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, themeVal, _) {
        final isDark = SC.isDark;

        // ── Dynamic colors based on theme ──────────────────────────────
        final bgColor       = isDark ? SC.bgStart           : const Color(0xFFF0F4FF);
        final textColor     = isDark ? Colors.white         : const Color(0xFF1A2332);
        final subTextColor  = isDark ? Colors.white         : const Color(0xFF1A2332);
        final cardColor     = isDark ? SC.cardBg            : Colors.white;
        final borderColor   = isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.08);
        final infoCardColor = isDark
            ? SC.indigo.withValues(alpha: 0.07)
            : SC.indigo.withValues(alpha: 0.06);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: _backButton(isDark, textColor),
              title: Text(
                'অ্যাপিয়ারেন্স',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18),
              ),
              centerTitle: true,
            ),
            body: Stack(children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                    gradient: SC.currentGradient),
              ),
              Positioned(
                  top: -60,
                  right: -60,
                  child: SC.blob(
                      240, SC.indigo.withValues(alpha: 0.05))),
              FadeTransition(
                opacity: _fadeCtrl,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                      18,
                      MediaQuery.of(context).padding.top + 90,
                      18,
                      40),
                  children: [

                    // ── Theme Mode ──────────────────────────────────────
                    _sectionHeader('থিম', Icons.palette_rounded,
                        SC.indigo, textColor),
                    _themedCard(
                      isDark: isDark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          for (int i = 0;
                          i < _themeOptions.length;
                          i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                                child: _themeCard(
                                    _themeOptions[i], isDark)),
                          ],
                        ]),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Font Size ───────────────────────────────────────
                    _sectionHeader('ফন্ট সাইজ',
                        Icons.text_fields_rounded, SC.cyan, textColor),
                    _themedCard(
                      isDark: isDark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text('টেক্সট সাইজ',
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                        fontWeight:
                                        FontWeight.w600)),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: SC.cyan
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                        color: SC.cyan
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                      '${_fontSize.toInt()}px',
                                      style: const TextStyle(
                                          color: SC.cyan,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Preview box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white
                                    .withValues(alpha: 0.03)
                                    : Colors.black
                                    .withValues(alpha: 0.03),
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white
                                        .withValues(alpha: 0.07)
                                        : Colors.black
                                        .withValues(
                                        alpha: 0.08)),
                              ),
                              child: Text(
                                'CSS - Computer Science Society',
                                style: TextStyle(
                                    color: textColor
                                        .withValues(alpha: 0.85),
                                    fontSize: _fontSize),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: SC.cyan,
                                inactiveTrackColor:
                                SC.cyan.withValues(alpha: 0.15),
                                thumbColor: SC.cyan,
                                overlayColor:
                                SC.cyan.withValues(alpha: 0.15),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: _fontSize,
                                min: 12,
                                max: 20,
                                divisions: 4,
                                onChanged: (v) {
                                  setState(() => _fontSize = v);
                                  _savePref('font_size', v);
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                for (final size in [12, 14, 16, 18, 20])
                                  Text(
                                    '$size',
                                    style: TextStyle(
                                      color: _fontSize ==
                                          size.toDouble()
                                          ? SC.cyan
                                          : textColor.withValues(
                                          alpha: 0.3),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Other preferences ───────────────────────────────
                    _sectionHeader('অন্যান্য', Icons.tune_rounded,
                        SC.orange, textColor),
                    _themedCard(
                      isDark: isDark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      child: _switchTile(
                        icon: Icons.view_compact_rounded,
                        color: SC.orange,
                        title: 'কমপ্যাক্ট মোড',
                        subtitle: 'কম জায়গায় বেশি কন্টেন্ট দেখুন',
                        value: _compactMode,
                        textColor: textColor,
                        onChanged: (v) {
                          setState(() => _compactMode = v);
                          _savePref('compact_mode', v);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Info note ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: infoCardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: SC.indigo.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: SC.indigo, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'থিম পরিবর্তন তাৎক্ষণিকভাবে প্রযোজ্য হবে।',
                              style: TextStyle(
                                  color:
                                  textColor.withValues(alpha: 0.55),
                                  fontSize: 12,
                                  height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ── Back button (theme-aware) ──────────────────────────────────────────────
  Widget _backButton(bool isDark, Color textColor) => Padding(
    padding: const EdgeInsets.all(10),
    child: ClipOval(
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.2)),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16),
          onPressed: () => Navigator.pop(context),
          color: textColor,
        ),
      ),
    ),
  );

  // ── Section header (theme-aware) ───────────────────────────────────────────
  Widget _sectionHeader(
      String title, IconData icon, Color color, Color textColor) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
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
                letterSpacing: 1.4),
          ),
        ]),
      );

  // ── Themed card wrapper ────────────────────────────────────────────────────
  Widget _themedCard({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Widget child,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.3 : 0.07),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: child,
      );

  // ── Theme option card ──────────────────────────────────────────────────────
  Widget _themeCard(_ThemeOpt opt, bool isDark) {
    final selected = _themeMode == opt.value;
    final unselectedTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.4);
    final unselectedSubColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);
    final unselectedBgColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.03);
    final unselectedBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () {
        setState(() => _themeMode = opt.value);
        _savePref('theme_mode', opt.value);
        SC.themeModeNotifier.value = opt.value;
        SC.toast(context, '${opt.label} সেট হয়েছে ✓', opt.color);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? opt.color.withValues(alpha: 0.12)
              : unselectedBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? opt.color.withValues(alpha: 0.5)
                : unselectedBorderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(children: [
          Icon(opt.icon,
              color: selected ? opt.color : unselectedTextColor,
              size: 26),
          const SizedBox(height: 8),
          Text(opt.label,
              style: TextStyle(
                  color: selected ? opt.color : unselectedTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(opt.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: unselectedSubColor,
                  fontSize: 9,
                  height: 1.4)),
        ]),
      ),
    );
  }

  // ── Switch tile (theme-aware) ──────────────────────────────────────────────
  Widget _switchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.45),
                          fontSize: 12)),
                ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withValues(alpha: 0.25),
            inactiveThumbColor:
            Colors.white.withValues(alpha: 0.3),
            inactiveTrackColor:
            Colors.white.withValues(alpha: 0.08),
          ),
        ]),
      );
}

class _ThemeOpt {
  final String value;
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  const _ThemeOpt(
      this.value, this.icon, this.color, this.label, this.subtitle);
}