import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/habit_model.dart';
import '../controllers/tasks_controller.dart';

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

  @override
  void initState() {
    super.initState();
    // Don't access context here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize after widget tree is built
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Get habit from route arguments
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is HabitModel) {
        _habit = arguments;
        // Load fresh data from database
        _loadHabitData();
      }
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
        });
      }
    } catch (e) {
      debugPrint('Error loading habit: $e');
    }
  }

  /// Show delete confirmation dialog with reason input
  Future<void> _showDeleteDialog(BuildContext context, TasksController controller) async {
    // Safety check: Don't allow deletion of preset tasks or completed tasks
    if (_habit == null || _habit!.isPreset || _habit!.isCompletedToday()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only incomplete, user-added tasks can be deleted.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Get last deletion reason
    final lastReason = await controller.getLastDeletionReason();
    final reasonController = TextEditingController(text: lastReason ?? '');

    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Task',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${_habit?.title}"?',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                'Please provide a reason for deletion:',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (lastReason != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Last reason: "$lastReason"',
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
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

              try {
                await controller.deleteHabit(_habit!.id, reason);
                if (!context.mounted) return;
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to tasks screen
                
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task "${_habit!.title}" deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting task: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _proofController.dispose();
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
    final isCompleted = _habit!.isCompletedToday();
    final proofRequired = controller.isProofRequired(_habit!);
    final todayProof = _habit!.getTodayProof();

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
        actions: [
          // Only show delete button if task is not a preset task AND not completed (in To-dos)
          if (_habit != null && !_habit!.isPreset && !_habit!.isCompletedToday())
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _showDeleteDialog(context, controller),
              tooltip: 'Delete Task',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
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
                  if (proofRequired)
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
            ),

            const SizedBox(height: 30),

            // Completion Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.withValues(alpha: 0.1) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isCompleted ? Colors.green : Colors.white54,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isCompleted ? "Task Completed" : "Task Pending",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.green : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (isCompleted)
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

            // Proof Section - Only show if proof is already submitted
            if (proofRequired && todayProof != null && todayProof.isNotEmpty) ...[
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
                      todayProof,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (isCompleted) ...[
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

            // Complete/Incomplete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _handleToggleCompletion(controller),
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
                        isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggleCompletion(TasksController controller) async {
    if (_isLoading || _habit == null) return;

    // If completing and proof is required, show proof dialog first
    if (!_habit!.isCompletedToday()) {
      final proofRequired = controller.isProofRequired(_habit!);
      final existingProof = _habit!.getTodayProof();
      
        if (proofRequired && existingProof == null) {
          // Show proof input dialog
          await _showProofDialog(controller);
          return;
        }
      }

      setState(() => _isLoading = true);

      try {
        if (_habit!.isCompletedToday()) {
          // Undo completion
          await controller.undoCompleteHabit(_habit!);
          await _loadHabitData();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Task marked as incomplete"),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          // Complete task - proof should already be submitted if required
          final existingProof = _habit!.getTodayProof();
          if (existingProof != null && existingProof.isNotEmpty) {
            // Proof already submitted, just complete
            await controller.completeHabit(_habit!, proof: existingProof);
          } else {
            // No proof needed or already handled
            await controller.completeHabit(_habit!);
          }
          
          // Reload habit data to get updated completion status
          await _loadHabitData();
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

    final proofController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Proof Required',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This task requires proof to mark as complete.',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: proofController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe how you completed this task...',
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
              final proof = proofController.text.trim();
              if (proof.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide proof to complete this task'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                // Submit proof and complete task
                await controller.submitProof(_habit!, proof);
                await controller.completeHabit(_habit!, proof: proof);
                
                if (!context.mounted) return;
                Navigator.pop(context); // Close dialog
                await _loadHabitData();
                
                if (!context.mounted) return;
                
                // Navigate back to tasks screen so user sees the task moved to "Done"
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Task completed with proof! ✅"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Complete Task', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      if (!mounted) return;
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
    _proofController.text = _habit!.getTodayProof() ?? '';
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
