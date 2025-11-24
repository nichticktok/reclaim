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
      body: Consumer2<JourneyController, MilestoneController>(
        builder: (context, journeyController, milestoneController, child) {
          if (journeyController.loading && journeyController.dayEntries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          final currentDay = journeyController.currentDay;
          final totalDays = milestoneController.getTotalDays();
          final startDate = journeyController.journeyStartDate ?? DateTime.now();

          return Column(
              children: [
              // Progress Header
              _buildProgressHeader(currentDay, totalDays),
              
              // Timeline View
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: totalDays,
                  itemBuilder: (context, index) {
                    final dayNumber = index + 1;
                    final dayDate = startDate.add(Duration(days: dayNumber - 1));
                    final isCompleted = dayNumber < currentDay;
                    final isCurrent = dayNumber == currentDay;
                    final isFuture = dayNumber > currentDay;
                    
                    final dayEntry = journeyController.dayEntries[dayNumber];
                    final mood = dayEntry?['mood'] as String?;
                    final hasJournal = dayEntry?['journalEntry'] != null && 
                                      (dayEntry?['journalEntry'] as String).isNotEmpty;

                    return _buildDayEntry(
                      dayNumber: dayNumber,
                      date: dayDate,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      isFuture: isFuture,
                      mood: mood,
                      hasJournal: hasJournal,
                  journeyController: journeyController,
                      totalDays: totalDays,
                      showConnector: index < totalDays - 1,
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
    required bool isFuture,
    String? mood,
    required bool hasJournal,
    required JourneyController journeyController,
    required int totalDays,
    required bool showConnector,
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
                    color: isCurrent
                        ? Colors.orange
                        : isCompleted
                            ? Colors.green
                            : Colors.grey.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(
                color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : isCurrent
                            ? const Icon(Icons.wb_sunny, color: Colors.white, size: 24)
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
                  color: isCurrent
                      ? Colors.orange.withValues(alpha: 0.1)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? Colors.orange
                        : Colors.white.withValues(alpha: 0.1),
                    width: isCurrent ? 2 : 1,
                  ),
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
                                color: isCurrent ? Colors.orange : Colors.white,
                                fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
                          ],
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
      decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
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