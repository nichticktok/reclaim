import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recalim/core/models/habit_model.dart';
import '../../../../core/utils/attribute_utils.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../controllers/progress_controller.dart';
import '../../../achievements/presentation/controllers/achievements_controller.dart';

class TodayProgressScreen extends StatefulWidget {
  const TodayProgressScreen({super.key});

  @override
  State<TodayProgressScreen> createState() => _TodayProgressScreenState();
}

class _TodayProgressScreenState extends State<TodayProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksController>().initialize();
      context.read<ProgressController>().initialize();
      context.read<AchievementsController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          "Today's Progress",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer3<TasksController, ProgressController, AchievementsController>(
        builder: (context, tasksController, progressController, achievementsController, child) {
          if (tasksController.loading || progressController.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          final habits = tasksController.habits;
          final overallProgress = progressController.overallProgress;
          final progressPercent = (overallProgress * 100).toInt();
          
          // Calculate today's stats
          final totalTasks = habits.length;
          final completedTasks = habits.where((h) => h.isCompletedToday()).length;
          final skippedTasks = habits.where((h) => h.isSkippedToday()).length;
          final pendingTasks = totalTasks - completedTasks - skippedTasks;

          // Get today's unlocked achievements
          final todayUnlocked = achievementsController.unlockedAchievements
              .where((a) => a.unlockedAt != null && 
                  a.unlockedAt!.year == DateTime.now().year &&
                  a.unlockedAt!.month == DateTime.now().month &&
                  a.unlockedAt!.day == DateTime.now().day)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Progress Card
                _buildProgressCard(progressPercent, completedTasks, totalTasks),
                
                const SizedBox(height: 20),
                
                // Today's Stats
                _buildStatsSection(completedTasks, pendingTasks, skippedTasks, totalTasks),
                
                const SizedBox(height: 20),
                
                // Today's Achievements
                if (todayUnlocked.isNotEmpty) ...[
                  _buildSectionTitle('Achievements Unlocked Today 🎉'),
                  const SizedBox(height: 12),
                  ...todayUnlocked.map((achievement) => _buildAchievementCard(achievement)),
                  const SizedBox(height: 20),
                ],
                
                // Task Breakdown
                _buildSectionTitle('Task Breakdown'),
                const SizedBox(height: 12),
                _buildTaskBreakdown(habits),
                
                const SizedBox(height: 20),
                
                // Motivational Message
                _buildMotivationalMessage(progressPercent, completedTasks, totalTasks),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(int progressPercent, int completed, int total) {
    Color progressColor;
    if (progressPercent >= 80) {
      progressColor = Colors.green;
    } else if (progressPercent >= 50) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            progressColor,
            progressColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: progressColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Today\'s Success Rate',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$progressPercent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$completed of $total tasks completed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(int completed, int pending, int skipped, int total) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Completed',
            completed.toString(),
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending',
            pending.toString(),
            Colors.orange,
            Icons.pending,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Skipped',
            skipped.toString(),
            Colors.red,
            Icons.skip_next,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAchievementCard(dynamic achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBreakdown(List<HabitModel> habits) {
    final completed = habits.where((h) => h.isCompletedToday()).toList();
    final pending = habits.where((h) => !h.isCompletedToday() && !h.isSkippedToday()).toList();
    final skipped = habits.where((h) => h.isSkippedToday()).toList();

    return Column(
      children: [
        if (completed.isNotEmpty) ...[
          _buildTaskGroup('Completed ✅', completed, Colors.green),
          const SizedBox(height: 12),
        ],
        if (pending.isNotEmpty) ...[
          _buildTaskGroup('Pending ⏳', pending, Colors.orange),
          const SizedBox(height: 12),
        ],
        if (skipped.isNotEmpty) ...[
          _buildTaskGroup('Skipped ⏭️', skipped, Colors.red),
        ],
      ],
    );
  }

  Widget _buildTaskGroup(String title, List<HabitModel> tasks, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...tasks.map((task) {
          // Get attribute for color coding
          final attribute = task.attribute ?? AttributeUtils.determineAttribute(
            title: task.title,
            description: task.description,
            category: '',
          );
          final attributeColor = AttributeUtils.getAttributeColor(attribute);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: attributeColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                // Attribute color indicator
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: attributeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  task.isCompletedToday()
                      ? Icons.check_circle
                      : task.isSkippedToday()
                          ? Icons.skip_next
                          : Icons.radio_button_unchecked,
                  color: attributeColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: task.isCompletedToday() ? 1.0 : 0.7),
                      fontSize: 14,
                      decoration: task.isCompletedToday()
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMotivationalMessage(int progressPercent, int completed, int total) {
    String message;
    Color messageColor;

    if (progressPercent >= 100) {
      message = 'Perfect! You\'ve completed all tasks today! 🎉';
      messageColor = Colors.green;
    } else if (progressPercent >= 80) {
      message = 'Excellent work! You\'re almost there! 💪';
      messageColor = Colors.orange;
    } else if (progressPercent >= 50) {
      message = 'Good progress! Keep going! 🔥';
      messageColor = Colors.orange;
    } else if (completed > 0) {
      message = 'You\'ve started! Every step counts! 🌟';
      messageColor = Colors.blue;
    } else {
      message = 'Ready to start? Let\'s make today count! 🚀';
      messageColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: messageColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: messageColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: messageColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: messageColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

