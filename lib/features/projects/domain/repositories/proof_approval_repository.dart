import '../entities/proof_approval_request.dart';

/// Abstract repository for proof approval requests
abstract class ProofApprovalRepository {
  /// Create a new approval request
  Future<String> createApprovalRequest(ProofApprovalRequest request);

  /// Get approval request by ID
  Future<ProofApprovalRequest?> getApprovalRequestById(String requestId);

  /// Get pending approval requests for a proof
  Future<ProofApprovalRequest?> getPendingApprovalForProof(String proofId);

  /// Update approval request status
  Future<void> updateApprovalRequest(ProofApprovalRequest request);

  /// Process response from approver (Y/YES = approved, N/NO = rejected)
  Future<void> processApprovalResponse(String requestId, String response);

  /// Check if a response is an approval (Y or YES)
  bool isApprovalResponse(String response);
}

