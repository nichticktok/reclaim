import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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
  final _authController = AuthController();

  void _safeGoToOnboarding() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding_screen');
  }

  bool get _isCupertino => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  // ---- Email sheet (send code -> verify)
  void _showEmailCodeSheet() {
    final emailCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    bool codeSent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        void log(String m) => debugPrint('[email-sheet] $m');

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setLocal) {
              Future<void> sendCode() async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  log('Please enter a valid email');
                  return;
                }
                if (mounted) setState(() => loading = true);
                try {
                  await _authController.requestCode(email: email);
                  setLocal(() => codeSent = true);
                  log('We emailed a 6-digit code to $email');
                } catch (e, st) {
                  log('Failed to send code: $e\n$st');
                } finally {
                  if (mounted) setState(() => loading = false);
                }
              }

              Future<void> verify() async {
                final email = emailCtrl.text.trim();
                final code = codeCtrl.text.trim();
                if (code.length != 6) {
                  log('Enter the 6-digit code');
                  return;
                }
                Navigator.pop(sheetContext);
                if (mounted) setState(() => loading = true);
                try {
                  await _authController.verifyCode(email: email, code: code);
                  _safeGoToOnboarding();
                } catch (e, st) {
                  log('Verification failed: $e\n$st');
                } finally {
                  if (mounted) setState(() => loading = false);
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        codeSent ? 'Enter the code we sent' : 'Sign in with Email',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "you@example.com",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (codeSent) ...[
                    TextField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(color: Colors.white, letterSpacing: 4),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: "6-digit code",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: codeSent ? verify : sendCode,
                      child: Text(codeSent ? "Verify code" : "Send code"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ---- Google Sign-in
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

  // ---- Apple Sign-in
  Future<void> signInWithApple() async {
    if (!_isCupertino) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apple Sign-In not available on this platform')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
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

  // ---- Anonymous Guest Sign-in
  Future<void> signInAsGuest() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final user = await _authController.continueAsGuest();
      if (user != null) _safeGoToOnboarding();
    } catch (e, st) {
      debugPrint('[auth] Guest sign-in failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start as guest. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
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

                  if (_isCupertino)
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
                    onTap: _showEmailCodeSheet,
                  ),

                  const SizedBox(height: 20),

                  // ✅ Updated: Guest sign-up button uses AuthController
                  TextButton(
                    onPressed: signInAsGuest,
                    child: const Text(
                      "Sign up later",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Restore Progress",
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        fontSize: 15,
                      ),
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
          backgroundColor: dark ? Colors.black : Colors.white.withValues(alpha: 0.1),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
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
