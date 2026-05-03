import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static final _supabase = Supabase.instance.client;

  /// Current session-এর stable key পাও
  static String? getCurrentSessionKey() {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.refreshToken?.hashCode.toString() ??
        session?.accessToken.hashCode.toString();
  }

  /// Login সফল হলে এই function call করুন
  static Future<void> saveSession() async {
    try {
      final user = _supabase.auth.currentUser;
      final session = _supabase.auth.currentSession;
      if (user == null || session == null) return;

      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Unknown';
      String deviceModel = 'Unknown';
      String osVersion = 'Unknown';

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceName = info.brand;
        deviceModel = info.model;
        osVersion = 'Android ${info.version.release}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceName = 'Apple';
        deviceModel = info.utsname.machine;
        osVersion = 'iOS ${info.systemVersion}';
      }

      final sessionKey = session.accessToken.hashCode.toString();

      await _supabase.from('user_sessions').upsert({
        'user_id': user.id,
        'device_name': deviceName,
        'device_model': deviceModel,
        'os_version': osVersion,
        'session_key': sessionKey,
        'last_active': DateTime.now().toIso8601String(),
      }, onConflict: 'session_key');
    } catch (e) {
      // silent fail — session save না হলে login block হবে না
    }
  }

  /// Logout-এর সময় call করুন
  static Future<void> deleteCurrentSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;
      final sessionKey = session.accessToken.hashCode.toString();
      await _supabase
          .from('user_sessions')
          .delete()
          .eq('session_key', sessionKey);
    } catch (_) {}
  }
}