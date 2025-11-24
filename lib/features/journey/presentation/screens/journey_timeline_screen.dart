import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../../../milestone/presentation/controllers/milestone_controller.dart';
import '../controllers/journey_controller.dart';
import 'daily_journey_screen.dart';

/// Journey Timeline Screen
/// Shows timeline view with 30 days, mood tracking, tasks, and journal entries
class JourneyTimelineScreen extends StatefulWidget {
  const JourneyTimelineScreen({super.key});

  @override
  State<JourneyTimelineScreen> createState() => _JourneyTimelineScreenState();
}

class _JourneyTimelineScreenState extends State<JourneyTimelineScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final journeyController = context.read<JourneyController>();
      final milestoneController = context.read<MilestoneController>();
      
      journeyController.initialize().then((_) {
        // Get total days from milestone controller
        final totalDays = milestoneController.getTotalDays();
        journeyController.loadAllDayEntries(totalDays: totalDays);
      });
      
      context.read<TasksController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Journey",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.wb_sunny,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer3<JourneyController, MilestoneController, TasksController>(
        builder: (context, journeyController, milestoneController, tasksController, child) {
          if (journeyController.loading && journeyController.dayEntries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          final currentDay = journeyController.currentDay;
          final totalDays = milestoneController.getTotalDays();
          final startDate = journeyController.journeyStartDate ?? DateTime.now();
          final today = DateTime.now();
          
          // Get today's tasks completion status
          final todayHabits = tasksController.habits
              .where((habit) => habit.isScheduledForDate(today))
              .toList();
          final completedTasksCount = todayHabits.where((h) => h.isCompletedToday()).length;
          final totalTasksCount = todayHabits.length;
          final allTasksCompleted = totalTasksCount > 0 && completedTasksCount == totalTasksCount;

          return Column(
              children: [
              // Progress Header
              _buildProgressHeader(currentDay, totalDays),
              
              // Completion message for today (if all tasks completed)
              if (allTasksCompleted)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade600,
                        Colors.green.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You completed $completedTasksCount task${completedTasksCount == 1 ? '' : 's'}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'How are you feeling?',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Timeline View
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: totalDays,
                  itemBuilder: (context, index) {
                    final dayNumber = index + 1;
                    final dayDate = startDate.add(Duration(days: dayNumber - 1));
                    final isCompleted = dayNumber < currentDay;
                    // Check if this day is actually today (not just current day in journey)
                    final isToday = dayDate.year == today.year && 
                                   dayDate.month == today.month && 
                                   dayDate.day == today.day;
                    final isCurrent = dayNumber == currentDay || isToday;
                    final isFuture = dayNumber > currentDay && !isToday;
                    
                    final dayEntry = journeyController.dayEntries[dayNumber];
                    final mood = dayEntry?['mood'] as String?;
                    final hasJournal = dayEntry?['journalEntry'] != null && 
                                      (dayEntry?['journalEntry'] as String).isNotEmpty;

                    return _buildDayEntry(
                      dayNumber: dayNumber,
                      date: dayDate,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      isToday: isToday,
                      isFuture: isFuture,
                      mood: mood,
                      hasJournal: hasJournal,
                      journeyController: journeyController,
                      totalDays: totalDays,
                      showConnector: index < totalDays - 1,
                      allTasksCompleted: isToday ? allTasksCompleted : false,
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

  Widget _buildProgressHeader(int currentDay, int totalDays) {
    final progress = (currentDay / totalDays).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day $currentDay of $totalDays',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% Complete',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Text(
                  '${totalDays - currentDay + 1} days left',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayEntry({
    required int dayNumber,
    required DateTime date,
    required bool isCompleted,
    required bool isCurrent,
    required bool isToday,
    required bool isFuture,
    String? mood,
    required bool hasJournal,
    required JourneyController journeyController,
    required int totalDays,
    required bool showConnector,
    bool allTasksCompleted = false,
  }) {
    return InkWell(
      onTap: () {
        // Navigate to daily journey screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyJourneyScreen(dayNumber: dayNumber),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
                  width: 48,
                  height: 48,
              decoration: BoxDecoration(
                    color: isToday
                        ? Colors.orange
                        : isCurrent
                            ? Colors.orange.withValues(alpha: 0.7)
                            : isCompleted
                                ? Colors.green
                                : Colors.grey.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(
                color: isToday ? Colors.orange : Colors.white,
                      width: isToday ? 3 : 2,
                    ),
                    boxShadow: isToday ? [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : isToday
                            ? const Icon(Icons.wb_sunny, color: Colors.white, size: 24)
                            : isCurrent
                                ? const Icon(Icons.wb_sunny, color: Colors.white, size: 20)
                                : Text(
                                    '$dayNumber',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                    ),
                  ),
                ),
                if (showConnector)
                  Container(
                    width: 2,
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isCompleted
                              ? Colors.green
                              : isCurrent
                                  ? Colors.orange
                                  : Colors.grey.shade700,
                          dayNumber + 1 <= totalDays
                              ? (dayNumber + 1 == journeyController.currentDay
                                  ? Colors.orange
                                  : dayNumber + 1 < journeyController.currentDay
                                      ? Colors.green
                                      : Colors.grey.shade700)
                              : Colors.grey.shade700,
                        ],
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Day content
        Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.orange.withValues(alpha: 0.15)
                      : isCurrent
                          ? Colors.orange.withValues(alpha: 0.1)
                          : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday
                        ? Colors.orange
                        : isCurrent
                            ? Colors.orange.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.1),
                    width: isToday ? 2 : isCurrent ? 1.5 : 1,
                  ),
                  boxShadow: isToday ? [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_getMonthName(date.month)} ${date.day}, ${date.year}",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Day $dayNumber",
                              style: TextStyle(
                                color: isToday ? Colors.orange : isCurrent ? Colors.orange.withValues(alpha: 0.8) : Colors.white,
                                fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
                          ],
                        ),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
      decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
      ),
                            child: const Text(
                              'Today',
            style: TextStyle(
              color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
            ),
          ),
                          )
                        else if (isCompleted)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Completion message for today
                    if (isToday && allTasksCompleted) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'All tasks completed! How are you feeling?',
                                style: TextStyle(
                                  color: Colors.green.shade100,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Mood indicator
                    if (mood != null)
                      Row(
                        children: [
                          Text(
                      mood,
                      style: const TextStyle(fontSize: 24),
                    ),
                          const SizedBox(width: 8),
                          Text(
                            _getMoodText(mood),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
      ),
                        ],
                      )
                    else if (!isFuture)
                      Text(
                        'No mood recorded',
            style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
            ),
          ),
                    if (hasJournal) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.book,
                            color: Colors.orange,
                            size: 16,
                ),
                          const SizedBox(width: 4),
                          Text(
                            'Journal entry saved',
            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
            ),
          ),
        ],
      ),
                    ],
                    if (isFuture)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Coming soon...',
            style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodText(String mood) {
    switch (mood) {
      case '😊':
        return 'Happy';
      case '😄':
        return 'Very Happy';
      case '😌':
        return 'Peaceful';
      case '😐':
        return 'Neutral';
      case '😔':
        return 'Sad';
      case '😢':
        return 'Very Sad';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}