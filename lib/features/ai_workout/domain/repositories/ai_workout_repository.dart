import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../features/workouts/domain/entities/workout_planning_input.dart';

abstract class AiWorkoutRepository {
  Future<void> saveWorkoutPreferences(WorkoutPlanningInput input);
}

class AiWorkoutRepositoryImpl implements AiWorkoutRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AiWorkoutRepositoryImpl(this._firestore, this._auth);

  @override
  Future<void> saveWorkoutPreferences(WorkoutPlanningInput input) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workout')
        .doc('requirements')
        .set(input.toMap());
  }
}
