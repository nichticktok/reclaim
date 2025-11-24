import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/plan_model.dart';
import '../../domain/repositories/plan_repository.dart';

/// Firestore implementation of PlanRepository
/// Plans are stored in user-specific subcollection: users/{userId}/plans
class FirestorePlanRepository implements PlanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get the current authenticated user
  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');
    return user.uid;
  }
  
  /// Get the plans collection reference for the current user
  CollectionReference get _plansCollection {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('plans');
  }

  @override
  Future<PlanModel> createPlan(PlanModel plan) async {
    try {
      final planMap = plan.toMap();
      planMap.remove('id'); // Remove id for document creation
      // Ensure userId matches current user
      planMap['userId'] = _currentUserId;

      final docRef = await _plansCollection.add(planMap);

      return plan.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create plan: $e');
    }
  }

  @override
  Future<PlanModel?> getPlanById(String planId) async {
    try {
      final doc = await _plansCollection.doc(planId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return PlanModel.fromMap(data);
    } catch (e) {
      throw Exception('Failed to get plan: $e');
    }
  }

  @override
  Future<List<PlanModel>> getUserPlans(String userId) async {
    try {
      // Plans are already scoped to the user's subcollection, so we don't need to filter by userId
      // But we validate that the requested userId matches the current user for security
      if (userId != _currentUserId) {
        throw Exception('Cannot access plans for other users');
      }

      // Fetch all plans from user's subcollection
      // Fetch without orderBy to avoid needing a composite index
      final snapshot = await _plansCollection.get();

      final plans = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return PlanModel.fromMap(data);
      }).toList();

      // Sort in memory by createdAt descending (most recent first)
      plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return plans;
    } catch (e) {
      throw Exception('Failed to get user plans: $e');
    }
  }

  @override
  Future<void> updatePlan(PlanModel plan) async {
    try {
      final planMap = plan.toMap();
      planMap.remove('id'); // Remove id before update
      planMap['updatedAt'] = Timestamp.fromDate(DateTime.now());
      // Ensure userId matches current user
      planMap['userId'] = _currentUserId;

      await _plansCollection.doc(plan.id).update(planMap);
    } catch (e) {
      throw Exception('Failed to update plan: $e');
    }
  }

  @override
  Future<void> deletePlan(String planId) async {
    try {
      await _plansCollection.doc(planId).delete();
    } catch (e) {
      throw Exception('Failed to delete plan: $e');
    }
  }

  @override
  Future<DailyPlan?> getDailyPlan(String planId, DateTime date) async {
    try {
      final plan = await getPlanById(planId);
      if (plan == null) return null;

      // Normalize dates to compare only date part
      final targetDate = DateTime(date.year, date.month, date.day);

      for (final dailyPlan in plan.dailyPlans) {
        final planDate = DateTime(
          dailyPlan.date.year,
          dailyPlan.date.month,
          dailyPlan.date.day,
        );

        if (planDate.isAtSameMomentAs(targetDate)) {
          return dailyPlan;
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get daily plan: $e');
    }
  }
}

