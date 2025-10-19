import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/sign_in_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ReclaimApp());
}

class ReclaimApp extends StatelessWidget {
  const ReclaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reclaim',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return const HomeScreen(); // user logged in
          } else {
            return const SignInScreen(); // user not logged in
          }
        },
      ),
    );
  }
}
