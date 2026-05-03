import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ActivityLogger {
  static final _db = Supabase.instance.client;

  static Future<void> log({
    required String activityType,
    String? detail,
    String? device,
    String? location,
  }) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;
      await _db.from('account_activities').insert({
        'user_id': userId,
        'activity_type': activityType,
        'detail': detail,
        'device': device,
        'location': location,
      });
    } catch (e) {
      debugPrint('ActivityLogger error: $e');
    }
  }
}