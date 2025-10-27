import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home_screen.dart';

class OnboardingService {
  static Future<Widget> getNextScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const OnboardingScreen(); // fallback safe

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      // first-time user → create initial onboarding state
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'onboardingStep': 0,
        'onboardingCompleted': false,
      });
      return const OnboardingScreen(startStep: 0);
    }

    final data = doc.data() ?? {};
    final bool completed = data['onboardingCompleted'] ?? false;
    final int step = data['onboardingStep'] ?? 0;

    if (!completed) {
      return OnboardingScreen(startStep: step);
    } else {
      return const HomeScreen();
    }
  }
}
