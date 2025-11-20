import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../data/repositories/firestore_onboarding_repository.dart';

/// Service for onboarding navigation logic
/// This coordinates which screen to show based on onboarding progress
class OnboardingService {
  static final OnboardingRepository _repository = FirestoreOnboardingRepository();
  
  /// Get the next screen info based on user's onboarding progress
  /// Returns a map with 'screen' type and optional 'step' for onboarding
  static Future<Map<String, dynamic>> getNextScreenInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'screen': 'onboarding', 'step': 0};
    }

    final progress = await _repository.getOnboardingProgress(user.uid);
    final bool completed = progress?['onboardingCompleted'] ?? false;
    final int step = progress?['onboardingStep'] ?? 0;

    if (!completed) {
      return {'screen': 'onboarding', 'step': step};
    } else {
      return {'screen': 'home'};
    }
  }
}
