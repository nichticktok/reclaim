import 'package:flutter/material.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';

/// App Routes - Centralized route definitions
class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String signIn = '/sign_in';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  
  // Route map for MaterialApp
  static Map<String, WidgetBuilder> get routes => {
        signIn: (context) => const SignInScreen(),
        onboarding: (context) => const OnboardingScreen(),
        home: (context) => HomeScreen(), // Remove const to ensure Provider context is available
      };
  
  // Navigation helpers
  static void navigateToSignIn(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, signIn, (route) => false);
  }
  
  static void navigateToOnboarding(BuildContext context) {
    Navigator.pushReplacementNamed(context, onboarding);
  }
  
  static void navigateToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, home);
  }
}

