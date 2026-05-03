import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationHelper {
  static final _db = Supabase.instance.client;

  /// একজন নির্দিষ্ট user কে notification পাঠাও
  static Future<void> send({
    required String userId,
    required String titleKey,
    required String bodyKey,
    required String type,
    String? senderName,
    String? requestId,     // ✅ Blood request id (UUID)
    String? eventId,
    String? noticeId,
    String? complaintId,
    String? postId,
  }) async {
    try {
      await _db.from('notifications').insert({
        'user_id':    userId,
        'title_key':  titleKey,
        'body_key':   bodyKey,
        'type':       type,
        'is_read':    false,
        // স্কিমা অনুযায়ী আন্ডারস্কোর কলাম নামগুলো নিশ্চিত করা হয়েছে
        if (senderName  != null) 'sender_name':  senderName,
        if (requestId   != null) 'request_id':   requestId,
        if (eventId     != null) 'event_id':     eventId,
        if (noticeId    != null) 'notice_id':    noticeId,
        if (complaintId != null) 'complaint_id': complaintId,
        if (postId      != null) 'post_id':      postId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ NotificationHelper.send error: $e');
    }
  }

  /// সব user-কে একসাথে notification পাঠাও
  static Future<void> sendToAll({
    required String titleKey,
    required String bodyKey,
    required String type,
    String? excludeUserId,
    String? senderName,
    String? requestId,     // ✅ added
    String? noticeId,
    String? postId,
    String? eventId,
    String? complaintId,
  }) async {
    try {
      // ইউজার প্রোফাইল ফেচ করা
      final users = await _db.from('profiles').select('id');
      final userList = users as List;

      if (userList.isEmpty) {
        debugPrint('⚠️ No users found in profiles table');
        return;
      }

      final now = DateTime.now().toIso8601String();

      // ইনসার্ট করার জন্য রো (rows) তৈরি করা
      final rows = userList
          .map((u) => u['id'] as String?)
          .where((uid) => uid != null && uid != excludeUserId)
          .map((uid) => {
        'user_id':   uid,
        'title_key': titleKey,
        'body_key':  bodyKey,
        'type':      type,
        'is_read':   false,
        'created_at': now,
        if (senderName  != null) 'sender_name':  senderName,
        if (requestId   != null) 'request_id':   requestId, // ✅ ডাটাবেসের সঠিক কলাম নাম
        if (noticeId    != null) 'notice_id':    noticeId,
        if (postId      != null) 'post_id':      postId,
        if (eventId     != null) 'event_id':     eventId,
        if (complaintId != null) 'complaint_id': complaintId,
      })
          .toList();

      if (rows.isEmpty) {
        debugPrint('⚠️ No recipients after exclusion');
        return;
      }

      // Bulk Insert
      await _db.from('notifications').insert(rows);
      debugPrint('✅ sendToAll done: ${rows.length} notifications sent');
    } catch (e) {
      debugPrint('❌ NotificationHelper.sendToAll error: $e');
    }
  }

  // ── Helper: Current User-এর full_name fetch করো ──────────────────
  static Future<String?> _fetchCurrentUserName() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return null;
      final data = await _db
          .from('profiles')
          .select('full_name')
          .eq('id', uid)
          .single();
      return data['full_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Blood request নোটিফিকেশন
  static Future<void> sendBloodRequest({
    required String excludeUserId,
    String? requesterName,
    String? requestId, // ✅ requestId গ্রহণ করছে
  }) async {
    final name = requesterName ?? await _fetchCurrentUserName();
    await sendToAll(
      titleKey:      'blood_request_title',
      bodyKey:       'blood_request_body',
      type:          'blood_request',
      excludeUserId: excludeUserId,
      senderName:    name,
      requestId:     requestId, // ✅ sendToAll-এ পাস করা হচ্ছে
    );
  }

  /// Event notification
  static Future<void> sendEventNotification({
    required String excludeUserId,
    required String eventId,
    String? creatorName,
  }) async {
    final name = creatorName ?? await _fetchCurrentUserName();
    await sendToAll(
      titleKey:      'event_notification',
      bodyKey:       'event_notification_body',
      type:          'event_notification',
      excludeUserId: excludeUserId,
      eventId:       eventId,
      senderName:    name,
    );
  }

  /// Notice notification
  static Future<void> sendNoticeNotification({
    required String excludeUserId,
    required String noticeId,
    String? publisherName,
  }) async {
    final name = publisherName ?? await _fetchCurrentUserName();
    await sendToAll(
      titleKey:      'notice_new_title',
      bodyKey:       'notice_new_body',
      type:          'notice',
      excludeUserId: excludeUserId,
      noticeId:      noticeId,
      senderName:    name,
    );
  }

  /// Post notification
  static Future<void> sendPostNotification({
    required String excludeUserId,
    required String postId,
    String? posterName,
  }) async {
    final name = posterName ?? await _fetchCurrentUserName();
    await sendToAll(
      titleKey:      'new_post_title',
      bodyKey:       'new_post_body',
      type:          'new_post',
      excludeUserId: excludeUserId,
      postId:        postId,
      senderName:    name,
    );
  }

  /// Complaint reply
  static Future<void> sendComplaintReply({
    required String toUserId,
    required String complaintId,
    String? adminName,
  }) async {
    final name = adminName ?? await _fetchCurrentUserName();
    await send(
      userId:      toUserId,
      titleKey:    'complaint_replied_title',
      bodyKey:     'complaint_replied_body',
      type:        'complaint_reply',
      complaintId: complaintId,
      senderName:  name,
    );
  }
}