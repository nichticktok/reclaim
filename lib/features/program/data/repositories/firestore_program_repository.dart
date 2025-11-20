import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/program_repository.dart';

/// Firestore implementation of ProgramRepository
/// Firestore operations for program management
class FirestoreProgramRepository implements ProgramRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>?> getCurrentProgram(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc('current')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch program: $e');
    }
  }

  @override
  Future<void> createProgram(String userId, Map<String, dynamic> programData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc('current')
          .set({
        ...programData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'startDate': FieldValue.serverTimestamp(),
        'currentDay': 1,
        'totalDays': 30, // Default, will be overridden by milestone
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create program: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getWeekTasks(String userId, int weekNumber) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc('current')
          .collection('weeks')
          .doc('week_$weekNumber')
          .collection('tasks')
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch week tasks: $e');
    }
  }

  @override
  Future<void> updateTask(String userId, String taskId, Map<String, dynamic> taskData) async {
    try {
      final programDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc('current')
          .get();

      if (!programDoc.exists) {
        throw Exception('Program not found');
      }

      // Find which week the task belongs to
      final weeksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc('current')
          .collection('weeks')
          .get();

      for (var weekDoc in weeksSnapshot.docs) {
        final taskDoc = await weekDoc.reference
            .collection('tasks')
            .doc(taskId)
            .get();

        if (taskDoc.exists) {
          await weekDoc.reference
              .collection('tasks')
              .doc(taskId)
              .update({
            ...taskData,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return;
        }
      }

      throw Exception('Task not found');
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    try {
      final weeksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc('current')
          .collection('weeks')
          .get();

      for (var weekDoc in weeksSnapshot.docs) {
        final taskDoc = await weekDoc.reference
            .collection('tasks')
            .doc(taskId)
            .get();

        if (taskDoc.exists) {
          await weekDoc.reference
              .collection('tasks')
              .doc(taskId)
              .delete();
          return;
        }
      }

      throw Exception('Task not found');
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}

