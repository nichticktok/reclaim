import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../features/onboarding/presentation/services/onboarding_service.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/tasks/presentation/screens/task_detail_screen.dart';
import '../web/landing_page.dart';
import '../providers/language_provider.dart';

class ReclaimApp extends StatelessWidget {
  const ReclaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'Reclaim',
          debugShowCheckedModeBanner: false,
          // Localization configuration
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LanguageProvider.supportedLocales,
          locale: languageProvider.locale,
          routes: {
        '/onboarding_screen': (context) => const OnboardingScreen(),
        '/home_screen': (context) => HomeScreen(), // Remove const to ensure Provider context is available
        '/sign_in_screen': (context) => const SignInScreen(),
        '/task_detail': (context) => const TaskDetailScreen(),
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

                    // Check onboarding progress from Firestore
                    return FutureBuilder<Map<String, dynamic>>(
                      future: OnboardingService.getNextScreenInfo(),
                      builder: (context, next) {
                        if (next.connectionState != ConnectionState.done) {
                          return const _Splash();
                        }
                        
                        final screenInfo = next.data;
                        if (screenInfo == null) {
                          return const HomeScreen();
                        }
                        
                        // Build widget in the correct context
                        final screenType = screenInfo['screen'] as String;
                        if (screenType == 'onboarding') {
                          final step = screenInfo['step'] as int? ?? 0;
                          return OnboardingScreen(startStep: step);
                        } else {
                          return const HomeScreen();
                        }
                      },
                    );
                  },
                );
              },
            ),
        );
      },
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
  const _Splash();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
}

