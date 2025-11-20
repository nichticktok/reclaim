import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/milestone_model.dart';
import 'milestone_repository.dart';

/// Firestore implementation of MilestoneRepository
class FirestoreMilestoneRepository implements MilestoneRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<MilestoneModel?> getCurrentMilestone(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('milestones')
          .doc('current')
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() ?? {};
      return MilestoneModel.fromMap({
        ...data,
        'id': 'current',
        'userId': userId,
      });
    } catch (e) {
      throw Exception('Failed to get current milestone: $e');
    }
  }

  @override
  Future<void> createMilestone(MilestoneModel milestone) async {
    try {
      await _firestore
          .collection('users')
          .doc(milestone.userId)
          .collection('milestones')
          .doc(milestone.id)
          .set(milestone.toMap());
    } catch (e) {
      throw Exception('Failed to create milestone: $e');
    }
  }

  @override
  Future<void> updateMilestone(MilestoneModel milestone) async {
    try {
      await _firestore
          .collection('users')
          .doc(milestone.userId)
          .collection('milestones')
          .doc(milestone.id)
          .update(milestone.toMap());
    } catch (e) {
      throw Exception('Failed to update milestone: $e');
    }
  }
}

