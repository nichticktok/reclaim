import 'package:recalim/core/models/progress_model.dart';

/// Abstract repository for progress data operations
abstract class ProgressRepository {
  Future<ProgressModel> getTodayProgress(String userId);
  Future<List<ProgressModel>> getProgressHistory(String userId, {int days = 7});
  Future<void> updateProgress(ProgressModel progress);
  Future<int> getCurrentStreak(String userId);
  Future<int> getLongestStreak(String userId);
  Future<int> getTotalCompletedTasks(String userId);
}

