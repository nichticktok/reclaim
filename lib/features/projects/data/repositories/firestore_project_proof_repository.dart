import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/project_task_proof.dart';
import '../../domain/repositories/project_proof_repository.dart';

class FirestoreProjectProofRepository implements ProjectProofRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> saveProof(ProjectTaskProof proof) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the project and milestone to get the correct path
    final projectsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();

    for (var projectDoc in projectsSnapshot.docs) {
      final milestonesSnapshot = await projectDoc.reference
          .collection('milestones')
          .get();

      for (var milestoneDoc in milestonesSnapshot.docs) {
        final taskDoc = await milestoneDoc.reference
            .collection('tasks')
            .doc(proof.taskId)
            .get();

        if (taskDoc.exists) {
          // Save proof in tasks/{taskId}/proofs/{proofId}
          final proofRef = taskDoc.reference.collection('proofs').doc();
          final proofWithId = proof.copyWith(id: proofRef.id);
          await proofRef.set(proofWithId.toMap());

          // Update task's proofs map with date key
          await taskDoc.reference.update({
            'proofs.${proof.dateKey}': proofWithId.generateProofSummary(),
          });

          return proofRef.id;
        }
      }
    }

    throw Exception('Task not found for proof submission');
  }

  @override
  Future<void> updateProof(ProjectTaskProof proof) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the proof and update it
    final projectsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();

    for (var projectDoc in projectsSnapshot.docs) {
      final milestonesSnapshot = await projectDoc.reference
          .collection('milestones')
          .get();

      for (var milestoneDoc in milestonesSnapshot.docs) {
        final proofDoc = await milestoneDoc.reference
            .collection('tasks')
            .doc(proof.taskId)
            .collection('proofs')
            .doc(proof.id)
            .get();

        if (proofDoc.exists) {
          await proofDoc.reference.update(proof.toMap());
          
          // Update task's proofs map with updated summary
          final taskDoc = await milestoneDoc.reference
              .collection('tasks')
              .doc(proof.taskId)
              .get();
          
          if (taskDoc.exists) {
            await taskDoc.reference.update({
              'proofs.${proof.dateKey}': proof.generateProofSummary(),
            });
          }
          
          return;
        }
      }
    }

    throw Exception('Proof not found for update');
  }

  @override
  Future<List<ProjectTaskProof>> getProofsForTask(String taskId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the task
    final projectsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();

    for (var projectDoc in projectsSnapshot.docs) {
      final milestonesSnapshot = await projectDoc.reference
          .collection('milestones')
          .get();

      for (var milestoneDoc in milestonesSnapshot.docs) {
        final proofsSnapshot = await milestoneDoc.reference
            .collection('tasks')
            .doc(taskId)
            .collection('proofs')
            .orderBy('sessionStart', descending: true)
            .get();

        if (proofsSnapshot.docs.isNotEmpty) {
          return proofsSnapshot.docs
              .map((doc) => ProjectTaskProof.fromMap({
                    ...doc.data(),
                    'id': doc.id,
                  }))
              .toList();
        }
      }
    }

    return [];
  }

  @override
  Future<ProjectTaskProof?> getProofById(String proofId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Search across all projects for the proof
    final projectsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();

    for (var projectDoc in projectsSnapshot.docs) {
      final milestonesSnapshot = await projectDoc.reference
          .collection('milestones')
          .get();

      for (var milestoneDoc in milestonesSnapshot.docs) {
        final tasksSnapshot = await milestoneDoc.reference
            .collection('tasks')
            .get();

        for (var taskDoc in tasksSnapshot.docs) {
          final proofDoc = await taskDoc.reference
              .collection('proofs')
              .doc(proofId)
              .get();

          if (proofDoc.exists) {
            return ProjectTaskProof.fromMap({
              ...proofDoc.data()!,
              'id': proofDoc.id,
            });
          }
        }
      }
    }

    return null;
  }

  @override
  Future<void> deleteProof(String proofId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find and delete the proof
    final projectsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();

    for (var projectDoc in projectsSnapshot.docs) {
      final milestonesSnapshot = await projectDoc.reference
          .collection('milestones')
          .get();

      for (var milestoneDoc in milestonesSnapshot.docs) {
        final tasksSnapshot = await milestoneDoc.reference
            .collection('tasks')
            .get();

        for (var taskDoc in tasksSnapshot.docs) {
          final proofDoc = await taskDoc.reference
              .collection('proofs')
              .doc(proofId)
              .get();

          if (proofDoc.exists) {
            await proofDoc.reference.delete();
            return;
          }
        }
      }
    }

    throw Exception('Proof not found');
  }

  @override
  Future<List<ProjectTaskProof>> getProofsForTaskOnDate(
      String taskId, String dateKey) async {
    final allProofs = await getProofsForTask(taskId);
    return allProofs.where((proof) => proof.dateKey == dateKey).toList();
  }
}

