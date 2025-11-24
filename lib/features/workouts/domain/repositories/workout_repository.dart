import 'package:recalim/core/models/workout_model.dart';

abstract class WorkoutRepository {
  /// Create a new workout plan
  Future<WorkoutPlanModel> createWorkoutPlan(WorkoutPlanModel plan);

  /// Get all workout plans for a user
  Future<List<WorkoutPlanModel>> getUserWorkoutPlans(String userId);

  /// Get active workout plan for a user
  Future<WorkoutPlanModel?> getActiveWorkoutPlan(String userId);

  /// Get a workout plan by ID
  Future<WorkoutPlanModel?> getWorkoutPlanById(String planId);

  /// Update a workout plan
  Future<void> updateWorkoutPlan(WorkoutPlanModel plan);

  /// Delete a workout plan
  Future<void> deleteWorkoutPlan(String planId);

  /// Create workout days for a plan
  Future<void> createWorkoutDays(String planId, List<WorkoutDayModel> days);

  /// Get workout days for a plan
  Future<List<WorkoutDayModel>> getWorkoutDays(String planId);

  /// Create exercises for a workout day
  Future<void> createExercises(String workoutDayId, List<WorkoutExerciseModel> exercises);

  /// Get exercises for a workout day
  Future<List<WorkoutExerciseModel>> getExercises(String workoutDayId);

  /// Update a workout day (e.g., mark as completed)
  Future<void> updateWorkoutDay(WorkoutDayModel day);

  /// Get today's workout session
  Future<WorkoutDayModel?> getTodaysWorkout(String userId);
}

