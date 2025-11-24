import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recalim/core/models/workout_model.dart';
import 'package:recalim/core/models/deletion_request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../controllers/workouts_controller.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../../../tasks/data/repositories/firestore_tasks_repository.dart';

class WorkoutRoadmapScreen extends StatefulWidget {
  final String workoutPlanId;

  const WorkoutRoadmapScreen({
    super.key,
    required this.workoutPlanId,
  });

  @override
  State<WorkoutRoadmapScreen> createState() => _WorkoutRoadmapScreenState();
}

class _WorkoutRoadmapScreenState extends State<WorkoutRoadmapScreen> {
  WorkoutPlanModel? _workoutPlan;
  bool _isPlanSynced = false;
  bool _isCheckingSyncStatus = true;
  DeletionRequestModel? _pendingDeletionRequest;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlan();
    _checkIfPlanSynced();
    _loadPendingDeletionRequest();
  }
  
  /// Load pending deletion request for this workout plan
  Future<void> _loadPendingDeletionRequest() async {
    if (_workoutPlan == null) return;
    
    final controller = context.read<WorkoutsController>();
    try {
      final request = await controller.getPendingDeletionRequestForWorkoutPlan(_workoutPlan!.id);
      if (mounted) {
        setState(() {
          _pendingDeletionRequest = request;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending deletion request: $e');
    }
  }

  Future<void> _loadWorkoutPlan() async {
    final controller = context.read<WorkoutsController>();
    
    // Check if plan is already loaded
    try {
      final existingPlan = controller.workoutPlans.firstWhere((p) => p.id == widget.workoutPlanId);
      if (mounted) {
        setState(() {
          _workoutPlan = existingPlan;
        });
      }
      return;
    } catch (e) {
      // Plan not in loaded list, continue to load
    }
    
    // Load all plans and find it
    await controller.initialize();
    
    if (!mounted) return;
    
    setState(() {
      try {
        _workoutPlan = controller.workoutPlans.firstWhere((p) => p.id == widget.workoutPlanId);
      } catch (e) {
        debugPrint('Workout plan not found: ${widget.workoutPlanId}');
      }
    });
  }

  /// Check if this workout plan's tasks have already been synced to habits
  Future<void> _checkIfPlanSynced() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isCheckingSyncStatus = false;
        });
      }
      return;
    }

    try {
      final tasksRepository = FirestoreTasksRepository();
      final habits = await tasksRepository.getHabits(user.uid);
      
      // Check if any habit has metadata['type'] == 'workout' and metadata['planId'] == workoutPlanId
      final hasSyncedTasks = habits.any((habit) {
        final metadata = habit.metadata;
        final type = metadata['type'] as String?;
        final planId = metadata['planId'] as String?;
        return type == 'workout' && planId == widget.workoutPlanId;
      });

      if (mounted) {
        setState(() {
          _isPlanSynced = hasSyncedTasks;
          _isCheckingSyncStatus = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking if workout plan is synced: $e');
      if (mounted) {
        setState(() {
          _isCheckingSyncStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          'Workout Roadmap',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer<WorkoutsController>(
        builder: (context, controller, child) {
          if (_workoutPlan == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            );
          }

          return _buildWorkoutPlanContent(context, _workoutPlan!, controller);
        },
      ),
    );
  }

  Widget _buildWorkoutPlanContent(BuildContext context, WorkoutPlanModel workoutPlan, WorkoutsController controller) {
    String getGoalDisplayName(String goal) {
      switch (goal) {
        case 'fat_loss':
          return 'Lose Fat';
        case 'strength':
          return 'Get Stronger';
        case 'stamina':
          return 'Improve Stamina';
        case 'muscle_build':
          return 'Build Muscle';
        case 'general_health':
          return 'Stay Active';
        default:
          return goal;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Plan Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B35).withValues(alpha: 0.2),
                  const Color(0xFF1A1A1A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      color: Color(0xFFFF6B35),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        getGoalDisplayName(workoutPlan.goalType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      text: '${workoutPlan.startDate.year}-${workoutPlan.startDate.month.toString().padLeft(2, '0')}-${workoutPlan.startDate.day.toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      icon: Icons.event,
                      text: '${workoutPlan.workoutDays.length} sessions',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      icon: Icons.access_time,
                      text: '${workoutPlan.minutesPerSession}min',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        workoutPlan.fitnessLevel.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${workoutPlan.durationWeeks} WEEKS',
                        style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (workoutPlan.equipment.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workoutPlan.equipment.map((eq) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          eq.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sync to Tasks Button or Already Added Message
          if (_isCheckingSyncStatus)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
              ),
            )
          else if (_isPlanSynced)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Already added to plan',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton(
                onPressed: controller.loading
                    ? null
                    : () async {
                        final parentContext = context;
                        try {
                          await controller.syncWorkoutPlanToTasks(workoutPlan.id);
                          
                          // Update sync status
                          await _checkIfPlanSynced();
                          
                          // Reload habits in TasksController to show the newly synced tasks
                          if (parentContext.mounted) {
                            await parentContext.read<TasksController>().reloadHabits();
                          }
                          
                          if (!mounted || !parentContext.mounted) return;
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Workout sessions synced to your daily tasks!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted || !parentContext.mounted) return;
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error syncing tasks: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sync, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Add to My Tasks',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

          // Workout Sessions
          Text(
            'Workout Schedule',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...workoutPlan.workoutDays.map((workoutDay) => _buildWorkoutDayCard(workoutDay)),
          
          // Delete Workout Plan Button at the bottom or Pending Deletion Message
          const SizedBox(height: 32),
          if (_pendingDeletionRequest != null && _pendingDeletionRequest!.status == DeletionRequestStatus.pending)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_outlined, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Deletion Request Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: controller.loading
                        ? null
                        : () => _showDeleteWorkoutPlanDialog(context, controller, workoutPlan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 22),
                    label: const Text(
                      'Delete Workout Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Elevated Access Deletion Button (DEBUG MODE ONLY)
                if (kDebugMode)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: ElevatedButton.icon(
                      onPressed: controller.loading
                          ? null
                          : () => _handleElevatedWorkoutPlanDeletion(context, controller, workoutPlan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.admin_panel_settings, size: 22),
                      label: const Text(
                        'Elevated Access Deletion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDayCard(WorkoutDayModel workoutDay) {
    final isToday = _isToday(workoutDay.scheduledDate ?? DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday 
            ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday 
              ? const Color(0xFFFF6B35).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(workoutDay.scheduledDate ?? DateTime.now()),
                      style: TextStyle(
                        color: isToday ? const Color(0xFFFF6B35) : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workoutDay.dayLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (workoutDay.focus.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        workoutDay.focus,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (workoutDay.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (workoutDay.exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Exercises (${workoutDay.exercises.length})',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...workoutDay.exercises.take(3).map((exercise) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${exercise.name} • ${exercise.sets} sets × ${exercise.reps}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            if (workoutDay.exercises.length > 3)
              Text(
                '+ ${workoutDay.exercises.length - 3} more exercises',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else {
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
    }
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Show delete workout plan request dialog with accountability partner requirement
  Future<void> _showDeleteWorkoutPlanDialog(
    BuildContext context,
    WorkoutsController controller,
    WorkoutPlanModel workoutPlan,
  ) async {
    final parentContext = context;
    if (!parentContext.mounted) return;

    // Get last deletion reason
    final tasksController = context.read<TasksController>();
    final lastReason = await tasksController.getLastDeletionReason();
    final reasonController = TextEditingController(text: lastReason ?? '');
    final contactController = TextEditingController();
    String selectedContactType = 'email';

    if (!parentContext.mounted) return;

    showDialog(
      context: parentContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Request Workout Plan Deletion',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'To delete this workout plan, an accountability partner must approve your request. This will also remove all associated tasks from your habits.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Delete Workout Plan: "${getGoalDisplayName(workoutPlan.goalType)}"',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will permanently delete the workout plan and all its associated tasks from your habits.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Reason for deletion:',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (lastReason != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Last reason: "$lastReason"',
                            style: const TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for deletion...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Accountability Partner Contact:',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter phone number or email of someone who will approve/reject this deletion:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Email'),
                        selected: selectedContactType == 'email',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              selectedContactType = 'email';
                            });
                          }
                        },
                        selectedColor: Colors.orange.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          color: selectedContactType == 'email' ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Phone'),
                        selected: selectedContactType == 'phone',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              selectedContactType = 'phone';
                            });
                          }
                        },
                        selectedColor: Colors.orange.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          color: selectedContactType == 'phone' ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: selectedContactType == 'phone'
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: selectedContactType == 'phone'
                        ? 'Enter phone number'
                        : 'Enter email address',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                final contact = contactController.text.trim();

                if (reason.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a reason for deletion'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (contact.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please provide ${selectedContactType == 'phone' ? 'phone number' : 'email address'}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  setDialogState(() {});

                  String getGoalDisplayName(String goal) {
                    switch (goal) {
                      case 'fat_loss':
                        return 'Lose Fat';
                      case 'strength':
                        return 'Get Stronger';
                      case 'stamina':
                        return 'Improve Stamina';
                      case 'muscle_build':
                        return 'Build Muscle';
                      case 'general_health':
                        return 'Stay Active';
                      default:
                        return goal;
                    }
                  }

                  // Create deletion request
                  final request = await controller.createWorkoutPlanDeletionRequest(
                    planId: workoutPlan.id,
                    planTitle: getGoalDisplayName(workoutPlan.goalType),
                    reason: reason,
                    accountabilityPartnerContact: contact,
                    contactType: selectedContactType,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  // Reload workout plan data
                  await _loadWorkoutPlan();

                  // Update pending deletion request state immediately
                  if (mounted) {
                    setState(() {
                      _pendingDeletionRequest = request;
                    });
                  }

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Workout plan deletion request sent to ${selectedContactType == 'phone' ? 'SMS' : 'Email'}. Waiting for approval...'
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error creating workout plan deletion request: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Request Deletion', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle elevated access deletion for workout plan (DEBUG MODE ONLY)
  Future<void> _handleElevatedWorkoutPlanDeletion(
    BuildContext context,
    WorkoutsController controller,
    WorkoutPlanModel workoutPlan,
  ) async {
    final parentContext = context;
    if (!parentContext.mounted) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              'Elevated Access Deletion',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.purple, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DEBUG MODE: This will delete the workout plan and all its tasks immediately without accountability partner approval.',
                      style: TextStyle(color: Colors.purple, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Are you sure you want to delete this workout plan?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will permanently delete the workout plan and remove all its tasks from your habits.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !parentContext.mounted) return;

    try {
      // Delete all tasks associated with this workout plan first
      final tasksController = parentContext.read<TasksController>();
      final tasksRepository = FirestoreTasksRepository();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        final habits = await tasksRepository.getHabits(user.uid);
        
        // Find all habits that belong to this workout plan
        final workoutHabits = habits.where((habit) {
          final metadata = habit.metadata;
          final type = metadata['type'] as String?;
          final planId = metadata['planId'] as String?;
          return type == 'workout' && planId == workoutPlan.id;
        }).toList();

        // Delete each habit
        for (var habit in workoutHabits) {
          try {
            await tasksRepository.deleteHabit(habit.id, 'Workout plan deleted (elevated access)');
          } catch (e) {
            debugPrint('Error deleting habit ${habit.id}: $e');
          }
        }
        
        // Reload habits
        await tasksController.reloadHabits();
      }
      
      // Delete the workout plan using elevated access
      await controller.deleteWorkoutPlanElevated(workoutPlan.id);
      
      if (!parentContext.mounted) return;
      
      // Navigate back
      Navigator.pop(parentContext);
      
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text('✅ Workout plan deleted with elevated access.'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!parentContext.mounted) return;
      
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('❌ Error deleting workout plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String getGoalDisplayName(String goal) {
    switch (goal) {
      case 'fat_loss':
        return 'Lose Fat';
      case 'strength':
        return 'Get Stronger';
      case 'stamina':
        return 'Improve Stamina';
      case 'muscle_build':
        return 'Build Muscle';
      case 'general_health':
        return 'Stay Active';
      default:
        return goal;
    }
  }
}

