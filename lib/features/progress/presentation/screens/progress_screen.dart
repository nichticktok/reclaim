import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recalim/core/models/habit_model.dart';
import 'package:recalim/core/theme/app_colors.dart';
import 'package:recalim/core/theme/app_design_system.dart';
import '../../../../core/utils/attribute_utils.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../controllers/progress_controller.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedCategory = "All";
  String _lastHabitsHash = ""; // Track last habits state to detect changes

  @override
  void initState() {
    super.initState();
    // Initialize controllers only once - they check internally if already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressController>().initialize();
      context.read<TasksController>().initialize();
    });
  }
  
  /// Create a hash of habits state (IDs + completion status) to detect changes
  String _getHabitsHash(List<dynamic> habits) {
    final hash = habits.map((h) => '${h.id}:${h.isCompletedToday()}').join('|');
    return hash;
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
        child: Consumer2<ProgressController, TasksController>(
          builder: (context, progressController, tasksController, child) {
            // Only show loading if we have no data yet
            if ((progressController.loading && progressController.currentProgress == null) ||
                (tasksController.loading && tasksController.habits.isEmpty)) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

          final allHabits = tasksController.habits;
          
          // Filter habits to show only today's items (for most categories)
          final today = DateTime.now();
          final todayHabits = allHabits
              .where((habit) => habit.isScheduledForDate(today))
              .toList();
          
          // ALWAYS calculate progress based on "All" category (today's habits)
          // This ensures the top status (33% done, days active) doesn't change when switching categories
          final currentHabitsHash = _getHabitsHash(todayHabits);
          final habitsChanged = currentHabitsHash != _lastHabitsHash;
          
          if (todayHabits.isNotEmpty && habitsChanged) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                progressController.calculateProgressFromTasks(todayHabits);
                setState(() {
                  _lastHabitsHash = currentHabitsHash;
                });
              }
            });
          }
          
          final overallProgress = progressController.overallProgress;
          final currentStreak = progressController.currentStreak;

          // Calculate days active and progress percentage (always based on "All")
          final daysActive = currentStreak;
          final progressPercent = (overallProgress * 100).toInt();

          // Determine status and color based on progress (always based on "All")
          final statusInfo = _getStatusInfo(progressPercent, daysActive);
          
          // Determine which habits to use for display based on category
          // Sleep, Water, and Exercise show ALL habits (not just today)
          // Other categories show only today's habits
          final bool showAllHabits = _selectedCategory == "Sleep" || 
                                     _selectedCategory == "Water" || 
                                     _selectedCategory == "Exercise";
          
          final habitsToUse = showAllHabits ? allHabits : todayHabits;

          // Filter habits by category
          // For Sleep, Water, Exercise, Meditation, Reading: show only completed tasks
          // For "All" category: show only today's habits
          final filteredHabits = _selectedCategory == "All"
              ? (showAllHabits ? allHabits : todayHabits)
              : habitsToUse.where((h) {
                  final title = h.title.toLowerCase();
                  bool matchesCategory = false;
                  
                  switch (_selectedCategory) {
                    case "Sleep":
                      matchesCategory = title.contains('wake') || title.contains('sleep');
                      break;
                    case "Water":
                      matchesCategory = title.contains('water') || title.contains('drink');
                      break;
                    case "Exercise":
                      matchesCategory = title.contains('exercise') || title.contains('workout');
                      break;
                    case "Meditation":
                      matchesCategory = title.contains('meditate');
                      break;
                    case "Reading":
                      matchesCategory = title.contains('read');
                      break;
                    default:
                      matchesCategory = true;
                  }
                  
                  // For Sleep, Water, Exercise, Meditation, Reading: only show completed tasks
                  if (matchesCategory && (_selectedCategory == "Sleep" || 
                                          _selectedCategory == "Water" || 
                                          _selectedCategory == "Exercise" ||
                                          _selectedCategory == "Meditation" ||
                                          _selectedCategory == "Reading")) {
                    // Check if task is completed (for today if it's a today habit, or any date if showing all)
                    if (showAllHabits) {
                      // For all habits, check if it's been completed at least once (any date)
                      return h.dailyCompletion.isNotEmpty;
                    } else {
                      // For today's habits, check if completed today
                      return h.isCompletedToday();
                    }
                  }
                  
                  return matchesCategory;
                }).toList();

          // Check if procrastination button should be shown
          final shouldShowProcrastination = _shouldShowProcrastinationButton(_selectedCategory, filteredHabits, todayHabits);
          
          return Column(
            children: [
              // Dynamic color header section with timer and status
              _buildHeaderSection(
                daysActive: daysActive,
                progressPercent: progressPercent,
                statusInfo: statusInfo,
                showProcrastinationButton: shouldShowProcrastination,
              ),

              // "Your Improvements" section with category tabs
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
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildImprovementsHeader(),
                      const SizedBox(height: 12),
                      _buildCategoryTabs(),
                      const SizedBox(height: 12),
                      // Improvement cards list
                      Expanded(
                        child: filteredHabits.isEmpty
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
                                    const Text(
                                      'No improvements yet',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filteredHabits.length,
                                itemBuilder: (context, index) {
                                  final habit = filteredHabits[index];
                                  return _buildImprovementCard(habit);
                                },
                              ),
                      ),
                    ],
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

  /// Get status information based on progress percentage
  Map<String, dynamic> _getStatusInfo(int progressPercent, int daysActive) {
    if (progressPercent >= 100) {
      return {
        'status': 'COMPLETE',
        'color': Colors.green,
        'icon': Icons.check_circle_rounded,
        'message': 'Good Job! You have completed all the tasks. If you want to do more, let\'s try it!',
      };
    } else if (progressPercent >= 80) {
      return {
        'status': 'EXCELLENT',
        'color': _interpolateColor(Colors.orange, Colors.green, (progressPercent - 80) / 20),
        'icon': Icons.star_rounded,
        'message': '$daysActive days active, $progressPercent% done. You\'re almost there!',
      };
    } else if (progressPercent >= 50) {
      return {
        'status': 'GOOD',
        'color': Colors.orange,
        'icon': Icons.trending_up_rounded,
        'message': '$daysActive days active, $progressPercent% done. Keep going!',
      };
    } else if (progressPercent >= 25) {
      return {
        'status': 'GETTING THERE',
        'color': _interpolateColor(Colors.red, Colors.orange, (progressPercent - 25) / 25),
        'icon': Icons.warning_rounded,
        'message': '$daysActive days active, $progressPercent% done. Come back and lock in!',
      };
    } else {
      return {
        'status': 'DANGEROUS',
        'color': Colors.red,
        'icon': Icons.warning_rounded,
        'message': '$daysActive days active, $progressPercent% done. Come back and lock in!',
      };
    }
  }

  /// Interpolate between two colors based on progress
  Color _interpolateColor(Color start, Color end, double t) {
    t = t.clamp(0.0, 1.0);
    return Color.fromRGBO(
      ((start.r + (end.r - start.r) * t) * 255.0).round().clamp(0, 255),
      ((start.g + (end.g - start.g) * t) * 255.0).round().clamp(0, 255),
      ((start.b + (end.b - start.b) * t) * 255.0).round().clamp(0, 255),
      (start.a + (end.a - start.a) * t).clamp(0.0, 1.0),
    );
  }

  Widget _buildHeaderSection({
    required int daysActive,
    required int progressPercent,
    required Map<String, dynamic> statusInfo,
    bool showProcrastinationButton = false,
  }) {
    // Calculate timer (mock for now - can be connected to actual program start time)
    final now = DateTime.now();
    final hours = now.hour;
    final minutes = now.minute;
    final seconds = now.second;
    final timerText = "${hours}hr ${minutes}m ${seconds.toString().padLeft(2, '0')}s";

    final statusColor = statusInfo['color'] as Color;
    final status = statusInfo['status'] as String;
    final icon = statusInfo['icon'] as IconData;
    final message = statusInfo['message'] as String;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              statusColor,
              statusColor.withOpacity(0.9),
              statusColor.withOpacity(0.7),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer section
              const Text(
                "You have started your Reclaim journey for",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timerText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Status indicator and procrastination button
              // Use responsive layout: stack on small screens, side-by-side on large screens
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;
                  
                  if (isSmallScreen) {
                    // Stack vertically on small screens (iPhone)
                    return Column(
                      children: [
                        // Status indicator
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      message,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 10,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Procrastination button (if applicable)
                        if (showProcrastinationButton) ...[
                          const SizedBox(height: 12),
                          _buildProcrastinationButtonCompact(isCompact: true),
                        ],
                      ],
                    );
                  } else {
                    // Side-by-side on large screens (iPad)
                    return Row(
                      children: [
                        // Status indicator - more compact
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        message,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Procrastination button (if applicable)
                        if (showProcrastinationButton) ...[
                          const SizedBox(width: 12),
                          _buildProcrastinationButtonCompact(isCompact: false),
                        ],
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImprovementsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.arrow_upward,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            "Your Improvements",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ["All", "Sleep", "Water", "Exercise", "Meditation", "Reading"];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImprovementCard(HabitModel habit) {
    // Get attribute from habit (from database) or determine it
    final attribute = habit.attribute ?? AttributeUtils.determineAttribute(
      title: habit.title,
      description: habit.description,
      category: '', // HabitModel doesn't have category, use empty string
    );
    
    // Get background gradient and color using centralized utility
    final gradientColors = AttributeUtils.getAttributeGradient(attribute);
    final attributeColor = AttributeUtils.getAttributeColor(attribute);
    
    // Get quote based on attribute
    String getQuote() {
      switch (attribute) {
        case 'Wisdom':
          return "Knowledge is power.";
        case 'Confidence':
          return "Believe in yourself.";
        case 'Strength':
          return "Strength comes from consistency.";
        case 'Discipline':
          return "Early to bed, early to rise.";
        case 'Focus':
          return "The noble minds are calm, steady.";
        default:
          return "Stay consistent and grow";
      }
    }

    final quote = getQuote();
    final isCompleted = habit.isCompletedToday();

    // Remove tap functionality - users should not be able to view details or interact with tasks
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors[0],
              gradientColors[1],
              gradientColors[0].withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: attributeColor.withOpacity(0.3),
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
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon/Emoji indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _getCategoryIcon(habit.title),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              quote,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Completion indicator
                  if (isCompleted)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  /// Check if procrastination button should be shown
  /// Always show if there are incomplete tasks in "All" category, regardless of selected category
  bool _shouldShowProcrastinationButton(String category, List<HabitModel> habits, List<HabitModel> allTodayHabits) {
    // Always show if there are incomplete tasks in "All" category (today's habits)
    // This persists across all category selections
    return allTodayHabits.any((h) => !h.isCompletedToday() && !h.isSkippedToday());
  }

  /// Get icon for category based on habit title
  IconData _getCategoryIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('wake') || lowerTitle.contains('sleep')) {
      return Icons.bedtime_rounded;
    } else if (lowerTitle.contains('water') || lowerTitle.contains('drink')) {
      return Icons.water_drop_rounded;
    } else if (lowerTitle.contains('exercise') || lowerTitle.contains('workout')) {
      return Icons.fitness_center_rounded;
    } else if (lowerTitle.contains('meditate')) {
      return Icons.self_improvement_rounded;
    } else if (lowerTitle.contains('read')) {
      return Icons.menu_book_rounded;
    } else {
      return Icons.check_circle_outline_rounded;
    }
  }

  Widget _buildProcrastinationButtonCompact({bool isCompact = false}) {
    return GestureDetector(
      onTap: () {
        _showProcrastinationDialog(context);
      },
      child: Container(
        width: isCompact ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 10 : 12,
          horizontal: isCompact ? 14 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade600,
              Colors.red.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: isCompact ? 14 : 16,
              ),
            ),
            SizedBox(width: isCompact ? 8 : 8),
            Text(
              "I'm procrastinating",
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show motivational dialog when user acknowledges procrastination
  void _showProcrastinationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Acknowledging Procrastination",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "It takes courage to recognize when you're procrastinating. This is the first step toward getting back on track.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Remember:",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "• Progress, not perfection, is what matters\n• Every small step counts\n• You've already started by acknowledging this\n• Your future self will thank you",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        height: 1.4,
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
            child: const Text(
              'I\'ll Stay Here',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Got It - Let\'s Go!',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

}
