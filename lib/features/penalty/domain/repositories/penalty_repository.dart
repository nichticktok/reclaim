/// Penalty Repository Interface
/// Abstract methods for penalty system
abstract class PenaltyRepository {
  /// Check if user has active penalty
  Future<bool> hasActivePenalty(String userId);
  
  /// Get penalty quest
  Future<Map<String, dynamic>?> getPenaltyQuest(String userId);
  
  /// Generate penalty quest
  Future<void> generatePenaltyQuest(String userId);
  
  /// Complete penalty quest
  Future<void> completePenaltyQuest(String userId, String questId);
  
  /// Reset to day 1 (if penalty quest failed)
  Future<void> resetToDayOne(String userId);
}

