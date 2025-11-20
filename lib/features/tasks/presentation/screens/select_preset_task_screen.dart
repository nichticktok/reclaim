import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/preset_task_model.dart';
import '../controllers/tasks_controller.dart';

class SelectPresetTaskScreen extends StatelessWidget {
  final TasksController controller;

  const SelectPresetTaskScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          'Select a Task',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TasksController>(
        builder: (context, controller, child) {
          if (controller.loadingPresets && controller.presetTasks.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (controller.presetTasks.isEmpty) {
            return const Center(
              child: Text(
                'No preset tasks available',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          // Group by category
          final categories = <String, List<PresetTaskModel>>{};
          for (var task in controller.presetTasks) {
            categories.putIfAbsent(task.category, () => []).add(task);
          }

          return Column(
            children: [
              // Disclaimer about proof icon
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tasks with this icon require proof when marking as complete',
                        style: TextStyle(
                          color: Colors.green.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Preset tasks list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories.keys.elementAt(index);
                    final tasks = categories[category]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: 12,
                            top: index > 0 ? 20 : 0,
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...tasks.map((presetTask) {
                          // Check if user already has this task
                          final hasTask = controller.habits.any(
                            (h) => h.title.toLowerCase() == presetTask.title.toLowerCase(),
                          );

                          return _buildPresetTaskCard(
                            context: context,
                            presetTask: presetTask,
                            isAdded: hasTask,
                            controller: controller,
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetTaskCard({
    required BuildContext context,
    required PresetTaskModel presetTask,
    required bool isAdded,
    required TasksController controller,
  }) {
    // Get gradient based on category
    List<Color> getGradient() {
      final category = presetTask.category.toLowerCase();
      if (category.contains('health')) {
        return [const Color(0xFFE74C3C), const Color(0xFFEC7063)];
      } else if (category.contains('mindfulness')) {
        return [const Color(0xFF6B4E71), const Color(0xFF8B6F8F)];
      } else if (category.contains('productivity')) {
        return [const Color(0xFF8E44AD), const Color(0xFFA569BD)];
      } else if (category.contains('social')) {
        return [const Color(0xFF4A90E2), const Color(0xFF6BA3E8)];
      } else if (category.contains('digital')) {
        return [const Color(0xFF34495E), const Color(0xFF5D6D7E)];
      } else if (category.contains('personal')) {
        return [const Color(0xFFFFA500), const Color(0xFFFFB84D)];
      } else if (category.contains('self-care')) {
        return [const Color(0xFF16A085), const Color(0xFF48C9B0)];
      }
      return [const Color(0xFF34495E), const Color(0xFF5D6D7E)];
    }

    final gradient = getGradient();
    final proofRequired = controller.hardModeEnabled || presetTask.requiresProof;

    return GestureDetector(
      onTap: isAdded
          ? null
          : () async {
              try {
                await controller.addPresetTask(presetTask);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${presetTask.title} added! ✅'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().contains('already exists')
                        ? 'Task already added'
                        : 'Error adding task'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isAdded
                ? [const Color(0xFF2A2A2A), const Color(0xFF2A2A2A)]
                : gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAdded ? Colors.green.withValues(alpha: 0.5) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          presetTask.title,
                          style: TextStyle(
                            color: isAdded ? Colors.white54 : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: isAdded ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (proofRequired)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      if (isAdded)
                        const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    presetTask.description,
                    style: TextStyle(
                      color: isAdded
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        presetTask.scheduledTime,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

