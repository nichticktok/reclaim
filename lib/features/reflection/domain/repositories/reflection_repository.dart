/// Abstract repository for reflection data operations
abstract class ReflectionRepository {
  Future<void> saveReflection({
    required String userId,
    required String gratitude,
    required String lesson,
    required String improvement,
  });
  
  Future<Map<String, dynamic>?> getTodayReflection(String userId);
  Future<List<Map<String, dynamic>>> getReflectionHistory(String userId, {int days = 30});
}

