import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/project_model.dart';
import 'package:recalim/core/models/plan_model.dart';
import '../../../../core/services/plan_tasks_sync_service.dart';
import '../../../../core/models/deletion_request_model.dart';
import '../../domain/entities/project_planning_input.dart';
import '../../domain/entities/project_plan.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/plan_repository.dart';
import '../../data/repositories/firestore_project_repository.dart';
import '../../data/repositories/firestore_plan_repository.dart';
import '../../data/services/ai_project_planning_service.dart';
import '../../../tasks/domain/repositories/deletion_request_repository.dart';
import '../../../tasks/data/services/accountability_service.dart';

class ProjectsController extends ChangeNotifier {
  final ProjectRepository _repository = FirestoreProjectRepository();
  final PlanRepository _planRepository = FirestorePlanRepository();
  final AIProjectPlanningService _aiService = AIProjectPlanningService();
  
  // Will be injected via setter or constructor
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

  List<ProjectModel> _projects = [];
  ProjectModel? _currentProject;
  ProjectPlan? _generatedPlan;
  PlanModel? _generatedDailyPlan;
  List<PlanModel> _plans = [];
  bool _loading = false;
  String? _error;

  List<ProjectModel> get projects => _projects;
  ProjectModel? get currentProject => _currentProject;
  ProjectPlan? get generatedPlan => _generatedPlan;
  PlanModel? get generatedDailyPlan => _generatedDailyPlan;
  List<PlanModel> get plans => _plans;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    if (_projects.isNotEmpty) return; // Already initialized
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _projects = await _repository.getUserProjects(user.uid);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading projects: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Generate a project plan using AI and save to plans collection
  Future<ProjectPlan> generatePlan(ProjectPlanningInput input) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Generate both ProjectPlan (for review screen) and PlanModel (for Firestore)
      _generatedPlan = await _aiService.generateProjectPlan(input);
      
      // Generate daily plan and save to Firestore plans collection
      _generatedDailyPlan = await _aiService.generateDailyPlan(input, user.uid);
      final savedPlan = await _planRepository.createPlan(_generatedDailyPlan!);
      _generatedDailyPlan = savedPlan;

      debugPrint('✅ AI plan generated and saved to plans collection: ${savedPlan.id}');
      
      return _generatedPlan!;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error generating plan: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load all plans for the current user
  Future<void> loadPlans() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _error = 'No authenticated user';
        return;
      }

      _plans = await _planRepository.getUserPlans(user.uid);
      debugPrint('✅ Loaded ${_plans.length} plans');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading plans: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Get daily plan for a specific date
  Future<DailyPlan?> getDailyPlanForDate(String planId, DateTime date) async {
    try {
      return await _planRepository.getDailyPlan(planId, date);
    } catch (e) {
      debugPrint('❌ Error getting daily plan: $e');
      return null;
    }
  }

  Future<ProjectModel> createProjectFromPlan(
    ProjectPlanningInput input,
    ProjectPlan plan,
  ) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Calculate date distribution
      final totalDays = input.totalDays;
      final phasesCount = plan.phases.length;
      final daysPerPhase = (totalDays / phasesCount).ceil();

      // Create project
      final project = ProjectModel(
        id: '',
        userId: user.uid,
        title: input.title,
        description: input.description,
        category: input.category,
        startDate: input.startDate,
        endDate: input.endDate,
        hoursPerDay: input.hoursPerDay,
        hoursPerWeek: input.hoursPerWeek,
        status: 'active',
      );

      final createdProject = await _repository.createProject(project);

      // Create milestones and tasks
      final milestones = <MilestoneModel>[];
      var currentDate = input.startDate;

      for (var i = 0; i < plan.phases.length; i++) {
        final phase = plan.phases[i];
        final phaseStartDate = currentDate;
        final phaseEndDate = i == plan.phases.length - 1
            ? input.endDate
            : currentDate.add(Duration(days: daysPerPhase - 1));

        // Distribute tasks across phase dates
        final tasks = <ProjectTaskModel>[];
        var taskDate = phaseStartDate;
        var dailyHoursUsed = 0.0;

        for (var task in phase.tasks) {
          if (dailyHoursUsed + task.estimatedHours > input.hoursPerDay) {
            // Move to next day
            taskDate = taskDate.add(const Duration(days: 1));
            dailyHoursUsed = 0.0;
          }

          if (taskDate.isAfter(phaseEndDate)) {
            taskDate = phaseEndDate; // Cap at phase end
          }

          tasks.add(ProjectTaskModel(
            id: '',
            milestoneId: '',
            title: task.title,
            description: task.description,
            estimatedHours: task.estimatedHours,
            dueDate: taskDate,
            status: 'pending',
          ));

          dailyHoursUsed += task.estimatedHours;
        }

        milestones.add(MilestoneModel(
          id: '',
          projectId: createdProject.id,
          title: phase.title,
          description: phase.description,
          order: phase.order,
          startDate: phaseStartDate,
          endDate: phaseEndDate,
          tasks: tasks,
        ));

        currentDate = phaseEndDate.add(const Duration(days: 1));
      }

      // Save milestones and tasks
      await _repository.createMilestones(createdProject.id, milestones);

      // Sync project tasks to daily tasks
      try {
        final syncService = PlanTasksSyncService();
        await syncService.syncProjectToTasks(createdProject.id);
      } catch (e) {
        debugPrint('Warning: Could not sync project to tasks: $e');
        // Don't fail the whole operation if sync fails
      }

      // Reload projects
      await refresh();

      return createdProject;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating project: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await initialize();
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      // Find the task
      for (var project in _projects) {
        for (var milestone in project.milestones) {
          final task = milestone.tasks.firstWhere(
            (t) => t.id == taskId,
            orElse: () => throw Exception('Task not found'),
          );

          final updatedTask = task.copyWith(
            status: status,
            completedAt: status == 'done' ? DateTime.now() : null,
          );

          await _repository.updateTask(updatedTask);
          await refresh();
          return;
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<List<ProjectTaskModel>> getTodaysTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    return await _repository.getTodaysTasks(user.uid);
  }

  void clearGeneratedPlan() {
    _generatedPlan = null;
    notifyListeners();
  }

  /// Sync plan daily tasks to user habits
  /// Note: TasksController needs to be reloaded separately via context after this call
  Future<void> syncPlanToTasks(String planId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final syncService = PlanTasksSyncService();
      await syncService.syncPlanToTasks(planId);

      debugPrint('✅ Synced plan $planId to tasks');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error syncing plan to tasks: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Delete a plan (called after approval)
  Future<void> deletePlan(String planId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _planRepository.deletePlan(planId);
      
      // Remove from local list
      _plans.removeWhere((plan) => plan.id == planId);

      debugPrint('✅ Deleted plan $planId');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting plan: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Elevated access deletion - bypasses accountability requirement (DEBUG MODE ONLY)
  /// This method directly deletes a plan without requiring approval
  /// Note: Tasks deletion is handled in the UI layer, this method only deletes the plan
  Future<void> deletePlanElevated(String planId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      // Delete the plan
      await _planRepository.deletePlan(planId);
      
      // Remove from local list
      _plans.removeWhere((plan) => plan.id == planId);

      debugPrint('✅ [ELEVATED ACCESS] Deleted plan $planId without accountability approval');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting plan with elevated access: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Create a plan deletion request (requires accountability partner approval)
  Future<DeletionRequestModel> createPlanDeletionRequest({
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

      // Create deletion request
      final request = await deletionRequestRepository.createPlanDeletionRequest(
        userId: user.uid,
        planId: planId,
        planTitle: planTitle,
        reason: reason,
        accountabilityPartnerContact: accountabilityPartnerContact,
        contactType: contactType,
      );

      // Update plan's deletionStatus to "pending"
      try {
        final plan = await _planRepository.getPlanById(planId);
        if (plan != null) {
          final updatedPlan = plan.copyWith(deletionStatus: "pending");
          await _planRepository.updatePlan(updatedPlan);
          
          // Update local list
          final index = _plans.indexWhere((p) => p.id == planId);
          if (index != -1) {
            _plans[index] = updatedPlan;
          }
        }
      } catch (e) {
        debugPrint('Error updating plan deletion status: $e');
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
      debugPrint('Error creating plan deletion request: $e');
      rethrow;
    }
  }

  /// Get pending deletion request for a plan
  Future<DeletionRequestModel?> getPendingDeletionRequestForPlan(String planId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      return await deletionRequestRepository.getPendingDeletionRequestForPlan(user.uid, planId);
    } catch (e) {
      debugPrint('Error getting pending deletion request for plan: $e');
      return null;
    }
  }
}

