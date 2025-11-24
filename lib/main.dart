
// trying to test firebase emulators in debug mode
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show
        debugPrint,
        kDebugMode,
        kIsWeb,
        TargetPlatform,
        defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'app/app.dart';
import 'app/di.dart';
import 'app/env.dart';
import 'features/projects/data/services/ai_project_planning_service.dart';



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

    if (AppEnv.useAuthEmulator) {
      final host = AppEnv.authEmulatorHost.isNotEmpty
          ? AppEnv.authEmulatorHost
          : defaultHost;
      await FirebaseAuth.instance.useAuthEmulator(host, AppEnv.authEmulatorPort);
      debugPrint('[auth] Using Auth emulator at $host:${AppEnv.authEmulatorPort}');
    }

    if (AppEnv.useFirestoreEmulator) {
      final host = AppEnv.firestoreEmulatorHost.isNotEmpty
          ? AppEnv.firestoreEmulatorHost
          : defaultHost;
      FirebaseFirestore.instance.useFirestoreEmulator(
          host, AppEnv.firestoreEmulatorPort);
      debugPrint(
          '[firestore] Using Firestore emulator at $host:${AppEnv.firestoreEmulatorPort}');
    }
  }

  // Initialize Gemini AI
  final apiKey = AIProjectPlanningService.getApiKey();
  if (apiKey.isNotEmpty) {
    Gemini.init(apiKey: apiKey, enableDebugging: kDebugMode);
    debugPrint('[gemini] Gemini AI initialized');
  } else {
    debugPrint('[gemini] Warning: Gemini API key not configured');
  }

  runApp(
    MultiProvider(
      providers: AppProviders.providers,
      child: const ReclaimApp(),
    ),
  );
}

String _defaultEmulatorHost() {
  if (kIsWeb) return 'localhost';
  if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
  return 'localhost';
}

