import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// PAGES
import 'onboarding_page.dart';
import 'welcome_page.dart';
import 'pages/account/signup_page.dart';
import 'pages/account/login_page.dart';
import 'member_home.dart';

// SETTINGS
import 'pages/SettingsPage/settings_constants.dart';

// SERVICES
import 'services/auth_guard_service.dart'; // ✅ NEW

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ================= BENGALI LOCALE INITIALIZATION =================
  try {
    await initializeDateFormatting('bn', null);
    debugPrint('✅ Bengali locale initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Bengali locale initialization failed: $e');
  }

  // ================= SUPABASE INIT =================
  await Supabase.initialize(
    url: 'https://dkhigqqmxzlyrbvxrsqa.supabase.co',
    anonKey: 'sb_publishable_nK4FKJ3KkOskR13_X_WQUA_CUEFb7PN',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // ================= LOAD APP PREFERENCES =================
  await SC.loadAppPrefs();

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

  Widget _decideStartPage() {
    final session = Supabase.instance.client.auth.currentSession;

    if (!seenOnboarding) {
      return const OnboardingPage();
    }

    if (session != null) {
      // ✅ App reopen এ already logged in থাকলে AuthGuard চালু করো
      // BuildContext এখানে নেই, তাই _AuthStartWrapper দিয়ে handle করছি
      return const _AuthStartWrapper();
    }

    return const WelcomePage();
  }
}

/// ✅ Already logged-in user এর জন্য AuthGuard init করে তারপর MemberHome দেখায়
class _AuthStartWrapper extends StatefulWidget {
  const _AuthStartWrapper();

  @override
  State<_AuthStartWrapper> createState() => _AuthStartWrapperState();
}

class _AuthStartWrapperState extends State<_AuthStartWrapper> {
  @override
  void initState() {
    super.initState();
    // Widget build হওয়ার পরে context ready — guard চালু করো
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && mounted) {
        AuthGuardService.init(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MemberHome(isGuest: false);
  }
}