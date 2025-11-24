import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recalim/core/models/project_model.dart';
import '../controllers/projects_controller.dart';

class ProjectRoadmapScreen extends StatelessWidget {
  final String projectId;

  const ProjectRoadmapScreen({
    super.key,
    required this.projectId,
  });

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
          // Find project in loaded projects
          ProjectModel? project;
          try {
            project = controller.projects.firstWhere(
              (p) => p.id == projectId,
            );
          } catch (e) {
            // Project not found, try to refresh
            if (controller.projects.isEmpty) {
              controller.refresh();
            }
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          return _buildProjectContent(context, project, controller);
        },
      ),
    );
  }

  Widget _buildProjectContent(BuildContext context, ProjectModel project, ProjectsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Header
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
                  project.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                // Progress Bar
                LinearProgressIndicator(
                  value: project.progressPercentage,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(project.progressPercentage * 100).toStringAsFixed(0)}% Complete',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Milestones
          Text(
            'Milestones',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...project.milestones.map((milestone) => _buildMilestoneCard(milestone, controller)),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(MilestoneModel milestone, ProjectsController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  milestone.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(milestone.progressPercentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            milestone.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...milestone.tasks.map((task) => _buildTaskItem(task, controller)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(ProjectTaskModel task, ProjectsController controller) {
    final isDone = task.status == 'done';
    final isOverdue = task.isOverdue && !isDone;

    return CheckboxListTile(
      value: isDone,
      onChanged: (value) {
        controller.updateTaskStatus(
          task.id,
          value == true ? 'done' : 'pending',
        );
      },
      title: Text(
        task.title,
        style: TextStyle(
          color: isDone
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.white,
          decoration: isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: task.dueDate != null
          ? Text(
              'Due: ${task.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2, '0')}-${task.dueDate!.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isOverdue ? Colors.red : Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            )
          : null,
      activeColor: Colors.orange,
      checkColor: Colors.white,
    );
  }
}
