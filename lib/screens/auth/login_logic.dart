import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'dart:io' show Platform;

/// Optional info handler type for UI logging/snackbars.
typedef InfoHandler = void Function(String);

/// --- Build-time flags (pass via --dart-define) ---
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
  late final FirebaseFunctions _functions;

  AuthController()
      : _functions = FirebaseFunctions.instanceFor(region: _functionsRegion) {
    // Configure Functions (emulator vs deployed)
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
          '[auth] Using Functions emulator at $host:$_functionsEmulatorPort');
      _functions.useFunctionsEmulator(host, _functionsEmulatorPort);
    } else {
      debugPrint(
          '[auth] Using deployed Functions in region $_functionsRegion (emulator: $_useFunctionsEmulator, debug: $kDebugMode)');
    }
  }

  // ---------------------------
  // Helpers to stabilize sign-in
  // ---------------------------

  Future<User?> _waitForUser(
      {Duration timeout = const Duration(seconds: 8)}) async {
    final u0 = _auth.currentUser;
    if (u0 != null) return u0;
    try {
      final u = await _auth
          .authStateChanges()
          .firstWhere((e) => e != null)
          .timeout(timeout, onTimeout: () => _auth.currentUser);
      return u;
    } catch (_) {
      return _auth.currentUser;
    }
  }

  Future<User?> _ensureUserDoc() async {
    final u = _auth.currentUser ?? await _waitForUser();
    if (u == null) return null;

    final ref = FirebaseFirestore.instance.collection('users').doc(u.uid);
    await ref.set({
      'uid': u.uid,
      'email': u.email,
      'displayName': u.displayName,
      'photoURL': u.photoURL,
      'isGuest': u.isAnonymous,
      'onboardingStep': 0,
      'onboardingCompleted': false,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return u;
  }

  Future<User?> ensureUserDocAfterSignIn() => _ensureUserDoc();

  // ---------------------------
  // Email link / code flow
  // ---------------------------

  Future<void> requestCode({required String email}) async {
    final callable = _functions.httpsCallable('auth_requestCode');
    try {
      await callable.call(<String, dynamic>{'email': email});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingEmail', email);
      debugPrint('[auth] requestCode succeeded for $email');
    } on FirebaseFunctionsException catch (fe) {
      debugPrint(
          '[auth] Cloud Function error: code=${fe.code} message=${fe.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('[auth] requestCode failed: $e\n$st');
      rethrow;
    }
  }

  Future<User?> verifyCode(
      {required String email, required String code}) async {
    final callable = _functions.httpsCallable('auth_verifyCode');
    try {
      final res =
          await callable.call(<String, dynamic>{'email': email, 'code': code});
      final data = (res.data as Map);
      final token = data['customToken'] as String;

      await _auth.signInWithCustomToken(token);
      await _waitForUser();
      final u = await _ensureUserDoc();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pendingEmail');

      debugPrint('[auth] verifyCode succeeded for $email (uid=${u?.uid})');
      return u;
    } on FirebaseFunctionsException catch (fe) {
      debugPrint('[auth] Cloud Function error: ${fe.code} ${fe.message}');
      rethrow;
    } catch (e, st) {
      debugPrint('[auth] verifyCode failed: $e\n$st');
      rethrow;
    }
  }

  // ---------------------------
  // Guest / "Sign up later" flow
  // ---------------------------

  Future<User?> continueAsGuest() async {
    try {
      final userCred = await _auth.signInAnonymously();
      final user = userCred.user!;
      debugPrint('[auth] Guest user created: ${user.uid}');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'isGuest': true,
        'onboardingStep': 0,
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guestUID', user.uid);

      return user;
    } catch (e, st) {
      debugPrint('[auth] continueAsGuest failed: $e\n$st');
      rethrow;
    }
  }

  /// ✅ Upgrade an anonymous user to a real account (Google/email)
  Future<void> linkAnonymousAccount(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw Exception('No anonymous user to upgrade.');
    }

    try {
      await user.linkWithCredential(credential);
      debugPrint('[auth] Anonymous account upgraded successfully.');
      await _ensureUserDoc();
    } catch (e, st) {
      debugPrint('[auth] linkAnonymousAccount failed: $e\n$st');
      rethrow;
    }
  }

  /// ✅ Proper logout (cleans prefs + Firebase)
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guestUID');
    await prefs.remove('pendingEmail');
    await _auth.signOut();
    debugPrint('[auth] User signed out');
  }

  void dispose() {}
}
