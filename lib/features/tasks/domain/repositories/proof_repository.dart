import 'package:recalim/core/models/proof_submission_model.dart';

/// Abstract repository for proof submissions
abstract class ProofRepository {
  /// Submit a proof for a habit
  Future<ProofSubmission> submitProof(String habitId, ProofSubmission proof);

  /// Get all proofs for a specific habit
  Future<List<ProofSubmission>> getProofsForHabit(String habitId);

  /// Get proof for a specific habit and date
  Future<ProofSubmission?> getProofForDate(String habitId, String dateKey);

  /// Delete a proof submission
  Future<void> deleteProof(String proofId);

  /// Upload media file (photo/video/file) to Firebase Storage
  /// Returns the download URL
  Future<String> uploadMediaFile(
    String filePath,
    String habitId,
    String proofType,
    String? fileName,
  );
}

