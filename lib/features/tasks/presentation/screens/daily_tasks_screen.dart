import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/habit_model.dart';
import 'package:recalim/core/theme/app_colors.dart';
import 'package:recalim/core/theme/app_text_styles.dart';
import 'package:recalim/core/theme/app_design_system.dart';
import '../controllers/tasks_controller.dart';
import '../../../progress/presentation/controllers/progress_controller.dart';
import '../../../journey/presentation/controllers/journey_controller.dart';
import '../../../milestone/presentation/controllers/milestone_controller.dart';
import '../../../achievements/presentation/controllers/achievements_controller.dart';
import '../../../achievements/presentation/screens/achievements_screen.dart';
import '../../../streaks/presentation/screens/streaks_screen.dart';
import '../../../rating/presentation/screens/rating_screen.dart';
import '../../../../core/utils/attribute_utils.dart';
import '../../../profile/presentation/screens/settings_screen.dart';
import 'select_preset_task_screen.dart';
import '../../../projects/presentation/controllers/projects_controller.dart';
import 'package:recalim/core/models/project_model.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  String _selectedFilter = "To-dos"; // To-dos, Done, Skipped
  DateTime _selectedDate = DateTime.now(); // Currently selected date for viewing tasks
  DateTime? _accountCreationDate; // Account creation date (earliest allowed date)

  @override
  void initState() {
    super.initState();
    // Initialize controllers only once - they check internally if already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksController>().initialize();
      context.read<ProgressController>().initialize();
      context.read<JourneyController>().initialize();
      context.read<MilestoneController>().initialize();
      _loadAccountCreationDate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload habits when returning to this screen (e.g., after syncing plans)
    final tasksController = context.read<TasksController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        tasksController.reloadHabits();
      }
    });
  }


  /// Load account creation date from Firestore
  Future<void> _loadAccountCreationDate() async {
    try {
      final auth = FirebaseAuth.instance.currentUser;
      if (auth == null) return;

      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(auth.uid).get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data['createdAt'] != null) {
          final createdAt = data['createdAt'];
          DateTime? accountDate;
          
          if (createdAt is Timestamp) {
            accountDate = createdAt.toDate();
          } else if (createdAt is DateTime) {
            accountDate = createdAt;
          }
          
          if (accountDate != null && mounted) {
            // Normalize to start of day
            final normalizedDate = DateTime(accountDate.year, accountDate.month, accountDate.day);
            final selectedDateNormalized = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
            
            debugPrint('📅 Account creation date loaded: $normalizedDate');
            debugPrint('📅 Selected date: $selectedDateNormalized');
            
            setState(() {
              _accountCreationDate = normalizedDate;
              
              // If selected date is before account creation, adjust it
              if (selectedDateNormalized.isBefore(normalizedDate)) {
                debugPrint('⚠️ Selected date is before account creation, adjusting to: $normalizedDate');
                _selectedDate = normalizedDate;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading account creation date: $e');
      // Fallback to today if we can't load it
      if (mounted) {
        final today = DateTime.now();
        setState(() {
          _accountCreationDate = DateTime(today.year, today.month, today.day);
        });
      }
    }
  }

  /// Navigate to previous day
  void _goToPreviousDay() {
    final earliestDate = _getEarliestDate();
    final selectedDateNormalized = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final earliestDateNormalized = DateTime(earliestDate.year, earliestDate.month, earliestDate.day);
    
    if (selectedDateNormalized.isAfter(earliestDateNormalized)) {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    } else {
      debugPrint('⚠️ Cannot go to previous day: Already at earliest date ($earliestDateNormalized)');
    }
  }
  
  /// Check if previous day button should be enabled
  bool get _canGoToPreviousDay {
    final earliestDate = _getEarliestDate();
    final selectedDateNormalized = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final earliestDateNormalized = DateTime(earliestDate.year, earliestDate.month, earliestDate.day);
    return selectedDateNormalized.isAfter(earliestDateNormalized);
  }

  /// Navigate to next day
  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  /// Get the earliest date (account creation date, which is the absolute minimum)
  DateTime _getEarliestDate() {
    // Always use account creation date as the earliest date
    // If not loaded yet, default to today
    final accountDate = _accountCreationDate;
    if (accountDate != null) {
      return accountDate;
    }
    
    // Fallback: if account date not loaded, use today as minimum
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }

  /// Get the latest date (furthest future date from projects or reasonable limit)
  DateTime _getLatestDate(TasksController controller) {
    // Check for project end dates
    DateTime? latestDate;
    
    // Check active projects for their end dates
    try {
      final projectsController = context.read<ProjectsController>();
      for (var project in projectsController.projects) {
        if (project.status == 'active' && project.endDate.isAfter(DateTime.now())) {
          if (latestDate == null || project.endDate.isAfter(latestDate)) {
            latestDate = project.endDate;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting latest date from projects: $e');
    }
    
    // Default to 1 year from now if no projects
    return latestDate ?? DateTime.now().add(const Duration(days: 365));
  }

  /// Get project tasks for a specific date
  // ignore: unused_element
  List<ProjectTaskModel> _getProjectTasksForDate(TasksController controller, DateTime date) {
    try {
      final projectsController = context.read<ProjectsController>();
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = dateStart.add(const Duration(days: 1));
      
      final tasks = <ProjectTaskModel>[];
      
      for (var project in projectsController.projects) {
        if (project.status != 'active') continue;
        
        for (var milestone in project.milestones) {
          for (var task in milestone.tasks) {
            if (task.dueDate != null &&
                task.dueDate!.isAfter(dateStart) &&
                task.dueDate!.isBefore(dateEnd) &&
                task.status != 'done') {
              tasks.add(task);
            }
          }
        }
      }
      
      return tasks;
    } catch (e) {
      debugPrint('Error getting project tasks: $e');
      return [];
    }
  }

  /// Show date picker to jump to any date
  Future<void> _showDatePicker(BuildContext context, TasksController controller) async {
    final earliestDate = _getEarliestDate();
    final latestDate = _getLatestDate(controller);
    
    // Store context references before async operations
    final currentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
    
    final picked = await showDatePicker(
      context: currentContext,
      initialDate: _selectedDate,
      firstDate: earliestDate,
      lastDate: latestDate,
      helpText: 'Select Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0D0D0F),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final earliestDate = _getEarliestDate();
      final pickedNormalized = DateTime(picked.year, picked.month, picked.day);
      final earliestNormalized = DateTime(earliestDate.year, earliestDate.month, earliestDate.day);
      
      // Ensure picked date is not before account creation date
      if (pickedNormalized.isBefore(earliestNormalized)) {
        // Show error and don't change date
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Cannot select date before account creation (${_getMonthName(earliestDate.month)} ${earliestDate.day}, ${earliestDate.year})',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      setState(() {
        _selectedDate = pickedNormalized;
      });
    }
  }

  /// Calculate day number based on milestone start date
  int _calculateDayNumber(DateTime date, MilestoneController milestoneController, JourneyController journeyController) {
    // Try to get milestone start date
    final milestone = milestoneController.currentMilestone;
    if (milestone != null && milestone.isActive) {
      final difference = date.difference(milestone.startDate).inDays;
      return (difference + 1).clamp(1, milestone.totalDays);
    }
    
    // Fallback: calculate from journey current day
    // Get the journey start date by working backwards from current day
    final currentDay = journeyController.currentDay;
    if (currentDay > 0) {
      final today = DateTime.now();
      final journeyStartDate = today.subtract(Duration(days: currentDay - 1));
      final difference = date.difference(journeyStartDate).inDays;
      return (difference + 1).clamp(1, 999); // No upper limit for journey
    }
    
    // Default: calculate from today
    final today = DateTime.now();
    final difference = date.difference(today).inDays;
    return (difference + 1).clamp(1, 999);
  }

  /// Get motivational message based on selected date
  String _getMotivationalMessage(int dayNumber, DateTime selectedDate) {
    final today = DateTime.now();
    final isToday = selectedDate.year == today.year && 
                    selectedDate.month == today.month && 
                    selectedDate.day == today.day;
    
    if (isToday) {
      if (dayNumber == 1) {
        return "It's your first day. Don't screw it.";
      } else {
        return "Keep going, you're doing great!";
      }
    } else if (selectedDate.isBefore(today)) {
      return "Well done, you conquered the day!";
    } else {
      return "You are going to make it.";
    }
  }

  /// Check if selected date is today
  bool _isToday(DateTime selectedDate) {
    final today = DateTime.now();
    return selectedDate.year == today.year && 
           selectedDate.month == today.month && 
           selectedDate.day == today.day;
  }

  /// Get day name from date
  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  /// Get month name from date
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Build date display widget
  Widget _buildDateDisplay(DateTime selectedDate) {
    final isToday = _isToday(selectedDate);
    
    if (isToday) {
      return const Text(
        "Today",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      );
    } else {
      final dayName = _getDayName(selectedDate);
      final monthName = _getMonthName(selectedDate.month);
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day name on first line
          Text(
            dayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Date on second line
          Text(
            '$monthName ${selectedDate.day}, ${selectedDate.year}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppDesignSystem.lightBackgroundGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Consumer<TasksController>(
        builder: (context, controller, child) {
          // Only show loading if we have no data yet
          if (controller.loading && controller.habits.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Only show habits scheduled for the selected date
          // Also filter out any dates before account creation
          if (_accountCreationDate != null) {
            final selectedDateNormalized = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
            final accountDateNormalized = DateTime(_accountCreationDate!.year, _accountCreationDate!.month, _accountCreationDate!.day);
            
            // If selected date is before account creation, show no tasks
            if (selectedDateNormalized.isBefore(accountDateNormalized)) {
              debugPrint('🚫 Blocked: Selected date $selectedDateNormalized is before account creation $accountDateNormalized');
              return Column(
                children: [
                  _buildNewHeaderSection(controller, 0, 0, 0, _selectedDate),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks available before ${_getMonthName(_accountCreationDate!.month)} ${_accountCreationDate!.day}, ${_accountCreationDate!.year}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          }
          
          final scheduledHabits = controller.habits
              .where((habit) => habit.isScheduledForDate(_selectedDate))
              .toList();

          if (scheduledHabits.isEmpty) {
            return Column(
              children: [
                // Header section even when no tasks
                _buildNewHeaderSection(controller, 0, 0, 0, _selectedDate),
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
          
          // Filter habits based on selected filter and selected date
          // Note: Project tasks integration will be added in future update
          // final projectTasks = _getProjectTasksForDate(controller, _selectedDate);
          final todos = scheduledHabits.where((h) => !h.isCompletedForDate(_selectedDate) && !h.isSkippedForDate(_selectedDate)).toList();
          final done = scheduledHabits.where((h) => h.isCompletedForDate(_selectedDate)).toList();
          final skipped = scheduledHabits.where((h) => h.isSkippedForDate(_selectedDate)).toList();
          
          // Count todos excluding tasks with pending deletion (they show but don't count)
          final todosCount = todos.where((h) => h.deletionStatus != "pending").length;
          final doneCount = done.length;
          final skippedCount = skipped.length;
          
          // Combine regular habits with project tasks for display
          // Project tasks will be shown as additional tasks for that date
          
          final displayHabits = _selectedFilter == "To-dos" 
              ? todos 
              : _selectedFilter == "Done" 
                  ? done 
                  : skipped;

          return Column(
            children: [
              // Header section with stats, day counter, and task filters
              // Use separate counts that exclude pending deletion tasks from todos count
              _buildNewHeaderSection(controller, todosCount, doneCount, skippedCount, _selectedDate),
              
              // Tasks list with rounded top accent
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF2A4A6F),
                        const Color(0xFF365A7F),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: displayHabits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_selectedFilter == "To-dos" && todos.isEmpty && done.isNotEmpty) ...[
                              // All tasks completed message
                              const Icon(
                                Icons.check_circle,
                                size: 64,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'You have finished all tasks for this day.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              // No tasks message
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
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 16,
                          bottom: MediaQuery.of(context).padding.bottom + 100, // Account for bottom nav bar
                        ),
                        itemCount: displayHabits.length,
                        itemBuilder: (context, index) {
                          final habit = displayHabits[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildNewTaskCard(
                              habit: habit,
                              controller: controller,
                              context: context,
                            ),
                          );
                        },
                      ),
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  // ✅ When user taps on a habit card - always navigate to detail screen
  void _handleHabitTap(BuildContext context, HabitModel habit, TasksController controller) async {
    await Navigator.pushNamed(
      context, 
      '/task_detail', 
      arguments: {
        'habit': habit,
        'viewDate': _selectedDate, // Pass the selected date
      },
    );
    
    // Reload habits when returning from detail screen to get latest deletionStatus
    if (mounted) {
      await controller.reloadHabits();
    }
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


  Widget _buildNewHeaderSection(TasksController controller, int todosCount, int doneCount, int skippedCount, DateTime selectedDate) {
    return Consumer3<ProgressController, MilestoneController, AchievementsController>(
      builder: (context, progressController, milestoneController, achievementsController, child) {
        final journeyController = context.read<JourneyController>();
        final overallProgress = progressController.overallProgress;
        
        // Calculate day number for selected date
        final dayNumber = _calculateDayNumber(selectedDate, milestoneController, journeyController);
        
        // Get real achievements count
        final achievementsCount = achievementsController.unlockedCount;
        final successRate = (overallProgress * 100).toInt();

        // Calculate current streak and selected date's task completion
        final streakInfo = _calculateCurrentStreak(controller.habits);
        final currentStreak = streakInfo['streak'] as int;
        
        // Calculate tasks completed for selected date
        final selectedDateTasksCompleted = controller.habits
            .where((h) => h.isCompletedForDate(selectedDate))
            .length;
        
        // Determine color based on selected date's task completion
        Color streakColor = Colors.grey;
        if (selectedDateTasksCompleted >= 7) {
          streakColor = Colors.red;
        } else if (selectedDateTasksCompleted >= 6) {
          streakColor = Colors.orange;
        } else if (selectedDateTasksCompleted >= 5) {
          streakColor = Colors.green;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1E3A5F),
                const Color(0xFF2A4A6F),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                              color: AppColors.accentAmber,
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
                              color: AppColors.accentBlue,
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
                        icon: Icon(
                          Icons.settings,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Day counter with navigation - cleaner design
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Previous day button
                      IconButton(
                        onPressed: _canGoToPreviousDay ? _goToPreviousDay : null,
                        icon: Icon(
                          Icons.chevron_left,
                          color: _canGoToPreviousDay ? AppColors.textPrimary : AppColors.textTertiary,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      // Day counter - tappable to open date picker (flexible size)
                      Expanded(
                        child: GestureDetector(
                        onTap: () => _showDatePicker(context, controller),
                          child: _buildDateDisplay(selectedDate),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Next day button
                      IconButton(
                        onPressed: _goToNextDay,
                        icon: Icon(
                          Icons.chevron_right,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Motivational message
                  Text(
                    _getMotivationalMessage(dayNumber, selectedDate),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
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
                          width: 56,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: AppColors.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppColors.textPrimary,
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              "$label ($count)",
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
    // Get attribute from habit (from database) or determine it
    final attribute = habit.attribute ?? AttributeUtils.determineAttribute(
      title: habit.title,
      description: habit.description,
      category: '', // HabitModel doesn't have category, use empty string
    );
    
    // Get background gradient and color using centralized utility
    final gradientColors = AttributeUtils.getAttributeGradient(attribute);
    final attributeColor = AttributeUtils.getAttributeColor(attribute);
    
    // Determine frequency/source text
    String frequency;
    final metadata = habit.metadata;
    final taskType = metadata['type'] as String?;
    
    if (taskType == 'project') {
      // Show project name for project tasks
      frequency = metadata['projectTitle'] as String? ?? 'Project Task';
    } else if (taskType == 'plan') {
      // Show plan name for plan tasks
      frequency = metadata['planTitle'] as String? ?? 'Plan Task';
    } else if (taskType == 'workout') {
      // Show workout plan name for workout tasks
      frequency = metadata['planTitle'] as String? ?? 'Workout';
    } else {
      // Regular tasks show "Everyday" or actual schedule
      if (habit.daysOfWeek.isEmpty && habit.specificDate != null) {
        // Single date task - show date or "One-time"
        frequency = "One-time";
      } else if (habit.daysOfWeek.length == 7) {
        frequency = "Everyday";
      } else if (habit.daysOfWeek.isEmpty) {
        frequency = "Scheduled";
      } else {
        frequency = "Everyday"; // Default fallback
      }
    }

    return GestureDetector(
      onTap: () => _handleHabitTap(context, habit, controller),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors[0],
              gradientColors[1],
              gradientColors[0].withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: attributeColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: AppDesignSystem.getColoredShadow(attributeColor),
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
                            // Attribute color indicator
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
                                habit.title,
                                style: AppTextStyles.h3.copyWith(
                                  color: Colors.white,
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
                            // Pending deletion indicator - more visible
                            if (habit.deletionStatus == "pending")
                              Tooltip(
                                message: "Deletion request pending",
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.orange,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
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
