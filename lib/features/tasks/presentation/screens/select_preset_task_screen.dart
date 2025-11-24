import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recalim/core/models/preset_task_model.dart';
import '../../../../core/utils/attribute_utils.dart';
import '../controllers/tasks_controller.dart';
import 'task_customization_screen.dart';

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

          // Group by category (original categories)
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
                          // Check if user already has at least one schedule for this preset
                          final scheduledCount = controller.habits
                              .where((habit) => habit.presetTaskId == presetTask.id)
                              .length;
                          final hasTask = scheduledCount > 0;
                          
                          // Get attribute color for this task (from database or fallback)
                          final attribute = presetTask.attribute.isNotEmpty 
                              ? presetTask.attribute 
                              : AttributeUtils.determineAttribute(
                                  title: presetTask.title,
                                  description: presetTask.description,
                                  category: presetTask.category,
                                );
                          final attributeColor = AttributeUtils.getAttributeColor(attribute);

                          return _buildPresetTaskCard(
                            context: context,
                            presetTask: presetTask,
                            isAdded: hasTask,
                            controller: controller,
                            attributeColor: attributeColor,
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
    required Color attributeColor,
  }) {
    // Create gradient from attribute color using centralized utility
    final gradient = AttributeUtils.getAttributeGradient(
      presetTask.attribute.isNotEmpty 
          ? presetTask.attribute 
          : AttributeUtils.determineAttribute(
              title: presetTask.title,
              description: presetTask.description,
              category: presetTask.category,
            ),
    );
    final proofRequired = controller.hardModeEnabled || presetTask.requiresProof;

    return GestureDetector(
      onTap: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskCustomizationScreen(
                    presetTask: presetTask,
                  ),
                ),
              );

              if (result == null || !context.mounted) return;

        final daysOfWeek = (result['daysOfWeek'] as List<dynamic>?)
                ?.map((day) => day as int)
                .toList() ??
            [];

              try {
          await controller.addPresetTask(
            presetTask: presetTask,
                  title: result['title'] as String,
                  description: result['description'] as String,
                  scheduledTime: result['scheduledTime'] as String,
            daysOfWeek: daysOfWeek,
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
              content: Text('${result['title']} scheduled! ✅'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
              content: Text(
                e.toString().contains('Select at least one day')
                    ? 'Pick at least one day.'
                    : e.toString().contains('already scheduled')
                        ? 'You already scheduled this combo.'
                        : 'Error adding task',
              ),
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
                        child: Row(
                          children: [
                            // Attribute indicator
                            Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: attributeColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                          ],
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

