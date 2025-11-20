import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../../../../models/habit_model.dart';

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> {
  String _selectedFilter = 'All'; // All, Active, Completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          'Your Streaks',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TasksController>(
        builder: (context, controller, child) {
          if (controller.loading && controller.habits.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          // Calculate streaks for each task
          final taskStreaks = _calculateTaskStreaks(controller.habits);

          // Filter streaks
          final filteredStreaks = _selectedFilter == 'All'
              ? taskStreaks
              : _selectedFilter == 'Active'
                  ? taskStreaks.where((s) => s['streak']! > 0).toList()
                  : taskStreaks.where((s) => s['streak']! == 0).toList();

          return Column(
            children: [
              // Filter tabs
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: ['All', 'Active', 'Completed'].length,
                  itemBuilder: (context, index) {
                    final filter = ['All', 'Active', 'Completed'][index];
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.orange : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Streaks list
              Expanded(
                child: filteredStreaks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 'Active'
                                  ? 'No active streaks'
                                  : _selectedFilter == 'Completed'
                                      ? 'No completed streaks'
                                      : 'No streaks yet',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredStreaks.length,
                        itemBuilder: (context, index) {
                          final streak = filteredStreaks[index];
                          return _buildStreakCard(streak);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _calculateTaskStreaks(List<HabitModel> habits) {
    final streaks = <Map<String, dynamic>>[];

    for (final habit in habits) {
      final streak = _calculateConsecutiveStreak(habit);
      final category = _getTaskCategory(habit.title);

      streaks.add({
        'habit': habit,
        'streak': streak,
        'category': category,
        'title': habit.title,
      });
    }

    // Sort by streak (highest first)
    streaks.sort((a, b) => (b['streak'] as int).compareTo(a['streak'] as int));

    return streaks;
  }

  int _calculateConsecutiveStreak(HabitModel habit) {
    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      final dateStr =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

      if (habit.dailyCompletion[dateStr] == true) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  String _getTaskCategory(String taskTitle) {
    final titleLower = taskTitle.toLowerCase();
    if (titleLower.contains('wake') || titleLower.contains('6') || titleLower.contains('morning')) {
      return 'Early Riser';
    } else if (titleLower.contains('exercise') || titleLower.contains('workout') || titleLower.contains('gym')) {
      return 'Fitness';
    } else if (titleLower.contains('meditate') || titleLower.contains('meditation')) {
      return 'Mindfulness';
    } else if (titleLower.contains('read') || titleLower.contains('book')) {
      return 'Learning';
    } else if (titleLower.contains('water') || titleLower.contains('drink')) {
      return 'Health';
    } else {
      return 'Other';
    }
  }

  Widget _buildStreakCard(Map<String, dynamic> streakData) {
    final streak = streakData['streak'] as int;
    final category = streakData['category'] as String;
    final title = streakData['title'] as String;

    final isActive = streak > 0;
    final color = isActive ? Colors.orange : Colors.white.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.orange.withValues(alpha: 0.1)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.orange.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Fire icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.orange.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Task info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isActive
                              ? Colors.orange
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Streak count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$streak',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                streak == 1 ? 'day' : 'days',
                style: TextStyle(
                  color: isActive
                      ? Colors.orange.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

