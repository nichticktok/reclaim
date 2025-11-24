import '../entities/diet_planning_input.dart';
import '../entities/diet_plan.dart';

/// Abstract repository for AI diet planning operations
abstract class AIDietPlanningRepository {
  /// Generate a diet plan based on user input
  Future<DietPlan> generateDietPlan(DietPlanningInput input);
}

