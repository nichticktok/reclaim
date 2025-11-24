import '../../../../core/models/plan_model.dart';

/// Repository for managing plans in Firestore
abstract class PlanRepository {
  /// Create a new plan
  Future<PlanModel> createPlan(PlanModel plan);

  /// Get a plan by ID
  Future<PlanModel?> getPlanById(String planId);

  /// Get all plans for a user
  Future<List<PlanModel>> getUserPlans(String userId);

  /// Update a plan
  Future<void> updatePlan(PlanModel plan);

  /// Delete a plan
  Future<void> deletePlan(String planId);

  /// Get daily plan for a specific date
  Future<DailyPlan?> getDailyPlan(String planId, DateTime date);
}

