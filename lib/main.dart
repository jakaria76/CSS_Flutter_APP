import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// PAGES
import 'onboarding_page.dart';
import 'welcome_page.dart';
import 'signup_page.dart';
import 'login_page.dart';
import 'member_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ================= SUPABASE INIT (CORRECT) =================
  await Supabase.initialize(
    url: 'https://dkhigqqmxzlyrbvxrsqa.supabase.co',
    anonKey: 'sb_publishable_nK4FKJ3KkOskR13_X_WQUA_CUEFb7PN',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // ✅ this is correct
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
      initialRoute: seenOnboarding ? '/welcome' : '/onboarding',
      routes: {
        '/onboarding': (_) => const OnboardingPage(),
        '/welcome': (_) => const WelcomePage(),
        '/signup': (_) => const SignupPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const MemberHome(isGuest: false),
      },
    );
  }
}
