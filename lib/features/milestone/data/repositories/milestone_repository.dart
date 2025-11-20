import '../../../../models/milestone_model.dart';

/// Abstract repository for milestone operations
abstract class MilestoneRepository {
  /// Get the current active milestone for a user
  Future<MilestoneModel?> getCurrentMilestone(String userId);
  
  /// Create a new milestone
  Future<void> createMilestone(MilestoneModel milestone);
  
  /// Update an existing milestone
  Future<void> updateMilestone(MilestoneModel milestone);
}

