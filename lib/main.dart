import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

// SERVICES
import 'package:css/services/notification_service.dart';

// PAGES
import 'onboarding_page.dart';
import 'welcome_page.dart';
import 'pages/account/signup_page.dart';
import 'pages/account/login_page.dart';
import 'member_home.dart';

// 🔔 Notification plugin (Global)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 🔔 Android notification channel
const AndroidNotificationChannel eventChannel = AndroidNotificationChannel(
  'events',
  'Event Notifications',
  description: 'Notifications for new events',
  importance: Importance.high,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ================= BENGALI LOCALE INITIALIZATION =================
  try {
    await initializeDateFormatting('bn', null);
    debugPrint('✅ Bengali locale initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Bengali locale initialization failed: $e');
    // Continue anyway with default locale
  }

  // ================= FIREBASE & NOTIFICATION INIT =================
  if (!kIsWeb) {
    await Firebase.initializeApp();

    await NotificationService.init();

    final androidPlugin =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(eventChannel);

    FirebaseMessaging.onBackgroundMessage(
        NotificationService.backgroundHandler);
  }

  // ================= SUPABASE INIT =================
  await Supabase.initialize(
    url: 'https://dkhigqqmxzlyrbvxrsqa.supabase.co',
    anonKey: 'sb_publishable_nK4FKJ3KkOskR13_X_WQUA_CUEFb7PN',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // ================= ONBOARDING CHECK =================
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSS Mobile App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _decideStartPage(),
      routes: {
        '/onboarding': (_) => const OnboardingPage(),
        '/welcome': (_) => const WelcomePage(),
        '/signup': (_) => const SignupPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) {
          final user = Supabase.instance.client.auth.currentUser;
          return MemberHome(isGuest: user == null);
        },
      },
    );
  }

  /// 🔐 Facebook-style startup decision
  Widget _decideStartPage() {
    final session = Supabase.instance.client.auth.currentSession;

    // 1️⃣ Onboarding first (only once)
    if (!seenOnboarding) {
      return const OnboardingPage();
    }

    // 2️⃣ If session exists → auto login
    if (session != null) {
      return const MemberHome(isGuest: false);
    }

    // 3️⃣ No session → welcome / login
    return const WelcomePage();
  }
}