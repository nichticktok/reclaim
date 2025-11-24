import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/custom_workout_plan.dart';
import '../../domain/repositories/custom_workout_repository.dart';
import '../../data/repositories/firestore_custom_workout_repository.dart';

class WorkoutCounterController extends ChangeNotifier {
  final CustomWorkoutRepository _repository = FirestoreCustomWorkoutRepository();

  List<CustomWorkoutPlan> _workoutPlans = [];
  CustomWorkoutPlan? _currentPlan;
  bool _loading = false;
  String? _error;

  List<CustomWorkoutPlan> get workoutPlans => _workoutPlans;
  CustomWorkoutPlan? get currentPlan => _currentPlan;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    if (_workoutPlans.isNotEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _workoutPlans = await _repository.getUserCustomWorkoutPlans(user.uid);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading custom workout plans: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> saveCustomWorkoutPlan(CustomWorkoutPlan plan) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final planWithUserId = plan.copyWith(
        userId: user.uid,
        createdAt: plan.id.isEmpty ? DateTime.now() : plan.createdAt,
        updatedAt: DateTime.now(),
      );

      String planId;
      if (plan.id.isEmpty) {
        planId = await _repository.saveCustomWorkoutPlan(planWithUserId);
      } else {
        await _repository.updateCustomWorkoutPlan(planWithUserId);
        planId = plan.id;
      }

      await refresh();
      return planId;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error saving custom workout plan: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCustomWorkoutPlan(String planId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteCustomWorkoutPlan(planId);
      await refresh();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting custom workout plan: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlanById(String planId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _currentPlan = await _repository.getCustomWorkoutPlanById(planId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading workout plan: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateWorkoutCompletion(String planId, Duration completionTime) async {
    try {
      final plan = await _repository.getCustomWorkoutPlanById(planId);
      if (plan == null) return;

      final updatedPlan = plan.copyWith(
        totalWorkouts: plan.totalWorkouts + 1,
        bestTime: plan.bestTime == null || completionTime < plan.bestTime!
            ? completionTime
            : plan.bestTime,
        updatedAt: DateTime.now(),
      );

      await _repository.updateCustomWorkoutPlan(updatedPlan);
      await refresh();
    } catch (e) {
      debugPrint('Error updating workout completion: $e');
    }
  }

  Future<void> refresh() async {
    _workoutPlans = [];
    await initialize();
  }
}

