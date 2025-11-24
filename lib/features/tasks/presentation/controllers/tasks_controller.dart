import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recalim/core/models/habit_model.dart';
import 'package:recalim/core/models/preset_task_model.dart';
import 'package:recalim/core/models/proof_submission_model.dart';
import 'package:recalim/core/constants/proof_types.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../../domain/repositories/proof_repository.dart';
import '../../domain/repositories/deletion_request_repository.dart';
import '../../data/repositories/firestore_tasks_repository.dart';
import '../../data/repositories/firestore_deletion_request_repository.dart';
import '../../data/repositories/preset_tasks_repository.dart';
import '../../data/services/accountability_service.dart';
import '../../../progress/data/repositories/firestore_user_stats_repository.dart';
import '../../../../core/models/deletion_request_model.dart';

class TasksController extends ChangeNotifier {
  final TasksRepository _repository = FirestoreTasksRepository();
  final PresetTasksRepository _presetRepository = PresetTasksRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreUserStatsRepository _statsRepository = FirestoreUserStatsRepository();
  
  // ProofRepository will be injected via constructor or setter
  ProofRepository? _proofRepository;
  DeletionRequestRepository? _deletionRequestRepository;
  AccountabilityService? _accountabilityService;
  
  void setProofRepository(ProofRepository proofRepository) {
    _proofRepository = proofRepository;
  }
  
  void setDeletionRequestRepository(DeletionRequestRepository repository) {
    _deletionRequestRepository = repository;
  }
  
  void setAccountabilityService(AccountabilityService service) {
    _accountabilityService = service;
  }
  
  ProofRepository get proofRepository {
    if (_proofRepository == null) {
      throw Exception('ProofRepository not initialized. Please inject it via setProofRepository or DI.');
    }
    return _proofRepository!;
  }
  
  DeletionRequestRepository get deletionRequestRepository {
    if (_deletionRequestRepository == null) {
      throw Exception('DeletionRequestRepository not initialized.');
    }
    return _deletionRequestRepository!;
  }
  
  AccountabilityService get accountabilityService {
    if (_accountabilityService == null) {
      throw Exception('AccountabilityService not initialized.');
    }
    return _accountabilityService!;
  }
  
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

  /// Reload habits from Firestore (without full initialization)
  Future<void> reloadHabits() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _habits = await _repository.getTodayHabits(user.uid);
      debugPrint('✅ Reloaded ${_habits.length} habits from database');
      notifyListeners();
    } catch (e) {
      debugPrint('Error reloading habits: $e');
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

  /// Submit proof for a habit (legacy text-only method)
  Future<void> submitProof(HabitModel habit, String proof) async {
    try {
      // If habit has proofType, use new proof submission system
      if (habit.proofType != null && habit.proofType != ProofTypes.text) {
        throw Exception('Use submitProofWithType() for non-text proof types');
      }
      
      // Use new proof system if proofType is text or fallback to old system
      if (habit.proofType == ProofTypes.text) {
        await submitProofWithType(
          habit,
          ProofSubmission(
            id: '',
            habitId: habit.id,
            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            proofType: ProofTypes.text,
            textContent: proof,
            dateKey: HabitModel.getTodayDateString(),
          ),
        );
      } else {
        // Fallback to old system for backward compatibility
      await _repository.submitProof(habit.id, proof);
      habit.markCompletedToday(proof: proof);
      }
      
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

  /// Submit proof with type (new proof submission system)
  Future<void> submitProofWithType(
    HabitModel habit,
    ProofSubmission proof,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Validate proof type matches habit requirement
      if (habit.proofType != null &&
          habit.proofType != ProofTypes.any &&
          proof.proofType != habit.proofType) {
        throw Exception(
            'Proof type mismatch. Expected: ${habit.proofType}, got: ${proof.proofType}');
      }

      // Ensure proof is valid
      if (!proof.isValid()) {
        throw Exception('Proof submission is not valid for its type');
      }

      // Submit proof via ProofRepository
      await proofRepository.submitProof(habit.id, proof);

      // Mark habit as completed
      await _repository.completeHabit(habit.id);

      // Refresh habits to get updated status
      _habits = await _repository.getTodayHabits(user.uid);

      // Update stats
      await _statsRepository.incrementTasksCompleted(user.uid);
      await _updateProgressStats(user.uid);

      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting proof with type: $e');
      rethrow;
    }
  }

  /// Get proof for a habit on a specific date
  Future<ProofSubmission?> getProofForDate(
    String habitId,
    String dateKey,
  ) async {
    try {
      return await proofRepository.getProofForDate(habitId, dateKey);
    } catch (e) {
      debugPrint('Error getting proof for date: $e');
      return null;
    }
  }

  /// Get all proofs for a habit
  Future<List<ProofSubmission>> getProofsForHabit(String habitId) async {
    try {
      return await proofRepository.getProofsForHabit(habitId);
    } catch (e) {
      debugPrint('Error getting proofs for habit: $e');
      return [];
    }
  }

  /// Skip a task (only for system-assigned tasks)
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
      
      // Refresh habits
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _habits = await _repository.getTodayHabits(user.uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error skipping habit: $e');
      rethrow;
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

  /// Add a preset task to user's habits with a custom schedule (days + time)
  Future<void> addPresetTask({
    required PresetTaskModel presetTask,
    required String title,
    required String description,
    required String scheduledTime,
    required List<int> daysOfWeek,
  }) async {
    try {
      if (daysOfWeek.isEmpty) {
        throw Exception('Select at least one day of the week.');
      }

      // Prevent creating duplicate schedules for the exact same preset + time + days combo
      final hasDuplicateSchedule = _habits.any((habit) {
        final existingDays = [...habit.daysOfWeek]..sort();
        final newDays = [...daysOfWeek]..sort();
        return habit.presetTaskId == presetTask.id &&
            habit.scheduledTime == scheduledTime &&
            listEquals(existingDays, newDays);
      });

      if (hasDuplicateSchedule) {
        throw Exception('Task already scheduled for those days.');
      }

      final habit = HabitModel(
        id: '', // Assigned by Firestore
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        requiresProof: _hardModeEnabled == true ? true : presetTask.requiresProof,
        proofType: presetTask.proofType ?? (presetTask.requiresProof ? ProofTypes.text : null),
        isPreset: true,
        attribute: presetTask.attribute,
        metadata: {
          'presetTaskId': presetTask.id,
        },
        daysOfWeek: daysOfWeek,
        presetTaskId: presetTask.id,
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

  /// Delete a habit with reason (only works for user-added habits, not preset tasks)
  /// This method now checks for approved deletion request before deleting
  /// Use createDeletionRequest() to request deletion instead
  Future<void> deleteHabit(String habitId, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      // Check if there's an approved deletion request
      final request = await deletionRequestRepository.getPendingDeletionRequestForHabit(user.uid, habitId);
      
      if (request == null) {
        throw Exception('No deletion request found. Please create a deletion request first.');
      }
      
      if (request.status != DeletionRequestStatus.approved) {
        throw Exception('Deletion request has not been approved yet. Current status: ${request.status.value}');
      }
      
      // Request was approved, proceed with deletion
      await _repository.deleteHabit(habitId, reason);
      _habits.removeWhere((h) => h.id == habitId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      rethrow;
    }
  }

  /// Elevated access deletion - bypasses accountability requirement (DEBUG MODE ONLY)
  /// This method directly deletes a habit without requiring approval
  /// NOTE: Future tasks cannot be deleted even with elevated access
  Future<void> deleteHabitElevated(String habitId, String reason, {DateTime? viewDate}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      // Check if this is a future task - prevent deletion even with elevated access
      if (viewDate != null) {
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);
        final viewDateNormalized = DateTime(viewDate.year, viewDate.month, viewDate.day);
        if (viewDateNormalized.isAfter(todayNormalized)) {
          throw Exception('Future tasks cannot be deleted, even with elevated access.');
        }
      }
      
      // Direct deletion without checking for approval
      await _repository.deleteHabit(habitId, reason);
      _habits.removeWhere((h) => h.id == habitId);
      notifyListeners();
      
      debugPrint('✅ [ELEVATED ACCESS] Deleted habit $habitId without accountability approval');
    } catch (e) {
      debugPrint('Error deleting habit with elevated access: $e');
      rethrow;
    }
  }
  
  /// Delete a habit immediately (internal use, bypasses approval)
  /// Only use this for approved deletions or system operations
  Future<void> _deleteHabitInternal(String habitId, String reason) async {
    // Update habit's deletionStatus to "deleted" and set isActive to false
    try {
      final habit = await _repository.getHabitById(habitId);
      final updatedHabit = habit.copyWith(
        deletionStatus: "deleted",
        isActive: false,
      );
      await _repository.updateHabit(updatedHabit);
      
      // Remove from local list
      _habits.removeWhere((h) => h.id == habitId);
    } catch (e) {
      debugPrint('Error updating habit deletion status: $e');
      // Fallback to direct deletion
      await _repository.deleteHabit(habitId, reason);
      _habits.removeWhere((h) => h.id == habitId);
    }
    notifyListeners();
  }

  /// Create a deletion request (removes from user's habits, not from preset tasks)
  Future<DeletionRequestModel> createDeletionRequest({
    required String habitId,
    required String habitTitle,
    required String reason,
    required String accountabilityPartnerContact,
    required String contactType, // 'phone' or 'email'
    DateTime? viewDate, // The date being viewed (to check if it's a future task)
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Prevent deletion requests for future tasks
      if (viewDate != null) {
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);
        final viewDateNormalized = DateTime(viewDate.year, viewDate.month, viewDate.day);
        if (viewDateNormalized.isAfter(todayNormalized)) {
          throw Exception('Future tasks cannot be deleted. You can only delete tasks for today or past dates.');
        }
      }

      // Validate contact format
      if (!accountabilityService.isValidContact(accountabilityPartnerContact, contactType)) {
        throw Exception('Invalid ${contactType == 'phone' ? 'phone number' : 'email address'} format');
      }

      // Create deletion request
      final request = await deletionRequestRepository.createDeletionRequest(
        userId: user.uid,
        habitId: habitId,
        habitTitle: habitTitle,
        reason: reason,
        accountabilityPartnerContact: accountabilityPartnerContact,
        contactType: contactType,
      );

      // Update habit's deletionStatus to "pending" (but keep isActive true)
      try {
        debugPrint('🔄 Starting habit update for deletion request. Habit ID: $habitId');
        final habit = await _repository.getHabitById(habitId);
        debugPrint('📋 Current habit deletionStatus: ${habit.deletionStatus}');
        
        final updatedHabit = habit.copyWith(
          deletionStatus: "pending",
          // Keep isActive as true for pending deletions
        );
        debugPrint('📋 Updated habit deletionStatus: ${updatedHabit.deletionStatus}');
        debugPrint('📋 Updated habit toMap deletionStatus: ${updatedHabit.toMap()['deletionStatus']}');
        
        await _repository.updateHabit(updatedHabit);
        debugPrint('✅ Successfully called updateHabit for habit $habitId');
        
        // Reload habits from Firestore to ensure we have the latest data
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _habits = await _repository.getTodayHabits(user.uid);
          final reloadedHabit = _habits.where((h) => h.id == habitId).isNotEmpty 
              ? _habits.where((h) => h.id == habitId).first 
              : null;
          if (reloadedHabit != null) {
            debugPrint('✅ Reloaded habits after deletion request. Habit $habitId deletionStatus: ${reloadedHabit.deletionStatus}');
          } else {
            debugPrint('⚠️ Habit $habitId not found in reloaded habits list');
          }
        } else {
          // Fallback: Update local habits list if reload fails
          final index = _habits.indexWhere((h) => h.id == habitId);
          if (index != -1) {
            _habits[index] = updatedHabit;
            debugPrint('✅ Updated local habits list with deletionStatus: ${updatedHabit.deletionStatus}');
          }
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error updating habit deletion status: $e');
        debugPrint('❌ Stack trace: $stackTrace');
        // Continue even if update fails - deletion request was created
      }

      // Send accountability message (SMS or Email)
      final sent = await accountabilityService.sendDeletionRequest(request: request);
      if (!sent) {
        debugPrint('Warning: Failed to send accountability message, but request was created');
      }

      notifyListeners();
      return request;
    } catch (e) {
      debugPrint('Error creating deletion request: $e');
      rethrow;
    }
  }

  /// Get pending deletion request for a habit
  Future<DeletionRequestModel?> getPendingDeletionRequestForHabit(String habitId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      return await deletionRequestRepository.getPendingDeletionRequestForHabit(user.uid, habitId);
    } catch (e) {
      debugPrint('Error getting pending deletion request: $e');
      return null;
    }
  }

  /// Check if habit has pending deletion request
  Future<bool> hasPendingDeletionRequest(String habitId) async {
    final request = await getPendingDeletionRequestForHabit(habitId);
    return request != null && request.status == DeletionRequestStatus.pending;
  }

  /// Process approved deletion requests and delete habits automatically
  /// This should be called periodically or when checking for deletions
  Future<void> processApprovedDeletions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get all requests to check for approved ones
      final allRequests = await (deletionRequestRepository as FirestoreDeletionRequestRepository).getAllDeletionRequests(user.uid);
      
      // Filter for approved requests that haven't been processed yet
      final approvedRequests = allRequests
          .where((r) => r.status == DeletionRequestStatus.approved)
          .toList();
      
      for (var request in approvedRequests) {
        // Check if habit still exists before deleting
        final habitExists = _habits.any((h) => h.id == request.habitId);
        
        if (habitExists && request.habitId != null) {
          try {
            // Update habit's deletionStatus to "deleted" and set isActive to false
            final habit = await _repository.getHabitById(request.habitId!);
            final updatedHabit = habit.copyWith(
              deletionStatus: "deleted",
              isActive: false,
            );
            await _repository.updateHabit(updatedHabit);
            
            // Update local habits list
            final index = _habits.indexWhere((h) => h.id == request.habitId);
            if (index != -1) {
              _habits[index] = updatedHabit;
            }
            
            debugPrint('✅ Marked habit ${request.habitId} as deleted after approval');
          } catch (e) {
            debugPrint('Error updating habit deletion status: $e');
            // Fallback to direct deletion
            try {
              await _deleteHabitInternal(request.habitId!, request.reason);
            } catch (e2) {
              debugPrint('Error deleting habit: $e2');
            }
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error processing approved deletions: $e');
    }
  }

  /// Process response from accountability partner (for SMS/Email webhook handlers)
  /// This method can be called when a response is received via webhook
  Future<void> processAccountabilityResponse(String requestId, String response) async {
    try {
      await deletionRequestRepository.processResponse(requestId, response);
      
      // Check if approved and auto-delete
      final request = await deletionRequestRepository.getDeletionRequestById(requestId);
      if (request != null && request.status == DeletionRequestStatus.approved) {
        await processApprovedDeletions();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error processing accountability response: $e');
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
      
      // Refresh habits to get updated completion status
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _habits = await _repository.getTodayHabits(user.uid);
        
        // Update stats
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

