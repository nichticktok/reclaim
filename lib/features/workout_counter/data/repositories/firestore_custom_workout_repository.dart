import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/custom_workout_repository.dart';
import '../../domain/entities/custom_workout_plan.dart';

class FirestoreCustomWorkoutRepository implements CustomWorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> saveCustomWorkoutPlan(CustomWorkoutPlan plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('custom_workout_plans')
        .add(plan.toMap());

    return docRef.id;
  }

  @override
  Future<List<CustomWorkoutPlan>> getUserCustomWorkoutPlans(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_workout_plans')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return CustomWorkoutPlan.fromMap(doc.data(), doc.id);
    }).toList();
  }

  @override
  Future<CustomWorkoutPlan?> getCustomWorkoutPlanById(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('custom_workout_plans')
        .doc(planId)
        .get();

    if (!doc.exists) return null;

    return CustomWorkoutPlan.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> updateCustomWorkoutPlan(CustomWorkoutPlan plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('custom_workout_plans')
        .doc(plan.id)
        .update(plan.toMap());
  }

  @override
  Future<void> deleteCustomWorkoutPlan(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('custom_workout_plans')
        .doc(planId)
        .delete();
  }
}

