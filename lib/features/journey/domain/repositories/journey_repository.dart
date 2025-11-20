/// Journey Repository Interface
/// Abstract methods for daily journey/reflection
abstract class JourneyRepository {
  /// Get journey entry for a specific day
  Future<Map<String, dynamic>?> getDayEntry(String userId, int dayNumber);
  
  /// Save mood selection
  Future<void> saveMood(String userId, int dayNumber, String mood);
  
  /// Save journal entry
  Future<void> saveJournalEntry(String userId, int dayNumber, String entry);
  
  /// Get current day number
  Future<int> getCurrentDay(String userId);
}

