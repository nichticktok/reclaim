import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  UserModel? currentUser;
  bool _loading = true;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // You can redirect to login or onboarding if user is not logged in
        debugPrint("⚠️ No Firebase user found");
        return;
      }

      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        currentUser = UserModel(
          id: user.uid,
          name: data['name'] ?? user.displayName ?? 'User',
          email: data['email'] ?? user.email ?? '',
          goal: data['goal'] ?? '',
          proofMode: data['proofMode'] ?? false,
          level: data['level'] ?? 1,
          streak: data['streak'] ?? 0,
          isPremium: data['isPremium'] ?? false,
        );
      } else {
        // Create a default Firestore user profile if not found
        await userDoc.set({
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'goal': '',
          'proofMode': false,
          'level': 1,
          'streak': 0,
          'isPremium': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        currentUser = UserModel(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          goal: '',
          proofMode: false,
          level: 1,
          streak: 0,
          isPremium: false,
        );
      }

      setState(() {
        _screens = [
          const DailyTasksScreen(),
          const ProgressScreen(),
          const CommunityScreen(),
          ProfileScreen(user: currentUser!),
        ];
        _loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
