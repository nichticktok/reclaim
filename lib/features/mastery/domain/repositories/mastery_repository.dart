/// Mastery Repository Interface
/// Abstract methods for mastery/achievement system
abstract class MasteryRepository {
  /// Get mastery data for user
  Future<Map<String, dynamic>> getMasteryData(String userId);
  
  /// Add XP to user
  Future<void> addXP(String userId, int amount);
  
  /// Get current rank
  Future<String> getCurrentRank(String userId);
  
  /// Get achievements
  Future<List<Map<String, dynamic>>> getAchievements(String userId);
}

