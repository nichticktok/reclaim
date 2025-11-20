/// Program Repository Interface
/// Abstract methods for program management
abstract class ProgramRepository {
  /// Get current program for user
  Future<Map<String, dynamic>?> getCurrentProgram(String userId);
  
  /// Create new 66-day program
  Future<void> createProgram(String userId, Map<String, dynamic> programData);
  
  /// Get tasks for a specific week
  Future<List<Map<String, dynamic>>> getWeekTasks(String userId, int weekNumber);
  
  /// Update task in program
  Future<void> updateTask(String userId, String taskId, Map<String, dynamic> taskData);
  
  /// Delete task from program
  Future<void> deleteTask(String userId, String taskId);
}

