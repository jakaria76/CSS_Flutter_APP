import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class DataCachePage extends StatefulWidget {
  const DataCachePage({super.key});

  @override
  State<DataCachePage> createState() => _DataCachePageState();
}

class _DataCachePageState extends State<DataCachePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;

  // Cache sizes
  double _tempCacheBytes = 0;
  double _docCacheBytes = 0;
  bool _isCalculating = true;
  bool _isClearing = false;

  // Offline mode
  bool _isOffline = false;
  bool _isConnected = true;

  // SharedPreferences key
  static const String _offlineKey = 'offline_mode_enabled';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 0,
    )..forward();
    _loadOfflineMode();
    _checkConnectivity();
    _calculateAllCaches();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── SharedPreferences থেকে offline mode load ───
  Future<void> _loadOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isOffline = prefs.getBool(_offlineKey) ?? false;
    });
  }

  // ─── Offline mode save করা ───
  Future<void> _setOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineKey, value);
    if (!mounted) return;
    setState(() => _isOffline = value);
    SC.toast(
      context,
      value ? SC.tr('offline_mode_on_msg') : SC.tr('offline_mode_off_msg'),
      value ? SC.orange : SC.green,
    );
  }

  // ─── Real internet connectivity check ───
  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });

    // Real-time connectivity stream listen
    Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }

  // ─── সব cache size calculate করা ───
  Future<void> _calculateAllCaches() async {
    setState(() => _isCalculating = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final docDir = await getApplicationDocumentsDirectory();

      final tempSize = await _calculateDirSize(tempDir);
      final docSize = await _calculateDirSize(docDir);

      if (!mounted) return;
      setState(() {
        _tempCacheBytes = tempSize;
        _docCacheBytes = docSize;
        _isCalculating = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  // ─── Directory size calculate helper ───
  Future<double> _calculateDirSize(Directory dir) async {
    double size = 0;
    try {
      if (dir.existsSync()) {
        dir
            .listSync(recursive: true, followLinks: false)
            .forEach((entity) {
          if (entity is File) {
            try {
              size += entity.lengthSync();
            } catch (_) {}
          }
        });
      }
    } catch (_) {}
    return size;
  }

  // ─── MB format করা ───
  String _formatBytes(double bytes) {
    if (bytes <= 0) return '0.00 MB';
    final mb = bytes / (1024 * 1024);
    if (mb < 1) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${mb.toStringAsFixed(2)} MB';
  }

  // ─── Cache clear করা ───
  Future<void> _clearCache() async {
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => _isClearing = true);
    try {
      // 1. Temporary directory clear
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.listSync().forEach((entity) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        });
      }

      // 2. Documents directory থেকে cache folder clear
      final docDir = await getApplicationDocumentsDirectory();
      final cacheSubDir = Directory('${docDir.path}/cache');
      if (cacheSubDir.existsSync()) {
        cacheSubDir.deleteSync(recursive: true);
      }

      // 3. SharedPreferences থেকে শুধু cache-related keys clear
      // (offline_mode এবং app settings রেখে দেওয়া হচ্ছে)
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        // শুধু cache/temp related keys মুছুন
        if (key.startsWith('cache_') || key.startsWith('temp_')) {
          await prefs.remove(key);
        }
      }

      if (!mounted) return;
      SC.toast(context, SC.tr('cache_cleared_msg'), SC.green);
      await _calculateAllCaches();
    } catch (_) {
      if (mounted) SC.toast(context, SC.tr('cache_error_msg'), SC.red);
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  // ─── Confirmation Dialog ───
  Future<bool> _showConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = SC.isDark;
        final cardColor = isDark ? SC.cardBg : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
        final subTextColor = isDark
            ? Colors.white.withValues(alpha: 0.55)
            : const Color(0xFF4A5568);
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            SC.tr('confirm_clear_cache'),
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          content: Text(
            SC.tr('confirm_clear_cache_msg'),
            style: TextStyle(color: subTextColor, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(SC.tr('cancel'),
                  style: TextStyle(color: subTextColor)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(SC.tr('confirm'),
                  style: TextStyle(
                      color: SC.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    return result ?? false;
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
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.50)
        : const Color(0xFF4A5568);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.08);

    final totalBytes = _tempCacheBytes + _docCacheBytes;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
                decoration:
                BoxDecoration(gradient: SC.currentGradient)),
            Positioned(
              top: -60,
              right: -60,
              child: SC.blob(220, SC.teal.withValues(alpha: 0.05)),
            ),
            Column(
              children: [
                _buildAppBar(textColor),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeCtrl,
                    child: SingleChildScrollView(
                      padding:
                      const EdgeInsets.fromLTRB(18, 16, 18, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Storage Summary Card ──
                          _storageSummaryCard(
                            totalBytes: totalBytes,
                            tempBytes: _tempCacheBytes,
                            docBytes: _docCacheBytes,
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            borderColor: borderColor,
                            isCalculating: _isCalculating,
                          ),
                          const SizedBox(height: 28),

                          // ── Cache Section ──
                          _sectionHeader(
                            SC.tr('cache_management'),
                            Icons.cleaning_services_rounded,
                            SC.cyan,
                            subTextColor,
                          ),
                          const SizedBox(height: 12),
                          _customTile(
                            icon: Icons.delete_sweep_rounded,
                            accentColor: SC.cyan,
                            title: SC.tr('clear_cache'),
                            subtitle: SC.tr('delete_temp_files'),
                            trailing: _isClearing
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: SC.cyan, strokeWidth: 2),
                            )
                                : Text(
                              _isCalculating
                                  ? '...'
                                  : _formatBytes(totalBytes),
                              style: TextStyle(
                                  color: SC.cyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            onTap: (_isClearing || _isCalculating)
                                ? null
                                : _clearCache,
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 28),

                          // ── Network & Offline Section ──
                          _sectionHeader(
                            SC.tr('offline_settings'),
                            Icons.wifi_off_rounded,
                            SC.orange,
                            subTextColor,
                          ),
                          const SizedBox(height: 12),

                          // Network status indicator
                          _networkStatusCard(
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 10),

                          // Offline toggle
                          _customTile(
                            icon: Icons.cloud_off_rounded,
                            accentColor: SC.orange,
                            title: SC.tr('offline_mode'),
                            subtitle: SC.tr('use_without_internet'),
                            trailing: Switch(
                              value: _isOffline,
                              onChanged: _setOfflineMode,
                              activeColor: SC.cyan,
                              materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                            ),
                            onTap: () => _setOfflineMode(!_isOffline),
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            borderColor: borderColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Storage Summary Card ──
  Widget _storageSummaryCard({
    required double totalBytes,
    required double tempBytes,
    required double docBytes,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required bool isCalculating,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: SC.purple, size: 18),
              const SizedBox(width: 8),
              Text(
                SC.tr('storage_usage'),
                style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isCalculating
              ? Center(
              child: CircularProgressIndicator(
                  color: SC.cyan, strokeWidth: 2))
              : Column(
            children: [
              _storageRow(SC.tr('temp_cache'),
                  _formatBytes(tempBytes), SC.cyan, textColor, subTextColor),
              const SizedBox(height: 10),
              _storageRow(SC.tr('app_documents'),
                  _formatBytes(docBytes), SC.purple, textColor, subTextColor),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: borderColor),
              ),
              _storageRow(SC.tr('total_storage'),
                  _formatBytes(totalBytes), SC.orange, textColor, subTextColor,
                  isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _storageRow(String label, String value, Color accent,
      Color textColor, Color subTextColor,
      {bool isBold = false}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal)),
        ),
        Text(value,
            style: TextStyle(
                color: isBold ? accent : textColor,
                fontSize: 13,
                fontWeight:
                isBold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }

  // ── Network Status Card ──
  Widget _networkStatusCard({
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    final statusColor = _isConnected ? SC.green : SC.red;
    final statusText = _isConnected
        ? SC.tr('connected')
        : SC.tr('disconnected');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            '${SC.tr('network_status')}: $statusText',
            style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── AppBar ──
  Widget _buildAppBar(Color textColor) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10, bottom: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              SC.tr('data_cache_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Section Header ──
  Widget _sectionHeader(
      String title, IconData icon, Color accent, Color subTextColor) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8),
        ),
      ],
    );
  }

  // ── Custom Tile ──
  Widget _customTile({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style:
                      TextStyle(color: subTextColor, fontSize: 12)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}