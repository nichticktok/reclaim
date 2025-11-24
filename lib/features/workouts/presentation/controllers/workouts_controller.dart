import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/workout_model.dart';
import '../../domain/entities/workout_planning_input.dart';
import '../../domain/entities/workout_plan.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../data/repositories/firestore_workout_repository.dart';
import '../../data/services/ai_workout_planning_service.dart';
import '../../../tasks/domain/repositories/deletion_request_repository.dart';
import '../../../tasks/data/services/accountability_service.dart';
import '../../../../core/models/deletion_request_model.dart';
import '../../../../core/services/plan_tasks_sync_service.dart';

class WorkoutsController extends ChangeNotifier {
  final WorkoutRepository _repository = FirestoreWorkoutRepository();
  final AIWorkoutPlanningService _aiService = AIWorkoutPlanningService();

  List<WorkoutPlanModel> _workoutPlans = [];
  WorkoutPlanModel? _activePlan;
  WorkoutPlan? _generatedPlan;
  WorkoutPlanModel? _generatedDailyPlan; // Store the saved daily plan
  bool _loading = false;
  String? _error;

  DeletionRequestRepository? _deletionRequestRepository;
  AccountabilityService? _accountabilityService;

  void setDeletionRequestRepository(DeletionRequestRepository repository) {
    _deletionRequestRepository = repository;
  }

  void setAccountabilityService(AccountabilityService service) {
    _accountabilityService = service;
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

  List<WorkoutPlanModel> get workoutPlans => _workoutPlans;
  WorkoutPlanModel? get activePlan => _activePlan;
  WorkoutPlan? get generatedPlan => _generatedPlan;
  WorkoutPlanModel? get generatedDailyPlan => _generatedDailyPlan;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    if (_workoutPlans.isNotEmpty) return; // Already initialized
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _workoutPlans = await _repository.getUserWorkoutPlans(user.uid);
      
      // Find active plan
      try {
        _activePlan = await _repository.getActiveWorkoutPlan(user.uid);
      } catch (e) {
        _activePlan = null; // No active plan
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading workout plans: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }  /// Generate a workout plan using AI and save to workout_plans collection
  Future<WorkoutPlan> generatePlan(WorkoutPlanningInput input) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Generate both WorkoutPlan (for review screen) and WorkoutPlanModel (for Firestore)
      _generatedPlan = await _aiService.generateWorkoutPlan(input);
      
      // Generate daily workout plan and save to Firestore workout_plans collection
      final dailyWorkoutPlan = await _aiService.generateDailyWorkoutPlan(input, user.uid);
      final savedPlan = await _repository.createWorkoutPlan(dailyWorkoutPlan);
      
      // Save workout days
      if (savedPlan.workoutDays.isNotEmpty) {
        await _repository.createWorkoutDays(savedPlan.id, savedPlan.workoutDays);
      }
      
      _generatedDailyPlan = savedPlan;

      debugPrint('✅ AI workout plan generated and saved to workout_plans collection: ${savedPlan.id}');
      
      return _generatedPlan!;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error generating workout plan: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Generate a daily workout plan using AI and save it directly
  Future<WorkoutPlanModel> generateAndSaveDailyWorkoutPlan(WorkoutPlanningInput input) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Generate daily workout plan using AI
      final workoutPlan = await _aiService.generateDailyWorkoutPlan(input, user.uid);

      // Save the plan
      final createdPlan = await _repository.createWorkoutPlan(workoutPlan);

      // Save workout days
      if (workoutPlan.workoutDays.isNotEmpty) {
        await _repository.createWorkoutDays(createdPlan.id, workoutPlan.workoutDays);
      }

      // Reload plans
      await refresh();

      debugPrint('✅ Created workout plan ${createdPlan.id} with ${workoutPlan.workoutDays.length} workout days');
      return createdPlan;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error generating and saving workout plan: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<WorkoutPlanModel> createPlanFromGenerated(
    WorkoutPlanningInput input,
    WorkoutPlan plan,
  ) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Calculate dates
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: input.durationWeeks * 7));

      // Create workout plan
      final workoutPlan = WorkoutPlanModel(
        id: '',
        userId: user.uid,
        goalType: input.goalType,
        fitnessLevel: input.fitnessLevel,
        durationWeeks: input.durationWeeks,
        sessionsPerWeek: input.sessionsPerWeek,
        minutesPerSession: input.minutesPerSession,
        startDate: startDate,
        endDate: endDate,
        status: 'active',
        equipment: input.equipment,
        constraints: input.constraints,
        planData: plan.toMap(),
      );

      final createdPlan = await _repository.createWorkoutPlan(workoutPlan);

      // Create workout days and schedule them
      final workoutDays = <WorkoutDayModel>[];
      var currentDate = startDate;
      int sessionCounter = 0;

      for (var week in plan.weeks) {
        for (var session in week.sessions) {
          // Schedule sessions based on sessionsPerWeek
          // Distribute evenly across the week
          final daysBetweenSessions = (7 / input.sessionsPerWeek).ceil();
          if (sessionCounter > 0) {
            currentDate = currentDate.add(Duration(days: daysBetweenSessions));
          }

          final order = sessionCounter + 1;

          // Create exercises
          final exercises = session.exercises.map((ex) {
            // Determine equipment from exercise name or use first available
            String equipment = input.equipment.isNotEmpty 
                ? input.equipment.first 
                : 'bodyweight';
            
            // Determine intensity based on fitness level
            String intensity = input.fitnessLevel == 'beginner' 
                ? 'easy' 
                : input.fitnessLevel == 'advanced' 
                    ? 'hard' 
                    : 'medium';

            return WorkoutExerciseModel(
              id: '',
              workoutDayId: '',
              name: ex.name,
              sets: ex.sets,
              reps: ex.reps,
              restSeconds: ex.restSeconds,
              instructions: ex.instructions,
              equipment: equipment,
              intensityLevel: intensity,
            );
          }).toList();

          workoutDays.add(WorkoutDayModel(
            id: '',
            planId: createdPlan.id,
            weekNumber: week.weekNumber,
            dayLabel: session.title,
            scheduledDate: currentDate,
            focus: session.focus,
            order: order,
            minutes: input.minutesPerSession,
            exercises: exercises,
          ));

          sessionCounter++;
        }
      }

      // Save workout days
      await _repository.createWorkoutDays(createdPlan.id, workoutDays);

      // Persist full AI plan structure for later use
      try {
        await _repository.updateWorkoutPlan(
          createdPlan.copyWith(planData: plan.toMap()),
        );
        debugPrint('🧱 Stored workout plan ${createdPlan.id} with ${plan.weeks.length} weeks.');
      } catch (e) {
        debugPrint('Warning: Failed to persist planData: $e');
      }

      // Reload plans
      await refresh();

      return createdPlan;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating workout plan: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await initialize();
  }

  Future<void> markWorkoutDayComplete(String dayId) async {
    try {
      // Find the day
      for (var plan in _workoutPlans) {
        for (var day in plan.workoutDays) {
          if (day.id == dayId) {
            final updatedDay = day.copyWith(
              isCompleted: true,
              completedAt: DateTime.now(),
            );
            await _repository.updateWorkoutDay(updatedDay);
            await refresh();
            return;
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking workout day complete: $e');
      rethrow;
    }
  }

  Future<WorkoutDayModel?> getTodaysWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return await _repository.getTodaysWorkout(user.uid);
  }

  void clearGeneratedPlan() {
    _generatedPlan = null;
    notifyListeners();
  }

  /// Delete a workout plan (called after approval)
  Future<void> deleteWorkoutPlan(String planId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteWorkoutPlan(planId);
      
      // Remove from local list
      _workoutPlans.removeWhere((plan) => plan.id == planId);
      if (_activePlan?.id == planId) {
        _activePlan = null;
      }

      debugPrint('✅ Deleted workout plan $planId');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting workout plan: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Elevated access deletion - bypasses accountability requirement (DEBUG MODE ONLY)
  Future<void> deleteWorkoutPlanElevated(String planId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteWorkoutPlan(planId);
      
      // Remove from local list
      _workoutPlans.removeWhere((plan) => plan.id == planId);
      if (_activePlan?.id == planId) {
        _activePlan = null;
      }

      debugPrint('✅ [ELEVATED ACCESS] Deleted workout plan $planId without accountability approval');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting workout plan with elevated access: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Create a workout plan deletion request (requires accountability partner approval)
  Future<DeletionRequestModel> createWorkoutPlanDeletionRequest({
    required String planId,
    required String planTitle,
    required String reason,
    required String accountabilityPartnerContact,
    required String contactType, // 'phone' or 'email'
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Validate contact format
      if (!accountabilityService.isValidContact(accountabilityPartnerContact, contactType)) {
        throw Exception('Invalid ${contactType == 'phone' ? 'phone number' : 'email address'} format');
      }

      // Create deletion request (using plan deletion request for now, we can extend later)
      final request = await deletionRequestRepository.createPlanDeletionRequest(
        userId: user.uid,
        planId: planId,
        planTitle: planTitle,
        reason: reason,
        accountabilityPartnerContact: accountabilityPartnerContact,
        contactType: contactType,
      );

      // Update workout plan's deletionStatus to "pending"
      try {
        final plan = await _repository.getWorkoutPlanById(planId);
        if (plan != null) {
          final updatedPlan = plan.copyWith(deletionStatus: "pending");
          await _repository.updateWorkoutPlan(updatedPlan);
          
          // Update local list
          final index = _workoutPlans.indexWhere((p) => p.id == planId);
          if (index != -1) {
            _workoutPlans[index] = updatedPlan;
          }
        }
      } catch (e) {
        debugPrint('Error updating workout plan deletion status: $e');
      }

      // Send accountability message (SMS or Email)
      final sent = await accountabilityService.sendDeletionRequest(request: request);
      if (!sent) {
        debugPrint('Warning: Failed to send accountability message, but request was created');
      }

      notifyListeners();
      return request;
    } catch (e) {
      debugPrint('Error creating workout plan deletion request: $e');
      rethrow;
    }
  }

  /// Get pending deletion request for a workout plan
  Future<DeletionRequestModel?> getPendingDeletionRequestForWorkoutPlan(String planId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      return await deletionRequestRepository.getPendingDeletionRequestForPlan(user.uid, planId);
    } catch (e) {
      debugPrint('Error getting pending deletion request for workout plan: $e');
      return null;
    }
  }

  /// Sync workout plan to daily tasks
  Future<void> syncWorkoutPlanToTasks(String workoutPlanId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final syncService = PlanTasksSyncService();
      await syncService.syncWorkoutPlanToTasks(workoutPlanId);

      debugPrint('✅ Synced workout plan $workoutPlanId to tasks');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error syncing workout plan to tasks: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

