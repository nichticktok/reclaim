import '../entities/workout_planning_input.dart';
import '../entities/workout_plan.dart';

abstract class AIWorkoutPlanningRepository {
  /// Generate a workout plan using AI
  Future<WorkoutPlan> generateWorkoutPlan(WorkoutPlanningInput input);
}

