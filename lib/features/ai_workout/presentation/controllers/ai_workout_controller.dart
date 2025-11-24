import 'package:flutter/foundation.dart';
import '../../domain/repositories/ai_workout_repository.dart';
import 'package:recalim/features/workouts/domain/entities/workout_planning_input.dart';

class AiWorkoutController extends ChangeNotifier {
  final AiWorkoutRepository _repository;

  AiWorkoutController(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaved = false;
  bool get isSaved => _isSaved;

  String? _error;
  String? get error => _error;

  Future<void> savePreferences(WorkoutPlanningInput input) async {
    _isLoading = true;
    _error = null;
    _isSaved = false;
    notifyListeners();

    try {
      await _repository.saveWorkoutPreferences(input);
      _isSaved = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void reset() {
    _isSaved = false;
    _error = null;
    notifyListeners();
  }
}
