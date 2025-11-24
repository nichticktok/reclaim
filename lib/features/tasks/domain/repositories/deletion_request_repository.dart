import 'package:recalim/core/models/deletion_request_model.dart';

abstract class DeletionRequestRepository {
  /// Create a new deletion request for a habit
  Future<DeletionRequestModel> createDeletionRequest({
    required String userId,
    required String habitId,
    required String habitTitle,
    required String reason,
    required String accountabilityPartnerContact,
    required String contactType, // 'phone' or 'email'
  });

  /// Create a new deletion request for a plan
  Future<DeletionRequestModel> createPlanDeletionRequest({
    required String userId,
    required String planId,
    required String planTitle,
    required String reason,
    required String accountabilityPartnerContact,
    required String contactType, // 'phone' or 'email'
  });

  /// Get a deletion request by ID
  Future<DeletionRequestModel?> getDeletionRequestById(String requestId);

  /// Get pending deletion request for a specific habit
  Future<DeletionRequestModel?> getPendingDeletionRequestForHabit(String userId, String habitId);

  /// Get pending deletion request for a specific plan
  Future<DeletionRequestModel?> getPendingDeletionRequestForPlan(String userId, String planId);

  /// Get all pending deletion requests for a user
  Future<List<DeletionRequestModel>> getPendingDeletionRequests(String userId);

  /// Get all deletion requests for a user (all statuses)
  Future<List<DeletionRequestModel>> getAllDeletionRequests(String userId);

  /// Update deletion request status (approved/rejected) based on response
  Future<void> updateDeletionRequestStatus(
    String requestId,
    DeletionRequestStatus status,
    String response, // Y, YES, N, NO
  );

  /// Check if a response is an approval (Y or YES)
  bool isApprovalResponse(String response);

  /// Process response from accountability partner
  Future<void> processResponse(
    String requestId,
    String response,
  );
}

