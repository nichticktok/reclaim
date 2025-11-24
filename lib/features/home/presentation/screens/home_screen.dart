import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recalim/core/models/user_model.dart';
import '../controllers/home_controller.dart';
import '../../../tasks/presentation/screens/daily_tasks_screen.dart';
import '../../../progress/presentation/screens/progress_screen.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/screens/sign_in_screen.dart';
import '../../../journey/presentation/screens/journey_timeline_screen.dart';
import '../../../tools/presentation/screens/tools_screen.dart';
import '../../../tools/presentation/controllers/screen_blocker_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Widget> _screens = [];
  bool _initialized = false;

  void _updateScreens(UserModel? user) {
    setState(() {
      _screens = [
        const DailyTasksScreen(), // Tasks/Improvements
        ProgressScreen(), // Progress/Stats
        const JourneyTimelineScreen(), // Journey/Timeline
        CommunityScreen(), // Community/Friends
        if (user != null) ProfileScreen(user: user) else const SizedBox(), // Profile
        const ToolsScreen(), // Tools
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        // Initialize controller on first build when context is available
        // Use addPostFrameCallback to avoid calling setState during build
        if (!_initialized) {
          _initialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.initialize().then((_) {
              if (mounted) {
                // Update screens after initialization completes
                if (controller.currentUser != null) {
                  _updateScreens(controller.currentUser);
                }
              }
            }).catchError((error) {
              debugPrint('Error initializing HomeController: $error');
            });
          });
        }

        if (controller.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.error != null) {
          final error = controller.error!;
          if (error.contains('permission-denied') || error.contains('No user')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => SignInScreen()),
              );
            });
          }
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $error'),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => SignInScreen()),
                    ),
                    child: const Text('Go to Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        // Update screens when user data is available (but not loading)
        if (!controller.loading && controller.currentUser != null && _screens.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _updateScreens(controller.currentUser);
            }
          });
        }

        // Show loading if screens not ready yet
        if (_screens.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Consumer<ScreenBlockerController>(
          builder: (context, blockerController, child) {
            return PopScope(
              canPop: !blockerController.isBlocked,
              child: Scaffold(
                extendBody: true,
                backgroundColor: Colors.grey.shade100,
                body: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _screens.isNotEmpty ? _screens[_selectedIndex] : const SizedBox(),
                ),
                bottomNavigationBar: _buildFloatingNavBar(blockerController.isBlocked),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFloatingNavBar(bool isBlocked) {
    return IgnorePointer(
      ignoring: isBlocked, // Block all interactions when blocker is active
      child: Opacity(
        opacity: isBlocked ? 0.5 : 1.0, // Dim the nav bar when blocked
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(icon: Icons.wb_sunny, index: 0, isBlocked: isBlocked),
                  _navItem(icon: Icons.bar_chart, index: 1, isBlocked: isBlocked),
                  _navItem(icon: Icons.edit, index: 2, isBlocked: isBlocked),
                  _navItem(icon: Icons.shield, index: 3, isBlocked: isBlocked),
                  _navItem(icon: Icons.people, index: 4, isBlocked: isBlocked),
                  _navItem(icon: Icons.grid_view, index: 5, isBlocked: isBlocked),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required int index, required bool isBlocked}) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: isBlocked
          ? null // Disable navigation when blocked
          : () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.orange : Colors.white54,
          size: isSelected ? 24 : 22,
        ),
      ),
    );
  }
}

