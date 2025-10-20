// lib/auth/login_logic.dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef InfoHandler = void Function(String message);

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<PendingDynamicLinkData?>? _linkSub;

  // Avoid handling the same link twice
  bool _isCompleting = false;
  String? _lastHandledLink;

  /// Send the passwordless email link and cache the email locally.
  Future<void> sendEmailLink({
    required String email,
    required ActionCodeSettings actionCodeSettings,
  }) async {
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingEmail', email);
  }

  /// Start listening for Firebase Dynamic Links (Android/iOS only).
  /// On success, calls [onSuccess]. Non-fatal info/errors go to callbacks.
  Future<void> initEmailLinkListener({
    required VoidCallback onSuccess,
    InfoHandler? onInfo,
    InfoHandler? onError,
  }) async {
    // Dynamic Links is NOT supported on web/desktop
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    try {
      // App opened from a terminated state
      final initial = await FirebaseDynamicLinks.instance.getInitialLink();
      if (initial != null) {
        await _maybeComplete(
          link: initial.link.toString(),
          onSuccess: onSuccess,
          onInfo: onInfo,
          onError: onError,
        );
      }

      // App already running: stream future links
      _linkSub = FirebaseDynamicLinks.instance.onLink.listen((data) async {
        final link = data.link.toString();
        await _maybeComplete(
          link: link,
          onSuccess: onSuccess,
          onInfo: onInfo,
          onError: onError,
        );
      }, onError: (e, st) {
        onError?.call('Dynamic link error: $e');
      });
    } catch (e) {
      onError?.call('Failed to initialize dynamic links: $e');
    }
  }

  /// Manual completion helper (e.g., if you parse a link yourself).
  Future<void> completeFromLink(
    String link, {
    required VoidCallback onSuccess,
    InfoHandler? onInfo,
    InfoHandler? onError,
  }) async {
    await _maybeComplete(
      link: link,
      onSuccess: onSuccess,
      onInfo: onInfo,
      onError: onError,
    );
  }

  Future<void> _maybeComplete({
    required String link,
    required VoidCallback onSuccess,
    InfoHandler? onInfo,
    InfoHandler? onError,
  }) async {
    // Debounce duplicates & concurrent calls
    if (_isCompleting || link.isEmpty || link == _lastHandledLink) return;
    _isCompleting = true;

    try {
      if (!_auth.isSignInWithEmailLink(link)) return;

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('pendingEmail');

      if (email == null || email.isEmpty) {
        onInfo?.call('Please re-enter your email to finish sign-in.');
        return;
      }

      await _auth.signInWithEmailLink(email: email, emailLink: link);
      await prefs.remove('pendingEmail');
      _lastHandledLink = link;
      onSuccess();
    } catch (e) {
      onError?.call('Email link sign-in failed: $e');
    } finally {
      _isCompleting = false;
    }
  }

  void dispose() {
    _linkSub?.cancel();
    _linkSub = null;
  }
}
