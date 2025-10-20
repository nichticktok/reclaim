// lib/auth/login_logic.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'dart:io' show Platform;

typedef InfoHandler = void Function(String);

const bool _useFunctionsEmulator =
    bool.fromEnvironment('USE_FUNCTIONS_EMULATOR', defaultValue: false);
const String _functionsRegion =
    String.fromEnvironment('FUNCTIONS_REGION', defaultValue: 'us-central1');
const String _functionsEmulatorHost =
    String.fromEnvironment('FUNCTIONS_EMULATOR_HOST', defaultValue: '');
const int _functionsEmulatorPort =
    int.fromEnvironment('FUNCTIONS_EMULATOR_PORT', defaultValue: 5001);

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: _functionsRegion);

  AuthController() {
    // If you run the functions emulator on your dev machine, enable emulator here.
    // For the iOS Simulator localhost is fine; for Android emulator use 10.0.2.2
    if (kDebugMode && _useFunctionsEmulator) {
      String host;
      if (_functionsEmulatorHost.isNotEmpty) {
        host = _functionsEmulatorHost;
      } else if (Platform.isAndroid) {
        host = '10.0.2.2';
      } else if (Platform.isIOS || Platform.isMacOS) {
        host = 'localhost';
      } else {
        host = '127.0.0.1';
      }
      debugPrint(
        '[auth] Using Functions emulator at $host:$_functionsEmulatorPort '
        '(region $_functionsRegion)',
      );
      _functions.useFunctionsEmulator(host, _functionsEmulatorPort);
    } else {
      debugPrint(
        '[auth] Using deployed Functions in region $_functionsRegion '
        '(emulator: $_useFunctionsEmulator, debug: $kDebugMode)',
      );
    }
  }

  /// Ask backend to generate + email a 6-digit code and cache the email locally.
  Future<void> requestCode({required String email}) async {
    final callable = _functions.httpsCallable('auth_requestCode');
    try {
      await callable.call(<String, dynamic>{'email': email});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingEmail', email);
      debugPrint('[auth] requestCode succeeded for $email');
    } on FirebaseFunctionsException catch (fe) {
      debugPrint('[auth] Cloud Function error: code=${fe.code} message=${fe.message} details=${fe.details}');
      // common guidance for NOT_FOUND
      if (fe.code == 'not-found') {
        debugPrint('[auth] NOT_FOUND — check function name and region, and that functions are deployed.');
      }
      rethrow;
    } catch (e, st) {
      debugPrint('[auth] requestCode failed: $e\n$st');
      rethrow;
    }
  }

  /// Verify code with backend, receive a custom token, and sign in.
  Future<void> verifyCode({required String email, required String code}) async {
    final callable = _functions.httpsCallable('auth_verifyCode');
    try {
      final res = await callable.call(<String, dynamic>{
        'email': email,
        'code': code,
      });
      final data = (res.data as Map);
      final token = data['customToken'] as String;
      await _auth.signInWithCustomToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pendingEmail');
      debugPrint('[auth] verifyCode succeeded for $email');
    } on FirebaseFunctionsException catch (fe) {
      debugPrint('[auth] Cloud Function error: code=${fe.code} message=${fe.message} details=${fe.details}');
      rethrow;
    } catch (e, st) {
      debugPrint('[auth] verifyCode failed: $e\n$st');
      rethrow;
    }
  }

  void dispose() {}
}
