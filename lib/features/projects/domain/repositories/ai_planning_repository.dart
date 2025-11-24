import '../entities/project_planning_input.dart';
import '../entities/project_plan.dart';

abstract class AIPlanningRepository {
  /// Generate a project plan using AI
  Future<ProjectPlan> generateProjectPlan(ProjectPlanningInput input);
}

