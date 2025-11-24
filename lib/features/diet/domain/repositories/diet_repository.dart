/// Abstract repository for diet plan data operations
abstract class DietRepository {
  Future<void> saveDietPlan(String userId, Map<String, dynamic> planData);
  Future<List<Map<String, dynamic>>> getUserDietPlans(String userId);
  Future<Map<String, dynamic>?> getActiveDietPlan(String userId);
  Future<void> updateDietPlan(String planId, Map<String, dynamic> updates);
  Future<void> deleteDietPlan(String planId);
}

