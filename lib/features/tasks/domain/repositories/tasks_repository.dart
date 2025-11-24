import 'package:recalim/core/models/habit_model.dart';

/// Abstract repository for tasks/habits data operations
abstract class TasksRepository {
  Future<List<HabitModel>> getHabits(String userId);
  Future<List<HabitModel>> getTodayHabits(String userId);
  Future<HabitModel> getHabitById(String habitId);
  Future<void> addHabit(HabitModel habit);
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(String habitId, String reason);
  Future<void> completeHabit(String habitId, {String? proof});
  Future<void> undoCompleteHabit(String habitId); // Undo today's completion
  Future<void> skipHabit(String habitId); // Skip a task for today (with consequences)
  Future<void> submitProof(String habitId, String proof);
  Future<void> initializeDefaultTasks(String userId, Map<String, dynamic> onboardingData);
}

