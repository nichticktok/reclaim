import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // ✅ added
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'providers/language_provider.dart'; // ✅ added
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'web/landing_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(), // ✅ provides global language context
      builder: (context, _) => const ReclaimApp(),
    ),
  );
}

class ReclaimApp extends StatelessWidget {
  const ReclaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reclaim',
      debugShowCheckedModeBanner: false,

      // ✅ Add routes here
      routes: {
        '/onboarding_screen': (context) => const OnboardingScreen(),
        '/home_screen': (context) => const HomeScreen(),
        '/sign_in_screen': (context) => const SignInScreen(),
      },

      // ✅ Auth logic remains unchanged
      home: kIsWeb
          ? const LandingPage()
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: Colors.black,
                    body: Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  );
                } else if (snapshot.hasData) {
                  return const HomeScreen(); // ✅ User logged in
                } else {
                  return const SignInScreen(); // ✅ User not logged in
                }
              },
            ),
    );
  }
}
