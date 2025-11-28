import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recalim/core/models/project_model.dart';
import '../../../../core/constants/project_proof_types.dart';
import '../controllers/projects_controller.dart';
import '../widgets/reflection_questions_dialog.dart';
import '../widgets/micro_quiz_dialog.dart';
import '../widgets/media_capture_dialog.dart';
import '../widgets/external_output_dialog.dart';
import '../../data/services/ai_reflection_service.dart';
import '../../data/services/quiz_template_service.dart';

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
          ...milestone.tasks.map((task) => Builder(
            builder: (context) => _buildTaskItem(context, task, controller),
          )),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, ProjectTaskModel task, ProjectsController controller) {
    final isDone = task.status == 'done';
    final isOverdue = task.isOverdue && !isDone;
    final hasProof = task.proofs.isNotEmpty;
    final suggestedProofType = task.suggestedProofType ?? ProjectProofTypes.timedSession;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone
              ? Colors.green.withValues(alpha: 0.3)
              : isOverdue
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isDone,
                onChanged: (value) async {
                  if (value == true && !isDone) {
                    // Task being marked as done - collect proof first
                    if (task.requiresProof && !hasProof) {
                      await _collectProof(context, task, controller);
                    } else {
                      controller.updateTaskStatus(task.id, 'done');
                    }
                  } else if (value == false && isDone) {
                    controller.updateTaskStatus(task.id, 'pending');
                  }
                },
                activeColor: Colors.orange,
                checkColor: Colors.white,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: isDone
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.dueDate != null)
                      Text(
                        'Due: ${task.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2, '0')}-${task.dueDate!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Proof type badge
          if (!isDone && task.requiresProof) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getProofTypeIcon(suggestedProofType),
                  size: 14,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  ProjectProofTypes.getDisplayName(suggestedProofType),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                if (hasProof) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.green,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getProofTypeIcon(String proofType) {
    switch (proofType) {
      case ProjectProofTypes.timedSession:
        return Icons.timer;
      case ProjectProofTypes.reflectionNote:
        return Icons.edit_note;
      case ProjectProofTypes.smallMediaClip:
        return Icons.videocam;
      case ProjectProofTypes.externalOutput:
        return Icons.link;
      default:
        return Icons.timer;
    }
  }

  Future<void> _collectProof(
    BuildContext context,
    ProjectTaskModel task,
    ProjectsController controller,
  ) async {
    final suggestedProofType = task.suggestedProofType ?? ProjectProofTypes.timedSession;
    final project = controller.projects.firstWhere((p) => 
      p.milestones.any((m) => m.tasks.any((t) => t.id == task.id))
    );

    bool? proofSubmitted = false;

    switch (suggestedProofType) {
      case ProjectProofTypes.timedSession:
        // In roadmap view, use reflection questions instead of work session screen
        // Work session screen is only for habits/daily tasks view
        try {
          final reflectionService = AIReflectionService();
          final reflectionQuestions = await reflectionService.generateReflectionQuestions(
            task,
            project.category,
          );
          if (!context.mounted) return;
          proofSubmitted = await showDialog<bool>(
            context: context,
            builder: (context) => ReflectionQuestionsDialog(
              task: task,
              questions: reflectionQuestions,
            ),
          );
        } catch (e) {
          // Fallback to template questions
          final quizService = QuizTemplateService();
          final questions = quizService.getQuizQuestions(task, project.category);
          if (!context.mounted) return;
          proofSubmitted = await showDialog<bool>(
            context: context,
            builder: (context) => ReflectionQuestionsDialog(
              task: task,
              questions: questions,
            ),
          );
        }
        break;

      case ProjectProofTypes.reflectionNote:
        // Check if it's a learning task (use micro-quiz) or regular reflection
        final quizService = QuizTemplateService();
        final questions = quizService.getQuizQuestions(task, project.category);
        
        // Use micro-quiz for learning tasks, reflection for others
        if (questions.length == 2 && questions.first.question.toLowerCase().contains('main idea')) {
          if (!context.mounted) return;
          proofSubmitted = await showDialog<bool>(
            context: context,
            builder: (context) => MicroQuizDialog(
              task: task,
              category: project.category,
              questions: questions,
            ),
          );
        } else {
          // Generate AI reflection questions
          try {
            final reflectionService = AIReflectionService();
            final reflectionQuestions = await reflectionService.generateReflectionQuestions(
              task,
              project.category,
            );
            if (!context.mounted) return;
            proofSubmitted = await showDialog<bool>(
              context: context,
              builder: (context) => ReflectionQuestionsDialog(
                task: task,
                questions: reflectionQuestions,
              ),
            );
          } catch (e) {
            // Fallback to template questions
            if (!context.mounted) return;
            proofSubmitted = await showDialog<bool>(
              context: context,
              builder: (context) => ReflectionQuestionsDialog(
                task: task,
                questions: questions,
              ),
            );
          }
        }
        break;

      case ProjectProofTypes.smallMediaClip:
        if (!context.mounted) return;
        proofSubmitted = await showDialog<bool>(
          context: context,
          builder: (context) => MediaCaptureDialog(task: task),
        );
        break;

      case ProjectProofTypes.externalOutput:
        if (!context.mounted) return;
        proofSubmitted = await showDialog<bool>(
          context: context,
          builder: (context) => ExternalOutputDialog(task: task),
        );
        break;

      default:
        // Default to reflection questions (not work session in roadmap view)
        try {
          final reflectionService = AIReflectionService();
          final reflectionQuestions = await reflectionService.generateReflectionQuestions(
            task,
            project.category,
          );
          if (!context.mounted) return;
          proofSubmitted = await showDialog<bool>(
            context: context,
            builder: (context) => ReflectionQuestionsDialog(
              task: task,
              questions: reflectionQuestions,
            ),
          );
        } catch (e) {
          // Fallback to template questions
          final quizService = QuizTemplateService();
          final questions = quizService.getQuizQuestions(task, project.category);
          if (!context.mounted) return;
          proofSubmitted = await showDialog<bool>(
            context: context,
            builder: (context) => ReflectionQuestionsDialog(
              task: task,
              questions: questions,
            ),
          );
        }
    }

    // If proof was submitted, mark task as done
    if (proofSubmitted == true) {
      controller.updateTaskStatus(task.id, 'done');
    }
  }
}
