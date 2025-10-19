import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'progress_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'daily_tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Temporary example user — replace later with real user data
  final UserModel currentUser = UserModel(
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
    goal: 'Become more focused and consistent',
    proofMode: true,
    level: 1,
    streak: 0,
    isPremium: false,
  );

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DailyTasksScreen(),
      const ProgressScreen(),
      const CommunityScreen(),
      ProfileScreen(user: currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey.shade100,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.home_rounded, index: 0),
            _navItem(icon: Icons.bar_chart_rounded, index: 1),
            _navItem(icon: Icons.people_alt_rounded, index: 2),
            _navItem(icon: Icons.person_rounded, index: 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required int index}) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.blueAccent : Colors.grey.shade500,
          size: isSelected ? 28 : 26,
        ),
      ),
    );
  }
}
