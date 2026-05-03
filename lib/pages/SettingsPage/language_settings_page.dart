import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_constants.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage>
    with SingleTickerProviderStateMixin {
  String _selected = 'বাংলা';
  late AnimationController _fadeCtrl;

  static const _languages = [
    _LangOption(
      code: 'বাংলা',
      nativeName: 'বাংলা',
      englishName: 'Bengali',
      flag: '🇧🇩',
    ),
    _LangOption(
      code: 'English',
      nativeName: 'English',
      englishName: 'English',
      flag: '🇬🇧',
    ),
  ];

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
    setState(() => _selected = p.getString('language') ?? 'বাংলা');
  }

  Future<void> _select(String code) async {
    setState(() => _selected = code);
    final p = await SharedPreferences.getInstance();
    await p.setString('language', code);
    SC.languageNotifier.value = code;
    if (!mounted) return;
    SC.toast(context, SC.tr('lang_changed').replaceAll('@lang', code), SC.purple);
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
    final isDark = SC.isDark;
    final cardColor = isDark ? SC.cardBg : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF4A5568);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          Container(decoration: BoxDecoration(gradient: SC.currentGradient)),
          Positioned(
              top: -60,
              right: -60,
              child: SC.blob(240, SC.purple.withValues(alpha: 0.05))),
          Positioned(
              bottom: 100,
              left: -80,
              child: SC.blob(200, SC.blue.withValues(alpha: 0.04))),
          Column(
            children: [
              _buildAppBar(textColor),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SC.purple.withValues(alpha: 0.1),
                            border: Border.all(color: SC.purple.withValues(alpha: 0.3), width: 1.5),
                            boxShadow: [BoxShadow(color: SC.purple.withValues(alpha: 0.15), blurRadius: 30)],
                          ),
                          child: const Icon(Icons.translate_rounded, color: SC.purple, size: 42),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          SC.tr('choose_lang_desc'),
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 36),

                      for (final lang in _languages) ...[
                        _langCard(lang, cardColor, textColor, subTextColor, borderColor),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SC.purple.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: SC.purple.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: SC.purple, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                SC.tr('lang_info_tip'),
                                style: TextStyle(color: subTextColor, fontSize: 12, height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildAppBar(Color textColor) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              SC.tr('lang_settings_title'),
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _langCard(_LangOption lang, Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    final isSelected = _selected == lang.code;
    return GestureDetector(
      onTap: () => _select(lang.code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? SC.purple.withValues(alpha: 0.12) : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? SC.purple.withValues(alpha: 0.5) : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(children: [
          Text(lang.flag, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lang.nativeName,
                  style: TextStyle(
                      color: isSelected ? SC.purple : textColor, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(lang.englishName, style: TextStyle(color: subTextColor, fontSize: 13)),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SC.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(SC.tr('default_lang'),
                      style: const TextStyle(color: SC.purple, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? SC.purple : Colors.transparent,
              border: Border.all(
                  color: isSelected ? SC.purple : subTextColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
          ),
        ]),
      ),
    );
  }

  bool get isDark => SC.isDark;
}

class _LangOption {
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;
  const _LangOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
  });
}