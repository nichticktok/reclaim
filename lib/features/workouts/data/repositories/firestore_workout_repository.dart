import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/workout_model.dart';
import '../../domain/repositories/workout_repository.dart';

class FirestoreWorkoutRepository implements WorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<WorkoutPlanModel> createWorkoutPlan(WorkoutPlanModel plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workout_plans')
        .add(plan.toMap());

    return plan.copyWith(id: docRef.id);
  }

  @override
  Future<List<WorkoutPlanModel>> getUserWorkoutPlans(String userId) async {
    final plansSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workout_plans')
        .orderBy('startDate', descending: true)
        .get();

    final plans = <WorkoutPlanModel>[];
    for (var doc in plansSnapshot.docs) {
      final plan = WorkoutPlanModel.fromMap(doc.data(), doc.id);
      // Load workout days
      final days = await getWorkoutDays(plan.id);
      plans.add(plan.copyWith(workoutDays: days));
    }

    return plans;
  }

  @override
  Future<WorkoutPlanModel?> getActiveWorkoutPlan(String userId) async {
    final plans = await getUserWorkoutPlans(userId);
    try {
      return plans.firstWhere((p) => p.status == 'active');
    } catch (e) {
      return null; // No active plan
    }
  }

  @override
  Future<WorkoutPlanModel?> getWorkoutPlanById(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workout_plans')
        .doc(planId)
        .get();

    if (!doc.exists) return null;

    final plan = WorkoutPlanModel.fromMap(doc.data()!, doc.id);
    final days = await getWorkoutDays(plan.id);
    return plan.copyWith(workoutDays: days);
  }

  @override
  Future<void> updateWorkoutPlan(WorkoutPlanModel plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workout_plans')
        .doc(plan.id)
        .update(plan.toMap());
  }

  @override
  Future<void> deleteWorkoutPlan(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Delete exercises and days first
    final days = await getWorkoutDays(planId);
    for (var day in days) {
      final exercises = await getExercises(day.id);
      for (var exercise in exercises) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workout_plans')
            .doc(planId)
            .collection('workout_days')
            .doc(day.id)
            .collection('exercises')
            .doc(exercise.id)
            .delete();
      }
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_plans')
          .doc(planId)
          .collection('workout_days')
          .doc(day.id)
          .delete();
    }

    // Delete plan
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workout_plans')
        .doc(planId)
        .delete();
  }

  @override
  Future<void> createWorkoutDays(String planId, List<WorkoutDayModel> days) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final batch = _firestore.batch();
    for (var day in days) {
      final dayRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_plans')
          .doc(planId)
          .collection('workout_days')
          .doc();
      
      final dayWithId = day.copyWith(id: dayRef.id);
      batch.set(dayRef, dayWithId.toMap());

      // Create exercises for this day
      for (var exercise in day.exercises) {
        final exerciseRef = dayRef.collection('exercises').doc();
        final exerciseWithId = exercise.copyWith(id: exerciseRef.id, workoutDayId: dayRef.id);
        batch.set(exerciseRef, exerciseWithId.toMap());
      }
    }

    await batch.commit();
  }

  @override
  Future<List<WorkoutDayModel>> getWorkoutDays(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final daysSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workout_plans')
        .doc(planId)
        .collection('workout_days')
        .orderBy('scheduledDate')
        .get();

    final days = <WorkoutDayModel>[];
    for (var doc in daysSnapshot.docs) {
      final day = WorkoutDayModel.fromMap(doc.data(), doc.id);
      final exercises = await getExercises(day.id);
      days.add(day.copyWith(exercises: exercises));
    }

    // Ensure consistent ordering by weekNumber, then scheduledDate
    days.sort((a, b) {
      final weekCompare = a.weekNumber.compareTo(b.weekNumber);
      if (weekCompare != 0) return weekCompare;
      final dateA = a.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.scheduledDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateA.compareTo(dateB);
    });

    return days;
  }

  @override
  Future<void> createExercises(String workoutDayId, List<WorkoutExerciseModel> exercises) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the workout day to get the correct path
    final plansSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workout_plans')
        .get();

    for (var planDoc in plansSnapshot.docs) {
      final dayDoc = await planDoc.reference
          .collection('workout_days')
          .doc(workoutDayId)
          .get();

      if (dayDoc.exists) {
        final batch = _firestore.batch();
        for (var exercise in exercises) {
          final exerciseRef = dayDoc.reference.collection('exercises').doc();
          final exerciseWithId = exercise.copyWith(id: exerciseRef.id);
          batch.set(exerciseRef, exerciseWithId.toMap());
        }
        await batch.commit();
        return;
      }
    }
  }

  @override
  Future<List<WorkoutExerciseModel>> getExercises(String workoutDayId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the workout day
    final plansSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workout_plans')
        .get();

    for (var planDoc in plansSnapshot.docs) {
      final exercisesSnapshot = await planDoc.reference
          .collection('workout_days')
          .doc(workoutDayId)
          .collection('exercises')
          .get();

      if (exercisesSnapshot.docs.isNotEmpty) {
        return exercisesSnapshot.docs
            .map((doc) => WorkoutExerciseModel.fromMap(doc.data(), doc.id))
            .toList();
      }
    }

    return [];
  }

  @override
  Future<void> updateWorkoutDay(WorkoutDayModel day) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the day
    final plansSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workout_plans')
        .get();

    for (var planDoc in plansSnapshot.docs) {
      final dayDoc = await planDoc.reference
          .collection('workout_days')
          .doc(day.id)
          .get();

      if (dayDoc.exists) {
        await dayDoc.reference.update(day.toMap());
        return;
      }
    }
  }

  @override
  Future<WorkoutDayModel?> getTodaysWorkout(String userId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final plans = await getUserWorkoutPlans(userId);
    for (var plan in plans) {
      if (plan.status != 'active') continue;

      for (var day in plan.workoutDays) {
        if (day.scheduledDate != null &&
            day.scheduledDate!.isAfter(todayStart) &&
            day.scheduledDate!.isBefore(todayEnd) &&
            !day.isCompleted) {
          return day;
        }
      }
    }

    return null;
  }
}

