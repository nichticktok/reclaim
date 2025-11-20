import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/penalty_repository.dart';

/// Firestore implementation of PenaltyRepository
/// Firestore operations for penalty system
class FirestorePenaltyRepository implements PenaltyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<bool> hasActivePenalty(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('penalties')
          .doc('active')
          .get();

      if (!doc.exists) return false;
      final data = doc.data();
      return data?['isActive'] == true;
    } catch (e) {
      throw Exception('Failed to check penalty status: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getPenaltyQuest(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('penalties')
          .doc('active')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data?['isActive'] == true) {
          return data?['quest'];
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch penalty quest: $e');
    }
  }

  @override
  Future<void> generatePenaltyQuest(String userId) async {
    try {
      final questData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'penalty',
        'description': 'Complete this penalty quest to continue your journey',
        'tasks': [
          {'task': 'Complete 3 extra tasks today', 'completed': false},
          {'task': 'Write a reflection on why you missed a day', 'completed': false},
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'deadline': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('penalties')
          .doc('active')
          .set({
        'isActive': true,
        'quest': questData,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to generate penalty quest: $e');
    }
  }

  @override
  Future<void> completePenaltyQuest(String userId, String questId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('penalties')
          .doc('active')
          .update({
        'isActive': false,
        'completedAt': FieldValue.serverTimestamp(),
        'quest.completed': true,
      });
    } catch (e) {
      throw Exception('Failed to complete penalty quest: $e');
    }
  }

  @override
  Future<void> resetToDayOne(String userId) async {
    try {
      // Reset program to day 1
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc('current')
          .update({
        'currentDay': 1,
        'resetAt': FieldValue.serverTimestamp(),
      });

      // Clear penalty
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('penalties')
          .doc('active')
          .delete();
    } catch (e) {
      throw Exception('Failed to reset to day 1: $e');
    }
  }
}

