import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/plan_model.dart';
import '../../domain/entities/project_planning_input.dart';
import '../controllers/projects_controller.dart';
import 'project_roadmap_screen.dart';

class ReviewPlanScreen extends StatelessWidget {
  final ProjectPlanningInput input;

  const ReviewPlanScreen({super.key, required this.input});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text('Review Plan', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ProjectsController>(
        builder: (context, controller, child) {
          final plan = controller.generatedPlan;
          if (plan == null) {
            return const Center(
              child: Text(
                'No plan generated',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final totalDays = input.totalDays;
          final totalHours = input.totalAvailableHours;
          final totalEstimatedHours = plan.phases
              .expand((p) => p.tasks)
              .fold(0.0, (sum, task) => sum + task.estimatedHours);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        input.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStat('$totalDays', 'Days'),
                          const SizedBox(width: 16),
                          _buildStat(totalHours.toStringAsFixed(0), 'Hours'),
                          const SizedBox(width: 16),
                          _buildStat('${plan.phases.length}', 'Phases'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Estimated: ${totalEstimatedHours.toStringAsFixed(1)}h',
                        style: TextStyle(
                          color: totalEstimatedHours > totalHours
                              ? Colors.red
                              : Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Phases
                Text(
                  'Project Phases',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...plan.phases.map((phase) => _buildPhaseCard(phase)),
                const SizedBox(height: 24),

                // Daily Plans Preview
                if (controller.generatedDailyPlan != null) ...[
                  Text(
                    'Daily Schedule Preview',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your plan has been saved to the plans collection with ${controller.generatedDailyPlan!.dailyPlans.length} daily schedules',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...controller.generatedDailyPlan!.dailyPlans.take(5).map((dailyPlan) => _buildDailyPlanCard(dailyPlan)),
                  if (controller.generatedDailyPlan!.dailyPlans.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+ ${controller.generatedDailyPlan!.dailyPlans.length - 5} more days...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.loading
                        ? null
                        : () async {
                            try {
                              final project = await controller
                                  .createProjectFromPlan(input, plan);
                              if (!context.mounted) return;

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProjectRoadmapScreen(
                                    projectId: project.id,
                                  ),
                                ),
                                (route) => route.isFirst,
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
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
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Confirm & Create Project',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseCard(dynamic phase) {
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
          Text(
            'Phase ${phase.order}: ${phase.title}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            phase.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${phase.tasks.length} tasks',
            style: TextStyle(
              color: Colors.orange.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...phase.tasks
              .take(3)
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
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
                ),
              ),
          if (phase.tasks.length > 3)
            Text(
              '+ ${phase.tasks.length - 3} more tasks',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyPlanCard(dynamic dailyPlan) {
    final dateStr = '${dailyPlan.date.month}/${dailyPlan.date.day}/${dailyPlan.date.year}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${dailyPlan.totalHours.toStringAsFixed(1)}h',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (dailyPlan.notes != null) ...[
            const SizedBox(height: 4),
            Text(
              dailyPlan.notes!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (dailyPlan.tasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...dailyPlan.tasks.take(3).map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${task.estimatedHours.toStringAsFixed(1)}h',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (dailyPlan.tasks.length > 3)
              Text(
                '+ ${dailyPlan.tasks.length - 3} more tasks',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Rest day',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
