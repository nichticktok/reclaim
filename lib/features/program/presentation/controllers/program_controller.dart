import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/program_repository.dart';
import '../../data/repositories/firestore_program_repository.dart';

/// Program Controller
/// Handles: 66-day program creation, week-based task planning, program customization
class ProgramController extends ChangeNotifier {
  final ProgramRepository _repository = FirestoreProgramRepository();
  bool _loading = false;
  Map<String, dynamic>? _currentProgram;
  String? _error;

  bool get loading => _loading;
  Map<String, dynamic>? get currentProgram => _currentProgram;
  String? get error => _error;

  /// Initialize and load current program
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _currentProgram = await _repository.getCurrentProgram(user.uid);
      debugPrint('✅ Program loaded: ${_currentProgram != null ? "Found" : "Not found"}');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading program: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create new 66-day program
  Future<void> createProgram(Map<String, dynamic> programData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      await _repository.createProgram(user.uid, programData);
      _currentProgram = await _repository.getCurrentProgram(user.uid);
      debugPrint('✅ Program created successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error creating program: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get tasks for a specific week
  Future<List<Map<String, dynamic>>> getWeekTasks(int weekNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return [];
    }

    try {
      return await _repository.getWeekTasks(user.uid, weekNumber);
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error fetching week tasks: $e');
      return [];
    }
  }

  /// Update task in program
  Future<void> updateTask(String taskId, Map<String, dynamic> taskData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    try {
      await _repository.updateTask(user.uid, taskId, taskData);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error updating task: $e');
    }
  }

  /// Delete task from program
  Future<void> deleteTask(String taskId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    try {
      await _repository.deleteTask(user.uid, taskId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting task: $e');
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

