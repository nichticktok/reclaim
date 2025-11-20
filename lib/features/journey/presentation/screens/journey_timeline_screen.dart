import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../controllers/journey_controller.dart';

/// Journey Timeline Screen
/// Shows timeline view with multiple days, mood tracking, tasks, and journal entries
class JourneyTimelineScreen extends StatefulWidget {
  const JourneyTimelineScreen({super.key});

  @override
  State<JourneyTimelineScreen> createState() => _JourneyTimelineScreenState();
}

class _JourneyTimelineScreenState extends State<JourneyTimelineScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize controllers only once - they check internally if already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JourneyController>().initialize();
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
      body: Consumer<JourneyController>(
        builder: (context, journeyController, child) {
          if (journeyController.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          final currentDay = journeyController.currentDay;
          final tasksController = context.read<TasksController>();
          final tasks = tasksController.habits;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day 1 (Completed)
                _buildDayEntry(
                  dayNumber: 1,
                  date: DateTime.now().subtract(const Duration(days: 1)),
                  isCompleted: true,
                  journeyController: journeyController,
                  tasks: tasks,
                ),
                const SizedBox(height: 32),
                // Day 2 (Current)
                _buildDayEntry(
                  dayNumber: currentDay,
                  date: DateTime.now(),
                  isCompleted: false,
                  journeyController: journeyController,
                  tasks: tasks,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayEntry({
    required int dayNumber,
    required DateTime date,
    required bool isCompleted,
    required JourneyController journeyController,
    required List tasks,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.orange : Colors.grey.shade700,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.wb_sunny,
                color: Colors.white,
                size: 24,
              ),
            ),
            if (dayNumber == 1) // Only show dotted line between days
              Container(
                width: 2,
                height: 100,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: CustomPaint(
                  painter: DottedLinePainter(),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Day content
        Expanded(
          child: Column(
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Mood card
              _buildMoodCard(dayNumber, journeyController),
              const SizedBox(height: 12),
              // Tasks card
              _buildTasksCard(tasks),
              const SizedBox(height: 12),
              // Visual journey card
              _buildVisualJourneyCard(dayNumber),
              const SizedBox(height: 12),
              // Text entry card
              _buildTextEntryCard(dayNumber, journeyController),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodCard(int dayNumber, JourneyController controller) {
    final moods = ['😊', '😄', '😌', '😐', '😔', '😢'];
    final currentMood = dayNumber == controller.currentDay ? controller.currentMood : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How are you feeling today?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: moods.map((mood) {
              final isSelected = currentMood == mood;
              return GestureDetector(
                onTap: () {
                  if (dayNumber == controller.currentDay) {
                    controller.saveMood(mood);
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      mood,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard(List tasks) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tasks",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: tasks.take(5).map((task) {
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getTaskIcon(task.title),
                  color: Colors.white54,
                  size: 24,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualJourneyCard(int dayNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "The visual journey",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Media picker coming soon! 📸"),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
              label: const Text(
                "Add Media",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextEntryCard(int dayNumber, JourneyController controller) {
    final isCurrentDay = dayNumber == controller.currentDay;
    final journalEntry = isCurrentDay ? controller.journalEntry : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Describe what you're feeling",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () {
                _showJournalEditor(context, controller, dayNumber);
              },
              icon: const Icon(Icons.text_fields, color: Colors.white),
              label: Text(
                journalEntry != null ? "Edit Text" : "Add Text",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJournalEditor(BuildContext context, JourneyController controller, int dayNumber) {
    final textController = TextEditingController(text: controller.journalEntry ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Journal Entry",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: textController,
            maxLines: 10,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Describe what you're feeling...",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = textController.text.trim();
              try {
                await controller.saveJournalEntry(text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Journal entry saved! ✍️"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error saving entry: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getTaskIcon(String taskTitle) {
    final title = taskTitle.toLowerCase();
    if (title.contains('wake') || title.contains('sleep')) {
      return Icons.wb_sunny;
    } else if (title.contains('water') || title.contains('drink')) {
      return Icons.water_drop;
    } else if (title.contains('exercise') || title.contains('workout')) {
      return Icons.fitness_center;
    } else if (title.contains('meditate')) {
      return Icons.self_improvement;
    } else if (title.contains('read')) {
      return Icons.menu_book;
    } else if (title.contains('shower')) {
      return Icons.shower;
    }
    return Icons.task;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2;

    const dashHeight = 4;
    const dashSpace = 4;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

