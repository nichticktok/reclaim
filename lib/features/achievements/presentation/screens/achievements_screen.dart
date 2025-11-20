import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/achievements_controller.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _achievementCategories = [
    {'id': 'All', 'name': 'All Achievements', 'icon': Icons.stars},
    {'id': 'EarlyRiser', 'name': 'Early Riser', 'icon': Icons.wb_sunny},
    {'id': 'Fitness', 'name': 'Fitness', 'icon': Icons.fitness_center},
    {'id': 'Mindfulness', 'name': 'Mindfulness', 'icon': Icons.self_improvement},
    {'id': 'Learning', 'name': 'Learning', 'icon': Icons.school},
    {'id': 'Health', 'name': 'Health', 'icon': Icons.local_drink},
    {'id': 'Consistency', 'name': 'Consistency', 'icon': Icons.trending_up},
  ];

  final List<Map<String, dynamic>> _predefinedAchievements = [
    // Early Riser Category
    {
      'id': 'early_riser_7',
      'category': 'EarlyRiser',
      'title': 'Early Riser',
      'description': 'Wake up early for 7 days straight',
      'icon': '🌅',
      'days': 7,
      'color': Colors.orange,
    },
    {
      'id': 'early_riser_14',
      'category': 'EarlyRiser',
      'title': 'Dawn Warrior',
      'description': 'Wake up early for 14 days straight',
      'icon': '⚡',
      'days': 14,
      'color': Colors.deepOrange,
    },
    {
      'id': 'early_riser_30',
      'category': 'EarlyRiser',
      'title': 'Sunrise Master',
      'description': 'Wake up early for 30 days straight',
      'icon': '👑',
      'days': 30,
      'color': Colors.amber,
    },
    // Fitness Category
    {
      'id': 'fitness_7',
      'category': 'Fitness',
      'title': 'Week Warrior',
      'description': 'Exercise for 7 days straight',
      'icon': '💪',
      'days': 7,
      'color': Colors.red,
    },
    {
      'id': 'fitness_14',
      'category': 'Fitness',
      'title': 'Fitness Champion',
      'description': 'Exercise for 14 days straight',
      'icon': '🏆',
      'days': 14,
      'color': Colors.deepOrange,
    },
    {
      'id': 'fitness_30',
      'category': 'Fitness',
      'title': 'Iron Will',
      'description': 'Exercise for 30 days straight',
      'icon': '🔥',
      'days': 30,
      'color': Colors.orange,
    },
    // Mindfulness Category
    {
      'id': 'mindfulness_7',
      'category': 'Mindfulness',
      'title': 'Zen Beginner',
      'description': 'Meditate for 7 days straight',
      'icon': '🧘',
      'days': 7,
      'color': Colors.purple,
    },
    {
      'id': 'mindfulness_14',
      'category': 'Mindfulness',
      'title': 'Mindful Master',
      'description': 'Meditate for 14 days straight',
      'icon': '✨',
      'days': 14,
      'color': Colors.deepPurple,
    },
    {
      'id': 'mindfulness_30',
      'category': 'Mindfulness',
      'title': 'Enlightened One',
      'description': 'Meditate for 30 days straight',
      'icon': '🕉️',
      'days': 30,
      'color': Colors.indigo,
    },
    // Learning Category
    {
      'id': 'learning_7',
      'category': 'Learning',
      'title': 'Bookworm',
      'description': 'Read for 7 days straight',
      'icon': '📚',
      'days': 7,
      'color': Colors.blue,
    },
    {
      'id': 'learning_14',
      'category': 'Learning',
      'title': 'Knowledge Seeker',
      'description': 'Read for 14 days straight',
      'icon': '📖',
      'days': 14,
      'color': Colors.lightBlue,
    },
    {
      'id': 'learning_30',
      'category': 'Learning',
      'title': 'Scholar',
      'description': 'Read for 30 days straight',
      'icon': '🎓',
      'days': 30,
      'color': Colors.cyan,
    },
    // Health Category
    {
      'id': 'health_7',
      'category': 'Health',
      'title': 'Hydration Hero',
      'description': 'Stay hydrated for 7 days straight',
      'icon': '💧',
      'days': 7,
      'color': Colors.blue,
    },
    {
      'id': 'health_14',
      'category': 'Health',
      'title': 'Aqua Master',
      'description': 'Stay hydrated for 14 days straight',
      'icon': '🌊',
      'days': 14,
      'color': Colors.lightBlue,
    },
    {
      'id': 'health_30',
      'category': 'Health',
      'title': 'Water Warrior',
      'description': 'Stay hydrated for 30 days straight',
      'icon': '🏊',
      'days': 30,
      'color': Colors.cyan,
    },
    // Consistency Category
    {
      'id': 'consistency_7',
      'category': 'Consistency',
      'title': 'Week Warrior',
      'description': 'Complete any task for 7 days straight',
      'icon': '🎯',
      'days': 7,
      'color': Colors.green,
    },
    {
      'id': 'consistency_14',
      'category': 'Consistency',
      'title': 'Consistency King',
      'description': 'Complete any task for 14 days straight',
      'icon': '👑',
      'days': 14,
      'color': Colors.teal,
    },
    {
      'id': 'consistency_30',
      'category': 'Consistency',
      'title': 'Habit Master',
      'description': 'Complete any task for 30 days straight',
      'icon': '🌟',
      'days': 30,
      'color': Colors.lightGreen,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchievementsController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AchievementsController>(
        builder: (context, controller, child) {
          if (controller.loading && controller.achievements.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          // Filter achievements by category
          final filteredAchievements = _selectedCategory == 'All'
              ? _predefinedAchievements
              : _predefinedAchievements
                  .where((a) => a['category'] == _selectedCategory)
                  .toList();

          return Column(
            children: [
              // Category tabs
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _achievementCategories.length,
                  itemBuilder: (context, index) {
                    final category = _achievementCategories[index];
                    final isSelected = _selectedCategory == category['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = category['id'] as String),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category['icon'] as IconData,
                                color: isSelected ? Colors.black : Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category['name'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Achievements grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredAchievements.length,
                  itemBuilder: (context, index) {
                    final achievement = filteredAchievements[index];
                    final isUnlocked = _isAchievementUnlocked(controller, achievement);
                    return _buildAchievementCard(achievement, isUnlocked, controller);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isAchievementUnlocked(AchievementsController controller, Map<String, dynamic> achievement) {
    // Check if user has unlocked this achievement
    return controller.unlockedAchievements.any((a) =>
        a.requiredDays == achievement['days'] &&
        _matchesCategory(a.taskTitle, achievement['category'] as String));
  }

  bool _matchesCategory(String taskTitle, String category) {
    final titleLower = taskTitle.toLowerCase();
    switch (category) {
      case 'EarlyRiser':
        return titleLower.contains('wake') || titleLower.contains('6') || titleLower.contains('morning');
      case 'Fitness':
        return titleLower.contains('exercise') || titleLower.contains('workout') || titleLower.contains('gym');
      case 'Mindfulness':
        return titleLower.contains('meditate') || titleLower.contains('meditation');
      case 'Learning':
        return titleLower.contains('read') || titleLower.contains('book');
      case 'Health':
        return titleLower.contains('water') || titleLower.contains('drink');
      case 'Consistency':
        return true; // Any task matches consistency
      default:
        return false;
    }
  }

  Widget _buildAchievementCard(
    Map<String, dynamic> achievement,
    bool isUnlocked,
    AchievementsController controller,
  ) {
    final color = achievement['color'] as Color;
    final icon = achievement['icon'] as String;
    final title = achievement['title'] as String;
    final description = achievement['description'] as String;
    final days = achievement['days'] as int;

    // Get progress for this achievement
    final progress = _getAchievementProgress(controller, achievement);

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked
            ? color.withValues(alpha: 0.2)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? color : Colors.white.withValues(alpha: 0.1),
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Text(
            icon,
            style: TextStyle(
              fontSize: 48,
              color: isUnlocked ? null : Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            title,
            style: TextStyle(
              color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              description,
              style: TextStyle(
                color: isUnlocked
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          // Progress indicator (if in progress)
          if (!isUnlocked && progress > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * days).toInt()}/$days days',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            )
          else if (isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'UNLOCKED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _getAchievementProgress(AchievementsController controller, Map<String, dynamic> achievement) {
    final days = achievement['days'] as int;
    final category = achievement['category'] as String;

    // Find matching in-progress achievements
    final matchingAchievements = controller.inProgressAchievements.where((a) {
      return a.requiredDays == days && _matchesCategory(a.taskTitle, category);
    }).toList();

    if (matchingAchievements.isEmpty) return 0.0;

    // Return the highest progress
    return matchingAchievements.map((a) => a.progress).reduce((a, b) => a > b ? a : b);
  }
}

