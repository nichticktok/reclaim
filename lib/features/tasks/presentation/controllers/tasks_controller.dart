import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/habit_model.dart';
import '../../../../models/preset_task_model.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../../data/repositories/firestore_tasks_repository.dart';
import '../../data/repositories/preset_tasks_repository.dart';
import '../../../progress/data/repositories/firestore_user_stats_repository.dart';

class TasksController extends ChangeNotifier {
  final TasksRepository _repository = FirestoreTasksRepository();
  final PresetTasksRepository _presetRepository = PresetTasksRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreUserStatsRepository _statsRepository = FirestoreUserStatsRepository();
  
  List<HabitModel> _habits = [];
  List<PresetTaskModel> _presetTasks = [];
  String _selectedFilter = "All";
  bool _loading = false;
  bool _loadingPresets = false;
  bool? _hardModeEnabled;
  bool _initialized = false; // Track if already initialized

  List<HabitModel> get habits => _habits;
  List<PresetTaskModel> get presetTasks => _presetTasks;
  String get selectedFilter => _selectedFilter;
  bool get loading => _loading;
  bool get loadingPresets => _loadingPresets;
  bool get hardModeEnabled => _hardModeEnabled ?? false;

  /// Initialize and load habits (only if not already initialized)
  Future<void> initialize({bool forceRefresh = false}) async {
    // Skip if already initialized unless force refresh
    if (_initialized && !forceRefresh) {
      debugPrint('📋 TasksController already initialized, skipping...');
      return;
    }

    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load hard mode setting from onboarding data
      await _loadHardModeSetting(user.uid);

      // Load habits
      _habits = await _repository.getTodayHabits(user.uid);
      debugPrint('✅ Loaded ${_habits.length} habits from database');
      
      // If no habits exist, initialize default tasks
      if (_habits.isEmpty) {
        debugPrint('⚠️ No habits found, initializing default tasks...');
        await _initializeDefaultTasks(user.uid);
        _habits = await _repository.getTodayHabits(user.uid);
        debugPrint('✅ After initialization: ${_habits.length} habits');
      }
      
      // Ensure preset tasks are seeded and loaded (only once)
      if (_presetTasks.isEmpty) {
        await _presetRepository.seedPresetTasks();
        _presetTasks = await _presetRepository.getPresetTasks();
        debugPrint('✅ Loaded ${_presetTasks.length} preset tasks');
      }
      
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading habits: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load preset tasks
  Future<void> loadPresetTasks() async {
    _loadingPresets = true;
    notifyListeners();
    try {
      // Ensure preset tasks are seeded first
      await _presetRepository.seedPresetTasks();
      _presetTasks = await _presetRepository.getPresetTasks();
    } catch (e) {
      debugPrint('Error loading preset tasks: $e');
    } finally {
      _loadingPresets = false;
      notifyListeners();
    }
  }

  /// Load hard mode setting from onboarding data
  Future<void> _loadHardModeSetting(String userId) async {
    try {
      final onboardingDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('onboarding')
          .doc('data')
          .get();
      
      if (onboardingDoc.exists) {
        final data = onboardingDoc.data();
        _hardModeEnabled = data?['hardModeEnabled'] as bool? ?? false;
      } else {
        // Fallback: check old structure
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final onboardingData = userDoc.data()?['onboardingData'] as Map<String, dynamic>?;
        _hardModeEnabled = onboardingData?['hardModeEnabled'] as bool? ?? false;
      }
    } catch (e) {
      debugPrint('Error loading hard mode setting: $e');
      _hardModeEnabled = false;
    }
  }

  /// Initialize default tasks based on onboarding data
  Future<void> _initializeDefaultTasks(String userId) async {
    try {
      // Get onboarding data
      Map<String, dynamic> onboardingData = {};
      
      final onboardingDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('onboarding')
          .doc('data')
          .get();
      
      if (onboardingDoc.exists) {
        onboardingData = onboardingDoc.data() ?? {};
      } else {
        // Fallback: check old structure
        final userDoc = await _firestore.collection('users').doc(userId).get();
        onboardingData = userDoc.data()?['onboardingData'] as Map<String, dynamic>? ?? {};
      }

      await _repository.initializeDefaultTasks(userId, onboardingData);
    } catch (e) {
      debugPrint('Error initializing default tasks: $e');
    }
  }

  /// Filter habits
  List<HabitModel> getFilteredHabits() {
    switch (_selectedFilter) {
      case "Pending":
        return _habits.where((h) => !h.completed).toList();
      case "Completed":
        return _habits.where((h) => h.completed).toList();
      default:
        return _habits;
    }
  }

  /// Set filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Complete a habit
  Future<void> completeHabit(HabitModel habit, {String? proof}) async {
    try {
      await _repository.completeHabit(habit.id, proof: proof);
      habit.markCompletedToday(proof: proof);
      
      // Refresh habits to get updated completion status
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _habits = await _repository.getTodayHabits(user.uid);
        
        // Update stats
        await _statsRepository.incrementTasksCompleted(user.uid);
        await _updateProgressStats(user.uid);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing habit: $e');
      rethrow;
    }
  }

  /// Submit proof for a habit
  Future<void> submitProof(HabitModel habit, String proof) async {
    try {
      await _repository.submitProof(habit.id, proof);
      habit.markCompletedToday(proof: proof);
      
      // Refresh habits to get updated proof status
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _habits = await _repository.getTodayHabits(user.uid);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting proof: $e');
      rethrow;
    }
  }

  /// Skip a task (only for system-assigned tasks, with consequences)
  Future<void> skipHabit(HabitModel habit) async {
    try {
      // Only system-assigned tasks can be skipped
      if (!habit.isSystemAssigned) {
        throw Exception('Only system-assigned tasks can be skipped');
      }

      // Cannot skip if already completed
      if (habit.isCompletedToday()) {
        throw Exception('Cannot skip a completed task');
      }

      await _repository.skipHabit(habit.id);
      habit.markSkippedToday();
      
      // Apply consequences - add a task for tomorrow
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _applySkipConsequences(user.uid, habit);
      }
      
      // Refresh habits
      _habits = await _repository.getTodayHabits(user!.uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error skipping habit: $e');
      rethrow;
    }
  }

  /// Apply consequences for skipping a task - adds a task for tomorrow
  Future<void> _applySkipConsequences(String userId, HabitModel skippedHabit) async {
    try {
      // Create a penalty task that's similar to the skipped task
      // This task will appear in the user's list tomorrow
      final penaltyTask = HabitModel(
        id: '', // Will be set by Firestore
        title: skippedHabit.title,
        description: '${skippedHabit.description} (Penalty for skipping yesterday)',
        scheduledTime: skippedHabit.scheduledTime,
        requiresProof: skippedHabit.requiresProof,
        isPreset: true,
        isSystemAssigned: true,
        difficulty: skippedHabit.difficulty,
      );
      
      // Add the penalty task to Firestore
      // It will automatically appear in tomorrow's task list
      await _repository.addHabit(penaltyTask);
      
      debugPrint('⚠️ Skip consequence: Added penalty task "${penaltyTask.title}" for tomorrow');
    } catch (e) {
      debugPrint('Error applying skip consequences: $e');
    }
  }

  /// Check if proof is required for a habit
  bool isProofRequired(HabitModel habit) {
    return habit.isProofRequired(_hardModeEnabled ?? false);
  }

  /// Add a new habit
  Future<void> addHabit(HabitModel habit) async {
    try {
      // Apply hard mode: if enabled, all tasks require proof
      if (_hardModeEnabled == true) {
        habit.requiresProof = true;
      }
      
      await _repository.addHabit(habit);
      // Reload habits to get the updated list with IDs
      await refresh();
    } catch (e) {
      debugPrint('Error adding habit: $e');
      rethrow;
    }
  }

  /// Add a preset task to user's habits
  Future<void> addPresetTask(PresetTaskModel presetTask) async {
    try {
      // Check if user already has this task
      final hasTask = _habits.any(
        (h) => h.title.toLowerCase() == presetTask.title.toLowerCase(),
      );

      if (hasTask) {
        throw Exception('Task already exists');
      }

      // Convert preset task to habit (mark as preset)
      final habit = HabitModel(
        id: '', // Will be set by Firestore
        title: presetTask.title,
        description: presetTask.description,
        scheduledTime: presetTask.scheduledTime,
        requiresProof: _hardModeEnabled == true ? true : presetTask.requiresProof,
        isPreset: true, // Mark as preset task
      );

      await addHabit(habit);
    } catch (e) {
      debugPrint('Error adding preset task: $e');
      rethrow;
    }
  }

  /// Get last deletion reason
  Future<String?> getLastDeletionReason() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    try {
      return await (_repository as FirestoreTasksRepository).getLastDeletionReason(user.uid);
    } catch (e) {
      debugPrint('Error getting last deletion reason: $e');
      return null;
    }
  }

  /// Delete a habit with reason
  Future<void> deleteHabit(String habitId, String reason) async {
    try {
      await _repository.deleteHabit(habitId, reason);
      _habits.removeWhere((h) => h.id == habitId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      rethrow;
    }
  }

  /// Get habit by ID
  Future<HabitModel> getHabitById(String habitId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');
    return await _repository.getHabitById(habitId);
  }

  /// Undo completion of a habit (for today)
  Future<void> undoCompleteHabit(HabitModel habit) async {
    try {
      await _repository.undoCompleteHabit(habit.id);
      // Update local state
      final today = HabitModel.getTodayDateString();
      habit.dailyCompletion.remove(today);
      habit.proofs.remove(today);
      habit.completed = false;
      
      // Update stats
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _statsRepository.decrementTasksCompleted(user.uid);
        await _updateProgressStats(user.uid);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error undoing habit completion: $e');
      rethrow;
    }
  }

  /// Update progress stats in stats collection
  Future<void> _updateProgressStats(String userId) async {
    try {
      // Calculate today's progress
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      int totalHabits = _habits.length;
      int completedHabits = _habits.where((h) => h.dailyCompletion[todayStr] == true).length;
      double progress = totalHabits > 0 ? (completedHabits / totalHabits) : 0.0;
      
      await _statsRepository.updateOverallProgress(userId, progress);
      
      // Update streak
      int streak = await _calculateCurrentStreak(userId);
      await _statsRepository.updateCurrentStreak(userId, streak);
    } catch (e) {
      debugPrint('Error updating progress stats: $e');
    }
  }

  /// Calculate current streak
  Future<int> _calculateCurrentStreak(String userId) async {
    if (_habits.isEmpty) return 0;
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    while (true) {
      final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      bool allCompleted = true;
      
      for (var habit in _habits) {
        if (habit.dailyCompletion[dateStr] != true) {
          allCompleted = false;
          break;
        }
      }
      
      if (allCompleted && _habits.isNotEmpty) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Refresh habits from database (light refresh - doesn't re-initialize)
  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _habits = await _repository.getTodayHabits(user.uid);
      notifyListeners();
    }
  }

  /// Force refresh (re-initialize everything)
  Future<void> forceRefresh() async {
    _initialized = false;
    await initialize(forceRefresh: true);
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

