import 'package:flutter/material.dart';
import 'package:recalim/core/theme/app_colors.dart';
import 'package:recalim/core/theme/app_design_system.dart';
import '../../../projects/presentation/screens/plans_list_screen.dart';
import 'screen_blocker_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Tools",
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppDesignSystem.lightBackgroundGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
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
          child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tap the tool to start a session",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            // Tools Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                _buildToolCard(
                  context: context,
                  title: "Meditation",
                  subtitle: "Guided sessions with human voice",
                  gradient: [const Color(0xFF6B4E71), const Color(0xFF8B6F8F)],
                  icon: Icons.self_improvement,
                ),
                _buildToolCard(
                  context: context,
                  title: "Book Summary",
                  subtitle: "Key insights from books",
                  gradient: [const Color(0xFF8E44AD), const Color(0xFFA569BD)],
                  icon: Icons.menu_book,
                  onTap: () {
                    Navigator.pushNamed(context, '/book_summary_list');
                  },
                ),
                _buildToolCard(
                  context: context,
                  title: "Screen Blocker",
                  subtitle: "Control app usage",
                  gradient: [const Color(0xFF34495E), const Color(0xFF5D6D7E)],
                  icon: Icons.phone_android,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScreenBlockerScreen(),
                      ),
                    );
                  },
                ),
                _buildToolCard(
                  context: context,
                  title: "Pomodoro",
                  subtitle: "Focus timer",
                  gradient: [const Color(0xFFE74C3C), const Color(0xFFEC7063)],
                  icon: Icons.timer,
                ),
                _buildToolCard(
                  context: context,
                  title: "Workout Counter",
                  subtitle: "Track your workouts",
                  gradient: [const Color(0xFFFF6B35), const Color(0xFFFF8C5A)],
                  icon: Icons.fitness_center,
                  onTap: () {
                    Navigator.pushNamed(context, '/workout_counter');
                  },
                ),
                _buildToolCard(
                  context: context,
                  title: "Project Planner",
                  subtitle: "AI-assisted project planning",
                  gradient: [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
                  icon: Icons.rocket_launch,
                  onTap: () {
                    Navigator.pushNamed(context, '/create_project');
                  },
                ),
                _buildToolCard(
                  context: context,
                  title: "View Plans",
                  subtitle: "See your project roadmaps",
                  gradient: [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
                  icon: Icons.map_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlansListScreen(),
                      ),
                    );
                  },
                ),
                _buildToolCard(
                  context: context,
                  title: "Workout AI",
                  subtitle: "Personalized fitness plans",
                  gradient: [const Color(0xFFFF6B35), const Color(0xFFFF8C5A)],
                  icon: Icons.fitness_center,
                  onTap: () {
                    Navigator.pushNamed(context, '/workout_setup');
                  },
                ),
                _buildToolCard(
                  context: context,
                  title: "Diet Plan AI",
                  subtitle: "Personalized meal plans",
                  gradient: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
                  icon: Icons.restaurant_menu,
                  onTap: () {
                    Navigator.pushNamed(context, '/diet_setup');
                  },
                ),
                _buildNewToolCard(context),
              ],
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$title tool coming soon! 🛠️"),
            backgroundColor: Colors.orange,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
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
            // Decorative overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildNewToolCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              "Suggest a Tool",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Have an idea for a new tool? Let us know!\n\nEmail: tools@reclaim.app",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.people_outline,
              color: Colors.white54,
              size: 24,
            ),
            const SizedBox(height: 16),
            const Text(
              "Would you like a new tool?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Send a suggestion",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

