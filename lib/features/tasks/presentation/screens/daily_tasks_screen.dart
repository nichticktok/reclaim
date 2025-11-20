import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/habit_model.dart';
import '../controllers/tasks_controller.dart';
import '../../../progress/presentation/controllers/progress_controller.dart';
import '../../../journey/presentation/controllers/journey_controller.dart';
import '../../../milestone/presentation/controllers/milestone_controller.dart';
import '../../../achievements/presentation/controllers/achievements_controller.dart';
import '../../../achievements/presentation/screens/achievements_screen.dart';
import '../../../streaks/presentation/screens/streaks_screen.dart';
import '../../../rating/presentation/screens/rating_screen.dart';
import '../../../profile/presentation/screens/settings_screen.dart';
import 'select_preset_task_screen.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  String _selectedFilter = "To-dos"; // To-dos, Done, Skipped

  @override
  void initState() {
    super.initState();
    // Initialize controllers only once - they check internally if already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksController>().initialize();
      context.read<ProgressController>().initialize();
      context.read<JourneyController>().initialize();
      context.read<MilestoneController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: Consumer<TasksController>(
        builder: (context, controller, child) {
          // Only show loading if we have no data yet
          if (controller.loading && controller.habits.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          // Get all habits (not filtered by category)
          final allHabits = controller.habits;

          if (allHabits.isEmpty) {
            return Column(
              children: [
                // Header section even when no tasks
                _buildNewHeaderSection(controller, 0, 0, 0),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.task_alt,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tasks yet',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the + button to add your first task',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          
          // Filter habits based on selected filter (To-dos, Done, Skipped)
          final todos = allHabits.where((h) => !h.isCompletedToday() && !h.isSkippedToday()).toList();
          final done = allHabits.where((h) => h.isCompletedToday()).toList();
          final skipped = allHabits.where((h) => h.isSkippedToday()).toList();
          
          final displayHabits = _selectedFilter == "To-dos" 
              ? todos 
              : _selectedFilter == "Done" 
                  ? done 
                  : skipped;

          return Column(
            children: [
              // Header section with stats, day counter, and task filters
              _buildNewHeaderSection(controller, todos.length, done.length, skipped.length),
              
              // Tasks list
              Expanded(
                child: displayHabits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.task_alt,
                              size: 64,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == "To-dos" 
                                  ? 'No tasks to do'
                                  : _selectedFilter == "Done"
                                      ? 'No completed tasks'
                                      : 'No skipped tasks',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: MediaQuery.of(context).padding.bottom + 80, // Account for bottom nav bar
                        ),
                        itemCount: displayHabits.length,
                        itemBuilder: (context, index) {
                          final habit = displayHabits[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildNewTaskCard(
                              habit: habit,
                              controller: controller,
                              context: context,
                            ),
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

  // ✅ When user taps on a habit card - always navigate to detail screen
  void _handleHabitTap(BuildContext context, HabitModel habit, TasksController controller) {
    Navigator.pushNamed(context, '/task_detail', arguments: habit);
  }

  // ✅ Show task information dialog when info icon is clicked
  void _showTaskInfoDialog(BuildContext context, HabitModel habit) {
    final taskInfo = _getTaskInfo(habit.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(taskInfo['icon'] as IconData, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.title,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                taskInfo['description'] as String,
                style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        taskInfo['benefits'] as String,
                        style: const TextStyle(color: Colors.orange, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: Colors.orange, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ✅ Get task-specific information
  Map<String, dynamic> _getTaskInfo(String taskTitle) {
    final title = taskTitle.toLowerCase();
    
    if (title.contains('digital detox') || title.contains('no phone') || title.contains('limit social media')) {
      return {
        'icon': Icons.phone_disabled,
        'description': 'Digital detox helps you break free from constant screen time and digital distractions.',
        'benefits': 'Reduces anxiety, improves sleep quality, enhances real-world relationships, increases focus and productivity, and helps you reconnect with yourself and your surroundings.',
      };
    } else if (title.contains('meditate') || title.contains('meditation')) {
      return {
        'icon': Icons.self_improvement,
        'description': 'Meditation is a practice of training your mind to focus and redirect your thoughts.',
        'benefits': 'Reduces stress and anxiety, improves emotional well-being, enhances self-awareness, increases attention span, and promotes better sleep and overall mental health.',
      };
    } else if (title.contains('water') || title.contains('drink')) {
      return {
        'icon': Icons.water_drop,
        'description': 'Staying hydrated is essential for your body to function optimally.',
        'benefits': 'Improves brain function and concentration, boosts physical performance, supports digestion, maintains healthy skin, regulates body temperature, and helps flush out toxins.',
      };
    } else if (title.contains('exercise') || title.contains('workout')) {
      return {
        'icon': Icons.fitness_center,
        'description': 'Regular physical activity is crucial for maintaining good health and well-being.',
        'benefits': 'Strengthens muscles and bones, improves cardiovascular health, boosts mood and energy, helps with weight management, reduces risk of chronic diseases, and enhances sleep quality.',
      };
    } else if (title.contains('read') || title.contains('reading')) {
      return {
        'icon': Icons.menu_book,
        'description': 'Reading expands your knowledge, vocabulary, and understanding of the world.',
        'benefits': 'Improves memory and cognitive function, reduces stress, enhances empathy and emotional intelligence, expands vocabulary and communication skills, and provides mental stimulation.',
      };
    } else if (title.contains('wake') || title.contains('sleep')) {
      return {
        'icon': Icons.wb_sunny,
        'description': 'Maintaining a consistent sleep schedule is fundamental to your health and productivity.',
        'benefits': 'Improves mood and mental clarity, boosts immune system, enhances memory and learning, regulates hormones, supports physical recovery, and increases daytime energy and focus.',
      };
    } else if (title.contains('gratitude') || title.contains('grateful')) {
      return {
        'icon': Icons.favorite,
        'description': 'Practicing gratitude shifts your focus to the positive aspects of your life.',
        'benefits': 'Increases happiness and life satisfaction, reduces depression and anxiety, improves relationships, enhances empathy, reduces aggression, and promotes better sleep.',
      };
    } else if (title.contains('journal') || title.contains('write')) {
      return {
        'icon': Icons.edit_note,
        'description': 'Journaling helps you process thoughts, emotions, and experiences.',
        'benefits': 'Reduces stress and anxiety, improves self-awareness, enhances problem-solving skills, boosts memory and comprehension, helps track progress and goals, and provides emotional release.',
      };
    } else if (title.contains('cold shower')) {
      return {
        'icon': Icons.water_drop_outlined,
        'description': 'Cold showers can boost your physical and mental resilience.',
        'benefits': 'Increases alertness and energy, improves circulation, strengthens immune system, reduces muscle soreness, enhances mood and mental toughness, and improves skin and hair health.',
      };
    } else if (title.contains('walk') || title.contains('outside')) {
      return {
        'icon': Icons.directions_walk,
        'description': 'Walking outdoors combines physical activity with fresh air and nature exposure.',
        'benefits': 'Improves cardiovascular health, reduces stress and anxiety, boosts vitamin D levels, enhances creativity and problem-solving, improves mood, and strengthens muscles and bones.',
      };
    } else if (title.contains('creative') || title.contains('art') || title.contains('music')) {
      return {
        'icon': Icons.palette,
        'description': 'Creative activities allow you to express yourself and explore your imagination.',
        'benefits': 'Reduces stress and anxiety, improves problem-solving skills, enhances self-expression, boosts confidence, provides sense of accomplishment, and promotes mindfulness and focus.',
      };
    } else if (title.contains('learn') || title.contains('skill')) {
      return {
        'icon': Icons.school,
        'description': 'Continuous learning keeps your mind sharp and opens new opportunities.',
        'benefits': 'Increases career opportunities, boosts confidence and self-esteem, improves cognitive function, enhances adaptability, provides sense of achievement, and keeps you mentally engaged.',
      };
    } else if (title.contains('plan') || title.contains('review') || title.contains('goal')) {
      return {
        'icon': Icons.flag,
        'description': 'Planning and reviewing helps you stay organized and achieve your objectives.',
        'benefits': 'Increases productivity and efficiency, reduces stress and overwhelm, improves time management, helps track progress, enhances decision-making, and provides clarity and direction.',
      };
    } else if (title.contains('help') || title.contains('friend') || title.contains('family')) {
      return {
        'icon': Icons.people,
        'description': 'Maintaining social connections is vital for your emotional well-being.',
        'benefits': 'Reduces feelings of loneliness, improves mental health, provides emotional support, increases sense of belonging, enhances empathy, and creates meaningful relationships.',
      };
    } else if (title.contains('breathing') || title.contains('breath')) {
      return {
        'icon': Icons.air,
        'description': 'Deep breathing exercises activate your body\'s relaxation response.',
        'benefits': 'Reduces stress and anxiety, lowers blood pressure, improves focus and concentration, enhances oxygen flow to brain, promotes relaxation, and helps manage emotions.',
      };
    } else {
      return {
        'icon': Icons.task_alt,
        'description': 'This task helps you build consistency and work towards your goals.',
        'benefits': 'Builds discipline and self-control, creates positive habits, increases sense of accomplishment, improves time management, and moves you closer to your long-term objectives.',
      };
    }
  }

  // ✅ Opens proof submission dialog (REMOVED - proof now requested in detail screen when marking complete)
  // Proof is now requested in the task detail screen when user clicks "Mark as Complete"

  // ✅ Show add task full screen with preset tasks
  void _showAddTaskDialog(BuildContext context) {
    final controller = context.read<TasksController>();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectPresetTaskScreen(controller: controller),
        fullscreenDialog: true,
      ),
    );
  }


  Widget _buildNewHeaderSection(TasksController controller, int todosCount, int doneCount, int skippedCount) {
    return Consumer3<ProgressController, MilestoneController, AchievementsController>(
      builder: (context, progressController, milestoneController, achievementsController, child) {
        final journeyController = context.read<JourneyController>();
        final currentDay = journeyController.currentDay;
        final overallProgress = progressController.overallProgress;
        final totalDays = milestoneController.getTotalDays();
        
        // Get real achievements count
        final achievementsCount = achievementsController.unlockedCount;
        final successRate = (overallProgress * 100).toInt();

        // Calculate current streak and today's task completion
        final streakInfo = _calculateCurrentStreak(controller.habits);
        final currentStreak = streakInfo['streak'] as int;
        final todayTasksCompleted = streakInfo['todayTasksCompleted'] as int;
        
        // Determine color based on today's task completion
        Color streakColor = Colors.grey;
        if (todayTasksCompleted >= 7) {
          streakColor = Colors.red;
        } else if (todayTasksCompleted >= 6) {
          streakColor = Colors.orange;
        } else if (todayTasksCompleted >= 5) {
          streakColor = Colors.green;
        }

        return Container(
          color: const Color(0xFF0D0D0F),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Top row: Stats buttons and settings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Three circular stat buttons
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StreaksScreen(),
                                ),
                              );
                            },
                            child: _buildStatButton(
                              icon: Icons.local_fire_department,
                              value: currentStreak.toString(),
                              color: streakColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AchievementsScreen(),
                                ),
                              );
                            },
                            child: _buildStatButton(
                              icon: Icons.military_tech,
                              value: achievementsCount.toString(),
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RatingScreen(),
                                ),
                              );
                            },
                            child: _buildStatButton(
                              icon: Icons.auto_awesome,
                              value: successRate.toString(),
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      // Settings gear icon
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Day counter
                  Text(
                    "Day $currentDay/$totalDays",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Motivational message
                  Text(
                    currentDay == 1 
                        ? "It's your first day. Don't screw it."
                        : "Keep going, you're doing great!",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Task status buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildTaskStatusButton(
                          label: "To-dos",
                          count: todosCount,
                          isSelected: _selectedFilter == "To-dos",
                          onTap: () => setState(() => _selectedFilter = "To-dos"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTaskStatusButton(
                          label: "Done",
                          count: doneCount,
                          isSelected: _selectedFilter == "Done",
                          onTap: () => setState(() => _selectedFilter = "Done"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTaskStatusButton(
                          label: "Skipped",
                          count: skippedCount,
                          isSelected: _selectedFilter == "Skipped",
                          onTap: () => setState(() => _selectedFilter = "Skipped"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add task button
                      GestureDetector(
                        onTap: () => _showAddTaskDialog(context),
                        child: Container(
                          width: 50,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatButton({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusButton({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "$label $count",
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewTaskCard({
    required HabitModel habit,
    required TasksController controller,
    required BuildContext context,
  }) {
    // Get appropriate background gradient based on task type
    List<Color> getBackgroundGradient() {
      final title = habit.title.toLowerCase();
      if (title.contains('meditate') || title.contains('meditation')) {
        return [const Color(0xFF6B4E71), const Color(0xFF8B6F8F)];
      } else if (title.contains('water') || title.contains('drink')) {
        return [const Color(0xFF4A90E2), const Color(0xFF6BA3E8)];
      } else if (title.contains('exercise') || title.contains('workout')) {
        return [const Color(0xFFE74C3C), const Color(0xFFEC7063)];
      } else if (title.contains('read') || title.contains('reading')) {
        return [const Color(0xFF8E44AD), const Color(0xFFA569BD)];
      } else if (title.contains('wake') || title.contains('sleep')) {
        return [const Color(0xFFFFA500), const Color(0xFFFFB84D)];
      }
      return [const Color(0xFF34495E), const Color(0xFF5D6D7E)];
    }

    // Get frequency text - defaults to "Everyday" for all tasks
    String getFrequency() {
      // Frequency can be added to HabitModel in the future
      return "Everyday";
    }

    final gradient = getBackgroundGradient();
    final frequency = getFrequency();

    return GestureDetector(
      onTap: () => _handleHabitTap(context, habit, controller),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
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
            // Decorative pattern overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                habit.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Proof required indicator (secure icon)
                            if (controller.isProofRequired(habit))
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Info icon - shows task information
                      GestureDetector(
                        onTap: () => _showTaskInfoDialog(context, habit),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Frequency (Everyday)
                      Icon(
                        Icons.repeat,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        frequency,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // Difficulty indicator with color-coded bar
                      _buildDifficultyIndicator(habit.difficulty),
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

  /// Build difficulty indicator with color-coded vertical bars (towers)
  Widget _buildDifficultyIndicator(String difficulty) {
    Color barColor;
    List<double> barHeights; // Heights for each bar (0.0 to 1.0)
    
    switch (difficulty.toLowerCase()) {
      case 'hard':
        barColor = Colors.red;
        barHeights = [1.0, 1.0, 1.0]; // All bars fully filled
        break;
      case 'medium':
        barColor = Colors.orange;
        barHeights = [0.5, 0.5, 0.5]; // All bars half filled
        break;
      case 'easy':
        barColor = Colors.green;
        barHeights = [0.33, 0.33, 0.33]; // All bars 1/3 filled
        break;
      default:
        barColor = Colors.orange;
        barHeights = [0.5, 0.5, 0.5]; // Default to medium
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Three vertical bars (towers)
        ...List.generate(3, (index) {
          return Container(
            margin: EdgeInsets.only(right: index < 2 ? 3 : 0),
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: barHeights[index],
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Calculate current streak (consecutive days with at least 5 tasks completed)
  /// Shows streak from yesterday if today hasn't been completed yet
  Map<String, dynamic> _calculateCurrentStreak(List<HabitModel> habits) {
    if (habits.isEmpty) {
      return {'streak': 0, 'todayTasksCompleted': 0};
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
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return {
      'streak': streak,
      'todayTasksCompleted': todayTasksCompleted,
    };
  }

}
