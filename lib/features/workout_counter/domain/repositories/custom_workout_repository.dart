import '../entities/custom_workout_plan.dart';

/// Abstract repository for custom workout plan data operations
abstract class CustomWorkoutRepository {
  Future<String> saveCustomWorkoutPlan(CustomWorkoutPlan plan);
  Future<List<CustomWorkoutPlan>> getUserCustomWorkoutPlans(String userId);
  Future<CustomWorkoutPlan?> getCustomWorkoutPlanById(String planId);
  Future<void> updateCustomWorkoutPlan(CustomWorkoutPlan plan);
  Future<void> deleteCustomWorkoutPlan(String planId);
}

