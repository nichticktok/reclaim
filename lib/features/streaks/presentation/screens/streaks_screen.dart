import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../../../../models/habit_model.dart';

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> with TickerProviderStateMixin {
  late AnimationController _burningAnimationController;

  @override
  void initState() {
    super.initState();
    _burningAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = context.read<TasksController>();
        controller.initialize();
      }
    });
  }

  @override
  void dispose() {
    _burningAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: Consumer<TasksController>(
        builder: (context, controller, child) {
          // Ensure controller is initialized
          if (!controller.loading && controller.habits.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                try {
                  controller.initialize();
                } catch (e) {
                  debugPrint('Error initializing TasksController in StreaksScreen: $e');
                }
              }
            });
          }

          if (controller.loading && controller.habits.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          // Calculate current streak and today's task completion
          final streakInfo = _calculateCurrentStreak(controller.habits);
          final currentStreak = streakInfo['streak'] as int;
          final todayTasksCompleted = streakInfo['todayTasksCompleted'] as int;
          final firstStreakDate = streakInfo['firstStreakDate'] as DateTime?;
          final isRedTier = todayTasksCompleted >= 7;

          // Calculate 7-day challenge progress starting from first streak date
          final challengeProgress = _calculate7DayChallenge(controller.habits, firstStreakDate);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Orange Header with current streak
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 50, bottom: 30, left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Close button (top left)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Current streak display (only show if streak > 0)
                      if (currentStreak > 0) ...[
                        Text(
                          '$currentStreak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'day streak',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Start Your Streak',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete 5 tasks to begin',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 7 Day Challenge Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '7 Day Challenge',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              challengeProgress['currentDay'] > 0
                                  ? 'Day ${challengeProgress['currentDay']} of 7'
                                  : 'Not Started',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Days of week with fire icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['F', 'S', 'S', 'M', 'T', 'W', 'T'].asMap().entries.map((entry) {
                            final index = entry.key;
                            final day = entry.value;
                            final dayData = challengeProgress['completedDays'][index] as Map<String, dynamic>;
                            final isCompleted = dayData['completed'] == true;
                            final tasksCompleted = dayData['tasksCompleted'] as int;
                            
                            // Determine color based on tasks completed
                            Color fireColor = Colors.grey;
                            bool showAnimation = false;
                            if (tasksCompleted >= 7) {
                              fireColor = Colors.red;
                              showAnimation = true;
                            } else if (tasksCompleted >= 6) {
                              fireColor = Colors.orange;
                            } else if (tasksCompleted >= 5) {
                              fireColor = Colors.green;
                            }
                            
                            return Column(
                              children: [
                                Text(
                                  day,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (showAnimation && isCompleted)
                                  AnimatedBuilder(
                                    animation: _burningAnimationController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: 1.0 + (math.sin(_burningAnimationController.value * 2 * math.pi) * 0.15),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: fireColor.withValues(alpha: 0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.local_fire_department,
                                            color: fireColor,
                                            size: 20,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? fireColor.withValues(alpha: 0.2)
                                          : const Color(0xFF2A2A2A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: isCompleted
                                        ? Icon(
                                            Icons.local_fire_department,
                                            color: fireColor,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Instruction text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'To secure a streak, complete at least 2 tasks in a day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Streak Achievements Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                    children: [
                      _buildStreakBadge(7, '7-DAY STREAK', '7-Day Streak', currentStreak, isRedTier),
                      _buildStreakBadge(14, '14-DAY STREAK', '14-Day Streak', currentStreak, isRedTier),
                      _buildStreakBadge(33, '33-DAY STREAK', '33-Day Streak', currentStreak, isRedTier),
                      _buildStreakBadge(66, '66-DAY STREAK', '66-Day Streak', currentStreak, isRedTier),
                      _buildStreakBadge(96, '96-DAY STREAK', '96-Day Streak', currentStreak, isRedTier),
                      _buildStreakBadge(132, '132-DAY STREAK', '132-Day Streak', currentStreak, isRedTier),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Calculate current streak (consecutive days with at least 5 tasks completed)
  /// Shows streak from yesterday if today hasn't been completed yet
  Map<String, dynamic> _calculateCurrentStreak(List<HabitModel> habits) {
    if (habits.isEmpty) {
      return {'streak': 0, 'todayTasksCompleted': 0, 'firstStreakDate': null};
    }

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Count today's completed tasks
    int todayTasksCompleted = 0;
    for (var habit in habits) {
      if (habit.dailyCompletion[todayStr] == true) {
        todayTasksCompleted++;
      }
    }

    // Start checking from yesterday if today has less than 5 tasks
    // Otherwise start from today
    DateTime checkDate;
    bool includeToday = todayTasksCompleted >= 5;
    
    if (includeToday) {
      checkDate = today;
    } else {
      // Start from yesterday to show streak from previous days
      checkDate = today.subtract(const Duration(days: 1));
    }

    int streak = 0;
    DateTime? firstStreakDate;
    
    // Count consecutive days with at least 5 tasks completed
    while (true) {
      final dateStr =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

      int tasksCompleted = 0;
      for (var habit in habits) {
        if (habit.dailyCompletion[dateStr] == true) {
          tasksCompleted++;
        }
      }

      // Need at least 5 tasks completed to count as a streak day
      if (tasksCompleted >= 5) {
        streak++;
        firstStreakDate = checkDate;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return {
      'streak': streak,
      'todayTasksCompleted': todayTasksCompleted,
      'firstStreakDate': firstStreakDate,
    };
  }

  /// Calculate 7-day challenge progress starting from first streak day
  Map<String, dynamic> _calculate7DayChallenge(List<HabitModel> habits, DateTime? firstStreakDate) {
    final completedDays = <Map<String, dynamic>>[];
    int currentDay = 0;
    
    if (firstStreakDate == null) {
      // No streak yet, show empty challenge
      return {
        'completedDays': List.generate(7, (index) => {'completed': false, 'tasksCompleted': 0}),
        'currentDay': 0,
      };
    }

    final today = DateTime.now();
    final startDate = firstStreakDate;

    // Check days starting from first streak date
    for (int i = 0; i < 7; i++) {
      final checkDate = startDate.add(Duration(days: i));
      
      // Don't check future dates
      if (checkDate.isAfter(today)) {
        completedDays.add({'completed': false, 'tasksCompleted': 0});
        continue;
      }

      final dateStr =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

      int tasksCompleted = 0;
      for (var habit in habits) {
        if (habit.dailyCompletion[dateStr] == true) {
          tasksCompleted++;
        }
      }

      // Day is completed if at least 5 tasks were done
      final isCompleted = tasksCompleted >= 5;
      completedDays.add({
        'completed': isCompleted,
        'tasksCompleted': tasksCompleted,
      });
      
      if (isCompleted) {
        currentDay++;
      }
    }

    return {
      'completedDays': completedDays,
      'currentDay': currentDay.clamp(0, 7),
    };
  }

  Widget _buildStreakBadge(int requiredDays, String label, String title, int currentStreak, bool isRedTier) {
    final isUnlocked = currentStreak >= requiredDays;
    final progress = (currentStreak / requiredDays).clamp(0.0, 1.0);
    final showBurning = isRedTier && isUnlocked;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? (showBurning ? Colors.red : Colors.orange)
              : Colors.white.withValues(alpha: 0.1),
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge icon with burning animation if red tier
          if (showBurning)
            AnimatedBuilder(
              animation: _burningAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (math.sin(_burningAnimationController.value * 2 * math.pi) * 0.1),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                );
              },
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department,
                color: isUnlocked
                    ? Colors.orange
                    : Colors.grey.withValues(alpha: 0.5),
                size: 40,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isUnlocked
                  ? (showBurning ? Colors.red : Colors.orange)
                  : Colors.grey,
            ),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
            Text(
              '$currentStreak/$requiredDays',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
