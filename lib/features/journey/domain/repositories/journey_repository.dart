/// Journey Repository Interface
/// Abstract methods for daily journey/reflection
abstract class JourneyRepository {
  /// Get journey entry for a specific day
  Future<Map<String, dynamic>?> getDayEntry(String userId, int dayNumber);
  
  /// Get multiple day entries (for timeline view)
  Future<Map<int, Map<String, dynamic>>> getDayEntries(String userId, List<int> dayNumbers);
  
  /// Save mood selection
  Future<void> saveMood(String userId, int dayNumber, String mood);
  
  /// Save journal entry
  Future<void> saveJournalEntry(String userId, int dayNumber, String entry);
  
  /// Get current day number
  Future<int> getCurrentDay(String userId);
  
  /// Get journey start date
  Future<DateTime?> getJourneyStartDate(String userId);
}

