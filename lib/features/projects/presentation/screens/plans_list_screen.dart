import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recalim/core/models/plan_model.dart';
import 'package:recalim/core/models/workout_model.dart';
import '../controllers/projects_controller.dart';
import '../../../workouts/presentation/controllers/workouts_controller.dart';
import '../../../workouts/presentation/screens/workout_roadmap_screen.dart';
import 'plan_roadmap_screen.dart';

enum _PlanType {
  project,
  workout,
}

class _PlanItem {
  final _PlanType type;
  final PlanModel? projectPlan;
  final WorkoutPlanModel? workoutPlan;

  _PlanItem({
    required this.type,
    this.projectPlan,
    this.workoutPlan,
  });
}

class PlansListScreen extends StatefulWidget {
  const PlansListScreen({super.key});

  @override
  State<PlansListScreen> createState() => _PlansListScreenState();
}

class _PlansListScreenState extends State<PlansListScreen> {
  @override
  void initState() {
    super.initState();
    // Load plans when screen opens - use a microtask to ensure we're outside build phase
    Future.microtask(() {
      if (mounted) {
        context.read<ProjectsController>().loadPlans();
        context.read<WorkoutsController>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          'All Plans',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<ProjectsController, WorkoutsController>(
        builder: (context, projectsController, workoutsController, child) {
          final isLoading = (projectsController.loading && projectsController.plans.isEmpty) ||
              (workoutsController.loading && workoutsController.workoutPlans.isEmpty);
          
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          final allPlans = <_PlanItem>[];
          
          // Add project plans
          for (var plan in projectsController.plans) {
            allPlans.add(_PlanItem(type: _PlanType.project, projectPlan: plan));
          }
          
          // Add workout plans
          for (var workoutPlan in workoutsController.workoutPlans) {
            allPlans.add(_PlanItem(type: _PlanType.workout, workoutPlan: workoutPlan));
          }
          
          // Sort by start date (most recent first)
          allPlans.sort((a, b) {
            final aDate = a.type == _PlanType.project 
                ? a.projectPlan!.startDate 
                : a.workoutPlan!.startDate;
            final bDate = b.type == _PlanType.project 
                ? b.projectPlan!.startDate 
                : b.workoutPlan!.startDate;
            return bDate.compareTo(aDate);
          });

          if (allPlans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Plans Yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a project or workout plan to get started',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await projectsController.loadPlans();
              await workoutsController.refresh();
            },
            color: Colors.orange,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: allPlans.length,
              itemBuilder: (context, index) {
                final planItem = allPlans[index];
                if (planItem.type == _PlanType.project) {
                  return _buildProjectPlanCard(context, planItem.projectPlan!);
                } else {
                  return _buildWorkoutPlanCard(context, planItem.workoutPlan!);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectPlanCard(BuildContext context, PlanModel plan) {
    final totalDays = plan.dailyPlans.length;
    final startDate = plan.startDate;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanRoadmapScreen(planId: plan.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.rocket_launch,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      plan.projectTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (plan.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  plan.description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.calendar_today,
                          text: '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          icon: Icons.event,
                          text: '$totalDays days',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutPlanCard(BuildContext context, WorkoutPlanModel workoutPlan) {
    final totalSessions = workoutPlan.workoutDays.length;
    final startDate = workoutPlan.startDate;
    
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutRoadmapScreen(workoutPlanId: workoutPlan.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.fitness_center,
                                    color: Color(0xFFFF6B35),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      getGoalDisplayName(workoutPlan.goalType),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${workoutPlan.fitnessLevel.toUpperCase()} • ${workoutPlan.durationWeeks} weeks',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.calendar_today,
                          text: '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          icon: Icons.event,
                          text: '$totalSessions sessions',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          icon: Icons.access_time,
                          text: '${workoutPlan.minutesPerSession}min',
                        ),
                      ],
                    ),
                    if (workoutPlan.equipment.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: workoutPlan.equipment.take(3).map((eq) {
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
            ),
          ],
        ),
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
}
