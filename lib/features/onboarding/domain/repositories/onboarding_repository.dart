/// Abstract repository for onboarding data operations
abstract class OnboardingRepository {
  Future<Map<String, dynamic>?> getOnboardingProgress(String userId);
  Future<void> saveOnboardingProgress(String userId, int step, Map<String, dynamic> data);
  Future<void> markOnboardingCompleted(String userId);
  Future<bool> isOnboardingCompleted(String userId);
}

