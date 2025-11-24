import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/habit_model.dart';
import 'package:recalim/core/models/proof_submission_model.dart';
import 'package:recalim/core/models/deletion_request_model.dart';
import 'package:recalim/core/constants/proof_types.dart';
import '../../../../core/utils/attribute_utils.dart';
import '../controllers/tasks_controller.dart';
import '../../../progress/presentation/controllers/progress_controller.dart';
import '../../../achievements/presentation/controllers/achievements_controller.dart';
import 'interactive_workout_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _proofController = TextEditingController();
  HabitModel? _habit;
  bool _isLoading = false;
  bool _hasInitialized = false;
  Timer? _workoutTimer;
  int _workoutTimerSeconds = 0;
  bool _isWorkoutTimerRunning = false;
  bool _workoutTimerCompleted = false;
  DateTime? _viewDate; // The date being viewed (for checking if it's today)
  DeletionRequestModel? _pendingDeletionRequest; // Track pending deletion request
  String? _lastLoadedHabitId; // Track which habit ID we last loaded deletion request for

  bool get _isWorkoutTask => _habit?.metadata['type'] == 'workout';
  
  /// Check if the viewed date is today (only today allows completion)
  bool get _canCompleteTask {
    if (_viewDate == null) return true; // Default to allowing if no date specified
    final today = DateTime.now();
    return _viewDate!.year == today.year && 
           _viewDate!.month == today.month && 
           _viewDate!.day == today.day;
  }

  @override
  void initState() {
    super.initState();
    // Don't access context here - wait for didChangeDependencies
  }

  Widget _buildWorkoutSummary(Map<String, dynamic> metadata) {
    final dayLabel = metadata['dayLabel'] as String? ?? 'Workout';
    final focus = metadata['focus'] as String? ?? '';
    final exercisesRaw = metadata['exercises'] as List<dynamic>? ?? [];
    final exercises = exercisesRaw
        .whereType<Map<String, dynamic>>()
        .where((exercise) => (exercise['name'] ?? '').toString().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (focus.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            focus,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
        const SizedBox(height: 12),
        ...exercises.map((exercise) {
          final name = exercise['name'] as String? ?? '';
          final sets = exercise['sets']?.toString() ?? '-';
          final reps = exercise['reps'] as String? ?? '';
          final rest = exercise['restSeconds']?.toString() ?? '60';
          final instructions = exercise['instructions'] as String? ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sets: $sets   Reps: $reps   Rest: ${rest}s',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (instructions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    instructions,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWorkoutTimerSection({
    required TasksController controller,
    required Map<String, dynamic> metadata,
    required bool isCompleted,
    required bool isSkipped,
    required int minutes,
  }) {
    final dayLabel = metadata['dayLabel'] as String? ?? 'Workout';
    final timerDisplay = _isWorkoutTimerRunning
        ? _formatTimer(_workoutTimerSeconds)
        : '${minutes.toString()} min';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$dayLabel Workout Timer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isWorkoutTimerRunning)
            Text(
              'Timer: $timerDisplay',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              'Estimated duration: $timerDisplay',
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isWorkoutTimerRunning || isCompleted || isSkipped || _isLoading)
                  ? null
                  : () => _startWorkoutTimer(minutes, controller, metadata),
              icon: Icon(
                _isWorkoutTimerRunning ? Icons.pause_circle : Icons.play_arrow,
              ),
              label: Text(
                _isWorkoutTimerRunning ? 'Timer Running' : 'Start Workout Timer',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_workoutTimerCompleted && !isCompleted) ...[
            const SizedBox(height: 8),
            const Text(
              'Timer completed! Finalizing your workout...',
              style: TextStyle(color: Colors.greenAccent, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  void _startWorkoutTimer(int minutes, TasksController controller, Map<String, dynamic> metadata) {
    if (_isWorkoutTimerRunning || minutes <= 0) return;
    _workoutTimer?.cancel();
    setState(() {
      _workoutTimerSeconds = minutes * 60;
      _isWorkoutTimerRunning = true;
      _workoutTimerCompleted = false;
    });

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_workoutTimerSeconds <= 1) {
        timer.cancel();
        if (mounted) {
        setState(() {
          _workoutTimerSeconds = 0;
          _isWorkoutTimerRunning = false;
          _workoutTimerCompleted = true;
        });
        _handleWorkoutTimerCompleted(controller, metadata, minutes);
        }
      } else {
        if (mounted) {
        setState(() {
          _workoutTimerSeconds--;
        });
        }
      }
    });
  }

  Future<void> _handleWorkoutTimerCompleted(
    TasksController controller,
    Map<String, dynamic> metadata,
    int minutes,
  ) async {
    if (_habit == null) return;
    final dayLabel = metadata['dayLabel'] as String? ?? 'Workout';
    final timestamp = DateFormat.jm().format(DateTime.now());
    final proof =
        'Completed $dayLabel workout for $minutes min using guided timer at $timestamp.';

    setState(() {
      _isLoading = true;
    });

    try {
      await controller.submitProof(_habit!, proof);
      await controller.completeHabit(_habit!, proof: proof);
      await _loadHabitData();

      if (!mounted) return;

      // Save references before navigating
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Workout completed! Great job 💪"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Save reference before showing snackbar
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _workoutTimerCompleted = false;
        });
      }
    }
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Handle workout completion from interactive workout screen
  /// The interactive workout itself serves as proof, so no additional proof input is needed
  Future<void> _handleWorkoutCompletion(
    TasksController controller,
    Map<String, dynamic> metadata,
  ) async {
    if (_habit == null) return;
    
    final dayLabel = metadata['dayLabel'] as String? ?? 'Workout';
    final timestamp = DateFormat.jm().format(DateTime.now());
    final exercisesCount = (metadata['exercises'] as List<dynamic>? ?? []).length;
    final proof =
        'Completed $dayLabel interactive workout with $exercisesCount exercises at $timestamp.';

    setState(() {
      _isLoading = true;
    });

    try {
      // Submit proof and complete the habit - the interactive workout is the proof
      await controller.submitProof(_habit!, proof);
      await controller.completeHabit(_habit!, proof: proof);
      
      // Reload habit data to get updated completion status
      await _loadHabitData();
      
      // Check for achievements
      if (mounted) {
        final achievementsController = context.read<AchievementsController>();
        final freshHabit = await controller.getHabitById(_habit!.id);
        await achievementsController.checkAchievementsOnTaskCompletion(freshHabit);
      }
      
      // Refresh progress controller to update stats
      if (mounted) {
        final tasksController = context.read<TasksController>();
        await context.read<ProgressController>().refresh(currentTasks: tasksController.habits);
      }
      
      if (!mounted) return;
      
      // Navigate back to tasks screen so user sees the task moved to "Done"
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Workout completed successfully! ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize after widget tree is built (only once)
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Get habit and viewDate from route arguments
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null) {
        if (arguments is HabitModel) {
          // Old format: just HabitModel (backward compatibility)
        _habit = arguments;
          _viewDate = DateTime.now(); // Default to today
        } else if (arguments is Map) {
          // New format: Map with habit and viewDate
          _habit = arguments['habit'] as HabitModel?;
          _viewDate = arguments['viewDate'] as DateTime?;
          if (_viewDate == null) {
            _viewDate = DateTime.now(); // Default to today if not specified
          }
        }
        // Load fresh data from database
        if (_habit != null) {
        _loadHabitData();
          // Check for approved deletions and load pending request
          _checkForApprovedDeletions();
        }
      }
    } else {
      // If already initialized, force reload pending deletion request when returning to screen
      if (_habit != null && mounted) {
        _forceReloadPendingDeletionRequest();
      }
    }
  }

  /// Check for approved deletion requests and process them
  Future<void> _checkForApprovedDeletions() async {
    if (_habit == null) return;
    
    final controller = context.read<TasksController>();
    try {
      await controller.processApprovedDeletions();
      
      // Check if habit still exists (might have been deleted)
      try {
        final updatedHabit = await controller.getHabitById(_habit!.id);
        if (mounted) {
          setState(() {
            _habit = updatedHabit;
          });
        }
      } catch (e) {
        // Habit was deleted, navigate back
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }
      
      // Load pending deletion request status
      await _loadPendingDeletionRequest();
    } catch (e) {
      debugPrint('Error checking approved deletions: $e');
    }
  }

  /// Load pending deletion request for current habit
  Future<void> _loadPendingDeletionRequest({bool force = false}) async {
    if (_habit == null) return;
    
    // Only skip reload if:
    // 1. Not forced
    // 2. Same habit ID
    // 3. We already have a pending request loaded
    if (!force && 
        _lastLoadedHabitId == _habit!.id && 
        _pendingDeletionRequest != null && 
        _pendingDeletionRequest!.status == DeletionRequestStatus.pending) {
      // Already have a pending request for this habit, skip reload
      return;
    }
    
    final controller = context.read<TasksController>();
    try {
      final request = await controller.getPendingDeletionRequestForHabit(_habit!.id);
      if (mounted) {
        setState(() {
          _pendingDeletionRequest = request;
          _lastLoadedHabitId = _habit!.id;
        });
        if (request != null) {
          debugPrint('📋 Loaded pending deletion request: ${request.id} (status: ${request.status.value}) for habit ${_habit!.id}');
        } else {
          debugPrint('📋 No pending deletion request found for habit ${_habit!.id}');
        }
      }
    } catch (e) {
      debugPrint('Error loading pending deletion request: $e');
    }
  }
  
  /// Force reload pending deletion request (used when returning to screen)
  Future<void> _forceReloadPendingDeletionRequest() async {
    if (_habit == null) return;
    
    final controller = context.read<TasksController>();
    try {
      final request = await controller.getPendingDeletionRequestForHabit(_habit!.id);
      if (mounted) {
        setState(() {
          _pendingDeletionRequest = request;
          _lastLoadedHabitId = _habit!.id;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending deletion request: $e');
    }
  }

  Future<void> _loadHabitData() async {
    if (!mounted || _habit == null) return;
    
    final controller = context.read<TasksController>();
    try {
      final updatedHabit = await controller.getHabitById(_habit!.id);
      if (mounted) {
        setState(() {
          _habit = updatedHabit;
          // If habit has deletionStatus "pending", immediately mark that we need to load the request
          // This prevents the UI from showing "Delete Task" when it should show "Deletion Request Pending"
          if (updatedHabit.deletionStatus == "pending" && _pendingDeletionRequest == null) {
            // Set a placeholder so the UI knows it's pending
            // We'll load the actual request details in the background
          }
        });
        // Always reload pending deletion request when loading habit data
        await _loadPendingDeletionRequest();
      }
    } catch (e) {
      debugPrint('Error loading habit: $e');
    }
  }

  /// Show delete confirmation dialog with accountability partner requirement
  Future<void> _showDeleteDialog(BuildContext context, TasksController controller) async {
    // Safety check: Don't allow deletion of completed tasks
    // Note: Deletion removes the task from user's habits only, not from preset tasks collection
    final viewDateForDelete = _viewDate ?? DateTime.now();
    if (_habit == null || _habit!.isCompletedForDate(viewDateForDelete)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only incomplete tasks can be deleted.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check if there's already a pending deletion request
    // First check local state, then check database
    if (_pendingDeletionRequest != null && _pendingDeletionRequest!.status == DeletionRequestStatus.pending) {
      if (!context.mounted) return;
      _showPendingDeletionDialog(context, controller, _pendingDeletionRequest!);
      return;
    }
    
    // Also check database in case state is stale
    final pendingRequest = await controller.getPendingDeletionRequestForHabit(_habit!.id);
    if (pendingRequest != null && pendingRequest.status == DeletionRequestStatus.pending) {
      if (!context.mounted) return;
      // Update local state
      setState(() {
        _pendingDeletionRequest = pendingRequest;
        _lastLoadedHabitId = _habit!.id;
      });
      _showPendingDeletionDialog(context, controller, pendingRequest);
      return;
    }

    // Get last deletion reason
    final lastReason = await controller.getLastDeletionReason();
    final reasonController = TextEditingController(text: lastReason ?? '');
    final contactController = TextEditingController();
    String selectedContactType = 'email'; // 'phone' or 'email'

    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Request Task Deletion',
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
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'To remove this task from your habits, an accountability partner must approve your request. This will not delete the task from the preset tasks library.',
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                  'Remove Task: "${_habit?.title}"',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will remove the task from your habits list only. The task will remain in the preset tasks library.',
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
                // Contact type selector
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
                  
                  // Create deletion request
                  final request = await controller.createDeletionRequest(
                    habitId: _habit!.id,
                    habitTitle: _habit!.title,
                    reason: reason,
                    accountabilityPartnerContact: contact,
                    contactType: selectedContactType,
                  );
                  
                if (!context.mounted) return;
                Navigator.pop(context); // Close dialog
                  
                  // Reload habit data to get updated deletionStatus
                  await _loadHabitData();
                  
                  // Update pending deletion request state immediately
                  if (mounted) {
                    setState(() {
                      _pendingDeletionRequest = request;
                      _lastLoadedHabitId = _habit!.id;
                    });
                    debugPrint('✅ Deletion request created and state updated: ${request.id}');
                  }
                  
                  // Force reload to ensure we have the latest status
                  await _forceReloadPendingDeletionRequest();
                
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                        'Deletion request sent to ${selectedContactType == 'phone' ? 'SMS' : 'Email'}. Waiting for approval...'
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 4),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error creating deletion request: $e'),
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

  /// Show dialog for pending deletion request
  void _showPendingDeletionDialog(BuildContext context, TasksController controller, DeletionRequestModel request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.pending_actions, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Deletion Request Pending',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task: "${request.habitTitle}"',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Reason: ${request.reason}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Sent to: ${request.accountabilityPartnerContact} (${request.contactType})',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Waiting for accountability partner to approve or reject. They will receive a message to reply with Y/YES or N/NO.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _proofController.dispose();
    _workoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if habit is not yet loaded
    if (_habit == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0F),
        appBar: AppBar(
          title: const Text(
            "Task Details",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    final controller = context.read<TasksController>();
    // Use _viewDate to check completion status for the specific date being viewed
    final viewDate = _viewDate ?? DateTime.now();
    final isCompleted = _habit!.isCompletedForDate(viewDate);
    final isSkipped = _habit!.isSkippedForDate(viewDate);
    final proofRequired = controller.isProofRequired(_habit!);
    final dateProof = _habit!.getProofForDate(viewDate);
    // Check if this is a plan task or workout task (cannot be deleted or skipped)
    final isPlanTask = _habit!.metadata['type'] == 'plan';
    final isWorkoutTask = _isWorkoutTask;
    final isPlanOrWorkoutTask = isPlanTask || isWorkoutTask;
    final canSkip = _habit!.isSystemAssigned && !isCompleted && !isSkipped && _canCompleteTask && !isPlanOrWorkoutTask;
    final metadata = _habit!.metadata;
    final workoutMinutes = isWorkoutTask
        ? (metadata['minutesPerSession'] as int? ?? 30)
        : 0;
    final hasProof = dateProof != null && dateProof.isNotEmpty;
    final disableCompletionButton = isWorkoutTask && !isCompleted && !hasProof;
    
    // Check deletion status immediately (no async needed - it's in the habit data)
    final hasPendingDeletion = _habit!.deletionStatus == "pending" || 
        (_pendingDeletionRequest != null && _pendingDeletionRequest!.status == DeletionRequestStatus.pending);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: Text(
          _habit!.title,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Details Card
            Builder(
              builder: (context) {
                // Get attribute for color coding
                final attribute = _habit!.attribute ?? AttributeUtils.determineAttribute(
                  title: _habit!.title,
                  description: _habit!.description,
                  category: '',
                );
                final attributeColor = AttributeUtils.getAttributeColor(attribute);
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        attributeColor.withValues(alpha: 0.2),
                        const Color(0xFF1A1A1A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: attributeColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Attribute indicator
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: attributeColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            attribute,
                            style: TextStyle(
                              color: attributeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _habit!.description,
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                  const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            "Scheduled: ${_habit!.scheduledTime}",
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isWorkoutTask)
                        _buildWorkoutSummary(metadata)
                      else if (proofRequired)
                        Row(
                          children: const [
                            Icon(Icons.verified_user, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              "Proof required for this task",
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),

            // Pending deletion request message - show below task details card (clickable to view details)
            if (hasPendingDeletion) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  // Load deletion request details if not already loaded
                  var requestToShow = _pendingDeletionRequest;
                  if (requestToShow == null) {
                    requestToShow = await controller.getPendingDeletionRequestForHabit(_habit!.id);
                    if (requestToShow != null && mounted) {
                      setState(() {
                        _pendingDeletionRequest = requestToShow;
                      });
                    }
                  }
                  if (requestToShow != null && mounted) {
                    _showPendingDeletionDialog(context, controller, requestToShow);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pendingDeletionRequest != null
                              ? 'Waiting for ${_pendingDeletionRequest!.accountabilityPartnerContact} to approve your deletion request. Tap to view details.'
                              : 'Deletion request pending. Waiting for accountability partner approval. Tap to view details.',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.orange, size: 20),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Completion Status - Hide if deletion is pending or if it's a plan/workout task (they don't show "Task Pending")
            if (!hasPendingDeletion && !isPlanOrWorkoutTask)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSkipped 
                    ? Colors.orange.withValues(alpha: 0.1)
                    : isCompleted 
                        ? Colors.green.withValues(alpha: 0.1) 
                        : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSkipped
                      ? Colors.orange
                      : isCompleted 
                          ? Colors.green 
                          : Colors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSkipped
                            ? Icons.skip_next
                            : isCompleted 
                                ? Icons.check_circle 
                                : Icons.radio_button_unchecked,
                        color: isSkipped
                            ? Colors.orange
                            : isCompleted 
                                ? Colors.green 
                                : Colors.white54,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isSkipped
                            ? "Task Skipped"
                            : isCompleted 
                                ? "Task Completed" 
                                : "Task Pending",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isSkipped
                              ? Colors.orange
                              : isCompleted 
                                  ? Colors.green 
                                  : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Only show undo button if completed for the viewed date AND the viewed date is today
                  if (isCompleted && _canCompleteTask)
                    TextButton.icon(
                      onPressed: _isLoading ? null : () => _handleUndoCompletion(controller),
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text("Undo"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),

            // Workout timer section removed - using interactive workout instead

            // Proof Section - Only show if proof is already submitted (hidden if deletion is pending)
            if (proofRequired && dateProof != null && dateProof.isNotEmpty && !hasPendingDeletion) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Proof Submitted",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dateProof,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (isCompleted && _canCompleteTask) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _isLoading ? null : () => _showEditProofDialog(controller),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Edit Proof"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Skip Button (only for system-assigned tasks, hidden if deletion is pending)
            if (canSkip && !hasPendingDeletion) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _handleSkipTask(controller),
                  icon: const Icon(Icons.skip_next, color: Colors.orange),
                  label: const Text(
                    "Skip Task",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This task will be marked as skipped for today",
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Interactive Workout Button (for workout tasks)
            if (isWorkoutTask && !isCompleted && !isSkipped && _canCompleteTask && !hasPendingDeletion) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InteractiveWorkoutScreen(habit: _habit!),
                            ),
                          );

                          if (result == true && mounted) {
                            // Workout completed - mark task as complete with proof
                            await _handleWorkoutCompletion(controller, metadata);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.fitness_center, color: Colors.white, size: 24),
                  label: const Text(
                    'Start Interactive Workout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Complete/Incomplete Button (hidden if deletion is pending, or for workout tasks use interactive workout instead)
            if (!hasPendingDeletion && !(isWorkoutTask && !isCompleted && _canCompleteTask))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: _isLoading || isSkipped || disableCompletionButton || !_canCompleteTask
                    ? null
                    : () => _handleToggleCompletion(controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.orange : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        !_canCompleteTask
                            ? "View Only"
                            : isSkipped 
                            ? "Task Skipped" 
                            : isCompleted 
                                ? "Mark as Incomplete" 
                                : "Mark as Complete",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            if (disableCompletionButton) ...[
              const SizedBox(height: 8),
              const Text(
                "Start and finish the workout timer to complete this session.",
                style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
              ),
            ],
            if (!_canCompleteTask && !hasPendingDeletion) ...[
              const SizedBox(height: 8),
              const Text(
                "You can only complete tasks for today. This is a view-only mode for other dates.",
                style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Delete Button - Show for all tasks (preset or user-added), but only for incomplete tasks
            // When deleted, it only removes from user's habits, not from preset tasks collection
            if (_habit != null && !_habit!.isCompletedForDate(viewDate)) ...[
              // Hide delete button for plan tasks and workout tasks (they can only be deleted by deleting the plan/workout)
              if (!isPlanOrWorkoutTask) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            // Check habit's deletionStatus first (immediate, no async)
                            if (hasPendingDeletion) {
                              var requestToShow = _pendingDeletionRequest;
                              if (requestToShow == null) {
                                requestToShow = await controller.getPendingDeletionRequestForHabit(_habit!.id);
                              }
                              if (requestToShow != null && mounted) {
                                _showPendingDeletionDialog(context, controller, requestToShow);
                              }
                            } else {
                              _showDeleteDialog(context, controller);
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: hasPendingDeletion
                          ? Colors.orange
                          : Colors.redAccent,
                      side: BorderSide(
                        color: hasPendingDeletion
                            ? Colors.orange
                            : Colors.redAccent,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      _pendingDeletionRequest != null && _pendingDeletionRequest!.status == DeletionRequestStatus.pending
                          ? Icons.pending_actions
                          : Icons.delete_outline,
                      size: 22,
                    ),
                    label: Text(
                      hasPendingDeletion
                          ? "Deletion Request Pending"
                          : "Delete Task",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              // Elevated Access Deletion Button (DEBUG MODE ONLY)
              if (kDebugMode && !isPlanOrWorkoutTask) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _handleElevatedDeletion(context, controller),
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
            ],
            // Show message for plan tasks and workout tasks explaining they cannot be deleted
            if (_habit != null && !_habit!.isCompletedForDate(viewDate) && isPlanOrWorkoutTask) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPlanTask
                            ? 'This task is part of a project plan. To remove it, delete the project plan from the roadmap.'
                            : 'This task is part of a workout plan. To remove it, delete the workout plan from the roadmap.',
                        style: TextStyle(
                          color: Colors.blue.shade200,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Handle elevated access deletion (DEBUG MODE ONLY)
  Future<void> _handleElevatedDeletion(BuildContext context, TasksController controller) async {
    if (_habit == null) return;
    
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
                      'DEBUG MODE: This will delete the task immediately without accountability partner approval.',
                      style: TextStyle(color: Colors.purple, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Are you sure you want to delete "${_habit?.title}"?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will permanently remove the task from your habits.',
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
      setState(() {
        _isLoading = true;
      });

      // Use elevated access deletion (bypasses accountability)
      await controller.deleteHabitElevated(_habit!.id, 'Elevated access deletion (debug mode)');
      
      if (!mounted || !parentContext.mounted) return;
      
      // Navigate back
      Navigator.pop(parentContext);
      
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text('✅ Task deleted with elevated access.'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted || !parentContext.mounted) return;
      
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('❌ Error deleting task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSkipTask(TasksController controller) async {
    if (_isLoading || _habit == null) return;

    // Check if skipping is allowed (only for today)
    if (!_canCompleteTask) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only skip tasks for today.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              "Skip Task?",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to skip this task?\n\nThe task will be marked as skipped for today.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Skip'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await controller.skipHabit(_habit!);
      await _loadHabitData();
      
      // Refresh progress controller to update stats immediately (using current tasks)
      if (mounted) {
        final tasksController = context.read<TasksController>();
        await context.read<ProgressController>().refresh(currentTasks: tasksController.habits);
      }
      
      if (!mounted) return;
      
      Navigator.pop(context);
      
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Task skipped for today",
              ),
              backgroundColor: Colors.orange,
            ),
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleToggleCompletion(TasksController controller) async {
    if (_isLoading || _habit == null) return;

    // Check if completion is allowed (only for today)
    if (!_canCompleteTask) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only complete tasks for today.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Use viewed date to check completion status
    final viewDate = _viewDate ?? DateTime.now();
    
    // Only allow completion/undo for today
    if (!_canCompleteTask) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only complete or undo tasks for today.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // If completing and proof is required, show proof dialog first
    if (!_habit!.isCompletedForDate(viewDate)) {
      final proofRequired = controller.isProofRequired(_habit!);
      final existingProof = _habit!.getProofForDate(viewDate);
      
        if (proofRequired && existingProof == null) {
          // Show proof input dialog
          await _showProofDialog(controller);
          return;
        }
      }

      setState(() => _isLoading = true);

      try {
        if (_habit!.isCompletedForDate(viewDate)) {
          // Undo completion
          await controller.undoCompleteHabit(_habit!);
          await _loadHabitData();
          
          // Refresh progress controller to update stats immediately (using current tasks)
          if (mounted) {
            final tasksController = context.read<TasksController>();
            await context.read<ProgressController>().refresh(currentTasks: tasksController.habits);
          }
          
          if (!mounted) return;
          
          // Navigate back to tasks screen so user sees the task moved to "To-dos"
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Task marked as incomplete"),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          // Complete task - proof should already be submitted if required
          final existingProof = _habit!.getProofForDate(viewDate);
          if (existingProof != null && existingProof.isNotEmpty) {
            // Proof already submitted, just complete
            await controller.completeHabit(_habit!, proof: existingProof);
          } else {
            // No proof needed or already handled
            await controller.completeHabit(_habit!);
          }
          
          // Reload habit data to get updated completion status
          await _loadHabitData();
          
          // Check for achievements (use fresh habit data from database)
          if (mounted) {
            final achievementsController = context.read<AchievementsController>();
            final freshHabit = await controller.getHabitById(_habit!.id);
            await achievementsController.checkAchievementsOnTaskCompletion(freshHabit);
          }
          
          // Refresh progress controller to update stats immediately (using current tasks)
          if (mounted) {
            final tasksController = context.read<TasksController>();
            await context.read<ProgressController>().refresh(currentTasks: tasksController.habits);
          }
          
          if (!mounted) return;
          
          // Navigate back to tasks screen so user sees the task moved to "Done"
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Task completed successfully! ✅"),
              backgroundColor: Colors.green,
            ),
          );
          _proofController.clear();
        }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show proof input dialog when marking task as complete
  Future<void> _showProofDialog(TasksController controller) async {
    if (!mounted || _habit == null) return;

    // Capture parent widget context and services before showing dialog
    final parentContext = context;
    
    await showDialog(
      context: parentContext,
      builder: (dialogContext) => _ProofInputDialog(
        habit: _habit!,
        controller: controller,
        onComplete: () async {
                // Close dialog using dialog's context
                Navigator.pop(dialogContext);
                
                // Check mounted before any async operations
                if (!mounted) return;
                
                await _loadHabitData();
                
                // Check for achievements - use parent context (only if widget is still mounted)
                if (mounted) {
                  try {
                    final achievementsController = parentContext.read<AchievementsController>();
                    if (_habit != null) {
                  await achievementsController.checkAchievementsOnTaskCompletion(_habit!);
                }
                  } catch (e) {
                    debugPrint('Error checking achievements: $e');
                  }
                }
                
          // Refresh progress controller - use parent context (only if widget is still mounted)
          if (mounted) {
                  try {
                    final tasksController = parentContext.read<TasksController>();
                    await parentContext.read<ProgressController>().refresh(currentTasks: tasksController.habits);
                  } catch (e) {
                    debugPrint('Error refreshing progress: $e');
                  }
                }
                
          // Navigate back to tasks screen and show snackbar - use parent context (only if widget is still mounted)
          if (mounted) {
                Navigator.pop(parentContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text("Task completed with proof! ✅"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
      ),
    );
  }

  Future<void> _handleSubmitProof(TasksController controller) async {
    if (_proofController.text.trim().isEmpty || _habit == null) {
      if (_proofController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please write something first."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if proof submission is allowed (only for today)
    if (!_canCompleteTask) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only submit proof for today.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await controller.submitProof(_habit!, _proofController.text.trim());
      await _loadHabitData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Proof submitted successfully ✅"),
          backgroundColor: Colors.green,
        ),
      );
      _proofController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUndoCompletion(TasksController controller) async {
    if (_habit == null) return;
    
    setState(() => _isLoading = true);

    try {
      await controller.undoCompleteHabit(_habit!);
      await _loadHabitData();
      
      // Refresh progress controller to update stats immediately (using current tasks)
      if (mounted) {
        final tasksController = context.read<TasksController>();
        await context.read<ProgressController>().refresh(currentTasks: tasksController.habits);
      }
      
      if (!mounted) return;
      
      // Navigate back to tasks screen so user sees the task moved to "To-dos"
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Task completion undone"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditProofDialog(TasksController controller) {
    if (_habit == null) return;
    final viewDate = _viewDate ?? DateTime.now();
    _proofController.text = _habit!.getProofForDate(viewDate) ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Edit Proof',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _proofController,
          style: const TextStyle(color: Colors.white),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter proof...',
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleSubmitProof(controller);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

/// Dialog widget for proof input supporting different proof types
class _ProofInputDialog extends StatefulWidget {
  final HabitModel habit;
  final TasksController controller;
  final VoidCallback onComplete;

  const _ProofInputDialog({
    required this.habit,
    required this.controller,
    required this.onComplete,
  });

  @override
  State<_ProofInputDialog> createState() => _ProofInputDialogState();
}

class _ProofInputDialogState extends State<_ProofInputDialog> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedProofType;
  String? _selectedFile;
  String? _mediaUrl;
  String? _locationLat;
  String? _locationLng;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedProofType = widget.habit.proofType ?? ProofTypes.text;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final proofType = _selectedProofType ?? ProofTypes.text;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate proof based on type
    switch (proofType) {
      case ProofTypes.text:
        if (_textController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please provide text proof'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        break;
      case ProofTypes.photo:
      case ProofTypes.video:
      case ProofTypes.file:
        if (_mediaUrl == null || _mediaUrl!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload a file'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        break;
      case ProofTypes.location:
        if (_locationLat == null || _locationLng == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please capture location'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        break;
    }

    setState(() => _isUploading = true);

    try {
      final proof = ProofSubmission(
        id: '',
        habitId: widget.habit.id,
        userId: user.uid,
        proofType: proofType,
        textContent: proofType == ProofTypes.text ? _textController.text.trim() : null,
        mediaUrl: _mediaUrl,
        locationLat: _locationLat,
        locationLng: _locationLng,
        fileName: _selectedFile,
        dateKey: HabitModel.getTodayDateString(),
      );

      await widget.controller.submitProofWithType(widget.habit, proof);
      
      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proofType = _selectedProofType ?? ProofTypes.text;
    final canChangeType = widget.habit.proofType == ProofTypes.any || widget.habit.proofType == null;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.green, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Proof Required',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ProofTypes.getHintText(proofType),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Proof type selector (only if "any" type)
            if (canChangeType) ...[
              DropdownButton<String>(
                value: proofType,
                isExpanded: true,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                items: ProofTypes.all.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(ProofTypes.getDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProofType = value;
                    _mediaUrl = null;
                    _locationLat = null;
                    _locationLng = null;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Proof input based on type
            _buildProofInput(proofType),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Complete Task', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildProofInput(String proofType) {
    switch (proofType) {
      case ProofTypes.text:
        return TextField(
          controller: _textController,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: ProofTypes.getHintText(proofType),
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
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
          ),
        );
      
      case ProofTypes.photo:
        return _buildMediaUpload(
          'Photo',
          Icons.photo,
          () {
            // TODO: Implement image picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image picker coming soon. Please use text proof for now.'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        );
      
      case ProofTypes.video:
        return _buildMediaUpload(
          'Video',
          Icons.videocam,
          () {
            // TODO: Implement video picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video picker coming soon. Please use text proof for now.'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        );
      
      case ProofTypes.location:
        return _buildLocationCapture();
      
      case ProofTypes.file:
        return _buildMediaUpload(
          'File',
          Icons.attach_file,
          () {
            // TODO: Implement file picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File picker coming soon. Please use text proof for now.'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        );
      
      default:
        return TextField(
          controller: _textController,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter proof...',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
        );
    }
  }

  Widget _buildMediaUpload(String label, IconData icon, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 48),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          if (_mediaUrl != null) ...[
            const SizedBox(height: 8),
            const Text(
              'File uploaded',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.upload),
            label: Text('Upload $label'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCapture() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_on, color: Colors.green, size: 48),
          const SizedBox(height: 8),
          const Text(
            'Location',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          if (_locationLat != null && _locationLng != null) ...[
            const SizedBox(height: 8),
            Text(
              'Lat: $_locationLat, Lng: $_locationLng',
              style: const TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement location capture using geolocator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location capture coming soon. Please use text proof for now.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Capture Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
