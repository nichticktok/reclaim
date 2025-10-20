// lib/ui/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;

import '../auth/login_logic.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool loading = false;

  // Email-link controller
  final _authController = AuthController();

  // ---- Navigation helper
  void _safeGoToOnboarding() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding_screen');
  }

  // ---- ActionCodeSettings for email links (replace values!)
  ActionCodeSettings get _acs => ActionCodeSettings(
        url: 'https://reclaim-f1b3f.web.app/emailSignIn', // your Dynamic Link
        handleCodeInApp: true,
        androidPackageName: 'com.example.recalim',        // <-- replace
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: 'com.example.recalim',               // <-- replace
      );

  @override
  void initState() {
    super.initState();
    // Listen & complete email link sign-in if app is opened by the link
    _authController.initEmailLinkListener(
      onSuccess: _safeGoToOnboarding,
      onInfo: (msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
      onError: (msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  // ---- Google (via Firebase provider API)
  Future<void> signInWithGoogle() async {
    setState(() => loading = true);
    try {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
      _safeGoToOnboarding();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---- Apple
  Future<void> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) return;
    setState(() => loading = true);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      _safeGoToOnboarding();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---- Email bottom sheet: sends magic link
  void _showEmailSignInSheet() {
    // Capture the screen's context to use after the sheet is closed
    final rootContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        final emailController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Enter your email address.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text(
                  "We'll email you a secure sign-in link.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "you@example.com",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty || !email.contains('@')) {
                      // Use SHEET context while it's still mounted
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid email")),
                      );
                      return;
                    }

                    // Close the sheet first; sheetContext becomes invalid after this.
                    Navigator.pop(sheetContext);

                    if (mounted) setState(() => loading = true);
                    try {
                      await _authController.sendEmailLink(
                        email: email,
                        actionCodeSettings: _acs,
                      );
                      if (!mounted) return;
                      // Use the ROOT (screen) context after closing the sheet
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text("Sign-in link sent to $email")),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text("Failed to send link: $e")),
                      );
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                  },
                  child: const Text("Send sign-in link"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  const Text(
                    "life-changing",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Reclaim  •  800K+ installs ★ 4.7",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  if (Platform.isIOS || Platform.isMacOS)
                    _authButton(
                      icon: Icons.apple,
                      label: "Continue with Apple",
                      onTap: signInWithApple,
                      dark: true,
                    ),
                  const SizedBox(height: 12),

                  _authButton(
                    iconAsset: 'assets/icons/google.png',
                    label: "Continue with Google",
                    onTap: signInWithGoogle,
                  ),
                  const SizedBox(height: 12),

                  _authButton(
                    icon: Icons.email_outlined,
                    label: "Continue with Email",
                    onTap: _showEmailSignInSheet,
                  ),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _safeGoToOnboarding,
                    child: const Text(
                      "Sign up later",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Optional: trigger resend link flow / restore with cached email
                    },
                    child: const Text(
                      "Restore Progress",
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _authButton({
    IconData? icon,
    String? iconAsset,
    required String label,
    required VoidCallback onTap,
    bool dark = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? Colors.black : Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        icon: iconAsset != null
            ? Image.asset(iconAsset, height: 22)
            : Icon(icon, color: Colors.white),
        label: Text(label),
      ),
    );
  }
}
