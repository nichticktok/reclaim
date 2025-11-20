import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/habit_model.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../controllers/progress_controller.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    // Initialize controllers only once - they check internally if already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressController>().initialize();
      context.read<TasksController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: Consumer2<ProgressController, TasksController>(
        builder: (context, progressController, tasksController, child) {
          // Only show loading if we have no data yet
          if ((progressController.loading && progressController.currentProgress == null) ||
              (tasksController.loading && tasksController.habits.isEmpty)) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          final overallProgress = progressController.overallProgress;
          final currentStreak = progressController.currentStreak;
          final habits = tasksController.habits;

          // Calculate days active and progress percentage
          final daysActive = currentStreak;
          final progressPercent = (overallProgress * 100).toInt();

          // Determine status based on progress
          String status = "DANGEROUS";
          if (overallProgress >= 0.8) {
            status = "EXCELLENT";
          } else if (overallProgress >= 0.5) {
            status = "GOOD";
          }

          // Filter habits by category
          final filteredHabits = _selectedCategory == "All"
              ? habits
              : habits.where((h) {
                  final title = h.title.toLowerCase();
                  switch (_selectedCategory) {
                    case "Sleep":
                      return title.contains('wake') || title.contains('sleep');
                    case "Water":
                      return title.contains('water') || title.contains('drink');
                    case "Exercise":
                      return title.contains('exercise') || title.contains('workout');
                    case "Meditation":
                      return title.contains('meditate');
                    case "Reading":
                      return title.contains('read');
                    default:
                      return true;
                  }
                }).toList();

          return Column(
            children: [
              // Orange-red header section with timer and status
              _buildHeaderSection(
                daysActive: daysActive,
                progressPercent: progressPercent,
                status: status,
              ),

              // "Your Improvements" section with category tabs
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D0D0F),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildImprovementsHeader(),
                      const SizedBox(height: 16),
                      _buildCategoryTabs(),
                      const SizedBox(height: 16),
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
                      // Procrastination button
                      if (filteredHabits.any((h) => !h.isCompletedToday()))
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildProcrastinationButton(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection({
    required int daysActive,
    required int progressPercent,
    required String status,
  }) {
    // Calculate timer (mock for now - can be connected to actual program start time)
    final now = DateTime.now();
    final hours = now.hour;
    final minutes = now.minute;
    final seconds = now.second;
    final timerText = "${hours}hr ${minutes}m ${seconds.toString().padLeft(2, '0')}s";

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFF6B35), // Orange-red
            const Color(0xFFFF6B35).withValues(alpha: 0.9),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Timer section
              const Text(
                "You have started a Life Reset for",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                timerText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$daysActive days active, $progressPercent% done. Come back and lock in!",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImprovementsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
    // Get appropriate background gradient and quote based on task type
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

    String getQuote() {
      final title = habit.title.toLowerCase();
      if (title.contains('meditate') || title.contains('meditation')) {
        return "The noble minds are calm, steady.";
      } else if (title.contains('water') || title.contains('drink')) {
        return "Stay hydrated, stay energised.";
      } else if (title.contains('exercise') || title.contains('workout')) {
        return "Strength comes from consistency.";
      } else if (title.contains('read') || title.contains('reading')) {
        return "Knowledge is power.";
      } else if (title.contains('wake') || title.contains('sleep')) {
        return "Early to bed, early to rise.";
      }
      return "Stay consistent and grow";
    }

    final gradient = getBackgroundGradient();
    final quote = getQuote();
    final isCompleted = habit.isCompletedToday();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/task_detail', arguments: habit);
      },
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              quote,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
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

  Widget _buildProcrastinationButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "I'm procrastinating",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
