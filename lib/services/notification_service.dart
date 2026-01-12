import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // ===================================================
  // 🔹 STEP 0: INIT LOCAL NOTIFICATION + CHANNEL
  // ===================================================
  static Future<void> init() async {
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);

    // 🔔 Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'events', // 🔑 MUST match backend channel_id
      'Event Notifications',
      description: 'Notifications for new events',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ===================================================
  // 🔹 STEP 1: PERMISSION + TOKEN + SAVE TO SUPABASE
  // ===================================================
  static Future<void> initAndSaveToken() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('❌ Notification permission denied');
        return;
      }

      final token = await _fcm.getToken();
      if (token == null) return;

      print('✅ FCM TOKEN = $token');

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);

      print('✅ Token saved to Supabase');
    } catch (e) {
      print('❌ initAndSaveToken error: $e');
    }
  }

  // ===================================================
  // 🔹 STEP 2: FOREGROUND NOTIFICATION (WITH IMAGE SUPPORT)
  // ===================================================
  static void listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showNotificationWithImage(message);
    });
  }

  // ===================================================
  // 🔹 STEP 3: BACKGROUND HANDLER
  // ===================================================
  static Future<void> backgroundHandler(RemoteMessage message) async {
    await _showNotificationWithImage(message);
  }

  // ===================================================
  // 🔹 HELPER: SHOW NOTIFICATION LOGIC (BIG PICTURE)
  // ===================================================
  static Future<void> _showNotificationWithImage(RemoteMessage message) async {
    final data = message.data;
    if (data.isEmpty) return;

    final title = data['title'] ?? "New Notification";
    final body = data['body'] ?? "Click to see more";
    final imageUrl = data['image']; // ডাটা পেলোডে ইমেজ ইউআরএল থাকতে হবে

    BigPictureStyleInformation? bigPicture;

    // 🖼️ ইমেজ ডাউনলোডের লজিক
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/notif_image.jpg');
        await file.writeAsBytes(response.bodyBytes);

        bigPicture = BigPictureStyleInformation(
          FilePathAndroidBitmap(file.path),
          contentTitle: title,
          summaryText: body,
        );
      } catch (e) {
        print('❌ Image download error: $e');
      }
    }

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'events',
          'Event Notifications',
          icon: '@mipmap/ic_launcher',
          styleInformation: bigPicture, // এখানে বড় ইমেজটি সেট হচ্ছে
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ===================================================
  // 🔹 STEP 4: NOTIFICATION CLICK HANDLER
  // ===================================================
  static void listenClick() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👉 Notification clicked');
      print('Payload: ${message.data}');
      // এখানে আপনি চাইলে ইভেন্ট আইডি অনুযায়ী স্পেসিফিক পেজে নেভিগেট করতে পারেন
    });
  }
}