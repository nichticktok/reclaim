import '../../../../core/models/project_task_proof.dart';

/// Abstract repository for project task proof operations
abstract class ProjectProofRepository {
  /// Save a proof for a project task
  Future<String> saveProof(ProjectTaskProof proof);

  /// Update an existing proof
  Future<void> updateProof(ProjectTaskProof proof);

  /// Get all proofs for a specific task
  Future<List<ProjectTaskProof>> getProofsForTask(String taskId);

  /// Get a proof by ID
  Future<ProjectTaskProof?> getProofById(String proofId);

  /// Delete a proof
  Future<void> deleteProof(String proofId);

  /// Get proofs for a task on a specific date
  Future<List<ProjectTaskProof>> getProofsForTaskOnDate(String taskId, String dateKey);
}

