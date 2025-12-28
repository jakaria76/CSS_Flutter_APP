import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase init
  await Supabase.initialize(
    url: 'https://dkhigqqmxzlyrbvxrsqa.supabase.co',
    anonKey: 'sb_publishable_nK4FKJ3KkOskR13_X_WQUA_CUEFb7PN',
  );

  // Onboarding seen check
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
      home: seenOnboarding
          ? const HomePage()
          : const OnboardingPage(),
    );
  }
}
