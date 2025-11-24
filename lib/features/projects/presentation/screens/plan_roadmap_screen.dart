import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recalim/core/models/plan_model.dart';
import 'package:recalim/core/models/deletion_request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/projects_controller.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../../../tasks/data/repositories/firestore_tasks_repository.dart';

class PlanRoadmapScreen extends StatefulWidget {
  final String planId;

  const PlanRoadmapScreen({
    super.key,
    required this.planId,
  });

  @override
  State<PlanRoadmapScreen> createState() => _PlanRoadmapScreenState();
}

class _PlanRoadmapScreenState extends State<PlanRoadmapScreen> {
  PlanModel? _plan;
  bool _isPlanSynced = false;
  bool _isCheckingSyncStatus = true;
  DeletionRequestModel? _pendingDeletionRequest;

  @override
  void initState() {
    super.initState();
    _loadPlan();
    _checkIfPlanSynced();
    _loadPendingDeletionRequest();
  }
  
  /// Load pending deletion request for this plan
  Future<void> _loadPendingDeletionRequest() async {
    if (_plan == null) return;
    
    final controller = context.read<ProjectsController>();
    try {
      final request = await controller.getPendingDeletionRequestForPlan(_plan!.id);
      if (mounted) {
        setState(() {
          _pendingDeletionRequest = request;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending deletion request: $e');
    }
  }

  Future<void> _loadPlan() async {
    // First try to get from controller's loaded plans
    final controller = context.read<ProjectsController>();
    
    // Check if plan is already loaded
    try {
      final existingPlan = controller.plans.firstWhere((p) => p.id == widget.planId);
      if (mounted) {
        setState(() {
          _plan = existingPlan;
        });
      }
      return;
    } catch (e) {
      // Plan not in loaded list, continue to load by ID
    }
    
    // Load plan directly by ID using the controller's repository access
    // We'll use the getDailyPlanForDate method pattern - actually, let's add a method to controller
    // For now, let's just load all plans and find it
    await controller.loadPlans();
    
    if (!mounted) return;
    
    setState(() {
      try {
        _plan = controller.plans.firstWhere((p) => p.id == widget.planId);
      } catch (e) {
        // Plan still not found - this shouldn't happen but handle gracefully
        debugPrint('Plan not found: ${widget.planId}');
      }
    });
  }

  /// Check if this plan's tasks have already been synced to habits
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
      
      // Check if any habit has metadata['type'] == 'plan' and metadata['planId'] == planId
      final hasSyncedTasks = habits.any((habit) {
        final metadata = habit.metadata;
        final type = metadata['type'] as String?;
        final planId = metadata['planId'] as String?;
        return type == 'plan' && planId == widget.planId;
      });

      if (mounted) {
        setState(() {
          _isPlanSynced = hasSyncedTasks;
          _isCheckingSyncStatus = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking if plan is synced: $e');
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
          'Project Roadmap',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProjectsController>(
        builder: (context, controller, child) {
          if (_plan == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          return _buildPlanContent(context, _plan!, controller);
        },
      ),
    );
  }

  Widget _buildPlanContent(BuildContext context, PlanModel plan, ProjectsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.2),
                  const Color(0xFF1A1A1A),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.projectTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (plan.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    plan.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      text: '${plan.startDate.year}-${plan.startDate.month.toString().padLeft(2, '0')}-${plan.startDate.day.toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      icon: Icons.event,
                      text: '${plan.dailyPlans.length} days',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      icon: Icons.access_time,
                      text: '${plan.hoursPerDay}h/day',
                    ),
                  ],
                ),
                if (plan.category.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      plan.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                child: CircularProgressIndicator(color: Colors.orange),
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
                          await controller.syncPlanToTasks(plan.id);
                          
                          // Update sync status
                          await _checkIfPlanSynced();
                          
                          // Reload habits in TasksController to show the newly synced tasks
                          if (parentContext.mounted) {
                            await parentContext.read<TasksController>().reloadHabits();
                          }
                          
                          if (!mounted || !parentContext.mounted) return;
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Plan tasks synced to your daily tasks!'),
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
                  backgroundColor: Colors.orange,
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

          // Daily Plans
          Text(
            'Daily Schedule',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...plan.dailyPlans.map((dailyPlan) => _buildDailyPlanCard(dailyPlan)),
          
          // Delete Plan Button at the bottom or Pending Deletion Message
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
                        : () => _showDeletePlanDialog(context, controller, plan),
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
                      'Delete Plan',
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
                          : () => _handleElevatedPlanDeletion(context, controller, plan),
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

  /// Show delete plan request dialog with accountability partner requirement
  Future<void> _showDeletePlanDialog(
    BuildContext context,
    ProjectsController controller,
    PlanModel plan,
  ) async {
    // Check if there's already a pending deletion request
    if (_pendingDeletionRequest != null && _pendingDeletionRequest!.status == DeletionRequestStatus.pending) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A deletion request is already pending for this plan.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Also check database in case state is stale
    final pendingRequest = await controller.getPendingDeletionRequestForPlan(plan.id);
    if (pendingRequest != null && pendingRequest.status == DeletionRequestStatus.pending) {
      if (!context.mounted) return;
      setState(() {
        _pendingDeletionRequest = pendingRequest;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A deletion request is already pending for this plan.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final reasonController = TextEditingController();
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
                'Request Plan Deletion',
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
                          'To delete this plan, an accountability partner must approve your request. This will delete the plan and all its associated tasks.',
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Delete Plan: "${plan.projectTitle}"',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will permanently delete the plan and remove all its tasks from your habits.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Reason for deletion:',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
                  final request = await controller.createPlanDeletionRequest(
                    planId: plan.id,
                    planTitle: plan.projectTitle,
                    reason: reason,
                    accountabilityPartnerContact: contact,
                    contactType: selectedContactType,
                  );
                  
                  if (!context.mounted) return;
                  Navigator.pop(context); // Close dialog
                  
                  // Update pending deletion request state immediately
                  if (mounted) {
                    setState(() {
                      _pendingDeletionRequest = request;
                    });
                  }
                  
                  // Reload plan to get updated deletionStatus
                  await _loadPlan();
                  await _loadPendingDeletionRequest();
                
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

  /// Handle elevated access deletion for plan (DEBUG MODE ONLY)
  Future<void> _handleElevatedPlanDeletion(
    BuildContext context,
    ProjectsController controller,
    PlanModel plan,
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
                      'DEBUG MODE: This will delete the plan and all its tasks immediately without accountability partner approval.',
                      style: TextStyle(color: Colors.purple, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Are you sure you want to delete "${plan.projectTitle}"?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will permanently delete the plan and remove all its tasks from your habits.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
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
      // Delete all tasks associated with this plan first
      final tasksController = parentContext.read<TasksController>();
      final tasksRepository = FirestoreTasksRepository();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        final habits = await tasksRepository.getHabits(user.uid);
        
        // Find all habits that belong to this plan
        final planHabits = habits.where((habit) {
          final metadata = habit.metadata;
          final type = metadata['type'] as String?;
          final planIdFromMeta = metadata['planId'] as String?;
          return type == 'plan' && planIdFromMeta == plan.id;
        }).toList();

        // Delete each habit
        for (var habit in planHabits) {
          try {
            await tasksRepository.deleteHabit(habit.id, 'Plan deleted (elevated access)');
          } catch (e) {
            debugPrint('Error deleting habit ${habit.id}: $e');
          }
        }
        
        // Reload habits
        await tasksController.reloadHabits();
      }
      
      // Delete the plan using elevated access
      await controller.deletePlanElevated(plan.id);
      
      if (!parentContext.mounted) return;
      
      // Navigate back
      Navigator.pop(parentContext);
      
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text('✅ Plan deleted with elevated access.'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!parentContext.mounted) return;
      
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('❌ Error deleting plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDailyPlanCard(DailyPlan dailyPlan) {
    final isToday = _isToday(dailyPlan.date);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday 
            ? Colors.orange.withValues(alpha: 0.1)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday 
              ? Colors.orange.withValues(alpha: 0.5)
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
                      _formatDate(dailyPlan.date),
                      style: TextStyle(
                        color: isToday ? Colors.orange : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDayName(dailyPlan.date),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${dailyPlan.totalHours.toStringAsFixed(1)}h',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (dailyPlan.notes != null && dailyPlan.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              dailyPlan.notes!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (dailyPlan.tasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...dailyPlan.tasks.map((task) => _buildTaskItem(task)),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskItem(DailyTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${task.estimatedHours.toStringAsFixed(1)}h',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
}

