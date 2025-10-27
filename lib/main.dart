import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/language_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'web/landing_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'services/onboarding_service.dart'; // ✅ newly added

const bool _useAuthEmulator =
    bool.fromEnvironment('USE_AUTH_EMULATOR', defaultValue: false);
const String _authEmulatorHost =
    String.fromEnvironment('AUTH_EMULATOR_HOST', defaultValue: '');
const int _authEmulatorPort =
    int.fromEnvironment('AUTH_EMULATOR_PORT', defaultValue: 9099);

const bool _useFirestoreEmulator =
    bool.fromEnvironment('USE_FIRESTORE_EMULATOR', defaultValue: false);
const String _firestoreEmulatorHost =
    String.fromEnvironment('FIRESTORE_EMULATOR_HOST', defaultValue: '');
const int _firestoreEmulatorPort =
    int.fromEnvironment('FIRESTORE_EMULATOR_PORT', defaultValue: 8080);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await FirebaseAppCheck.instance.activate(
      appleProvider: AppleProvider.debug,
      androidProvider: AndroidProvider.debug,
    );
    debugPrint('[app_check] Debug providers active');
  } catch (e) {
    debugPrint('[app_check] Skipped activating debug provider: $e');
  }

  if (kDebugMode) {
    final String defaultHost = _defaultEmulatorHost();

    if (_useAuthEmulator) {
      final host =
          _authEmulatorHost.isNotEmpty ? _authEmulatorHost : defaultHost;
      await FirebaseAuth.instance.useAuthEmulator(host, _authEmulatorPort);
      debugPrint('[auth] Using Auth emulator at $host:$_authEmulatorPort');
    }

    if (_useFirestoreEmulator) {
      final host = _firestoreEmulatorHost.isNotEmpty
          ? _firestoreEmulatorHost
          : defaultHost;
      FirebaseFirestore.instance.useFirestoreEmulator(
          host, _firestoreEmulatorPort);
      debugPrint(
          '[firestore] Using Firestore emulator at $host:$_firestoreEmulatorPort');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const ReclaimApp(),
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
      routes: {
        '/onboarding_screen': (context) => const OnboardingScreen(),
        '/home_screen': (context) => const HomeScreen(),
        '/sign_in_screen': (context) => const SignInScreen(),
      },
      home: kIsWeb
          ? const LandingPage()
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _Splash();
                }

                if (!snapshot.hasData) {
                  return const SignInScreen();
                }

                final user = snapshot.data!;
                return FutureBuilder<bool>(
                  future: _ensureUserDocSafe(user),
                  builder: (context, userDoc) {
                    if (userDoc.connectionState != ConnectionState.done) {
                      return const _Splash();
                    }
                    if (userDoc.data == false) {
                      return const SignInScreen();
                    }

                    // ✅ NEW: Check onboarding progress from Firestore
                    return FutureBuilder<Widget>(
                      future: OnboardingService.getNextScreen(),
                      builder: (context, next) {
                        if (next.connectionState != ConnectionState.done) {
                          return const _Splash();
                        }
                        return next.data ?? const HomeScreen();
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

Future<bool> _ensureUserDocSafe(User user) async {
  try {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  } catch (e) {
    debugPrint('❌ Firestore ensureUserDoc failed: $e — signing out');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    return false;
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
}

String _defaultEmulatorHost() {
  if (kIsWeb) return 'localhost';
  if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
  return 'localhost';
}
