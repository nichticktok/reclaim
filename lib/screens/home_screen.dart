import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'progress_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'daily_tasks_screen.dart';
import 'auth/sign_in_screen.dart';

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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // 1) Wait for a real, non-null user (restores fast if already signed in)
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(const Duration(seconds: 10), onTimeout: () => null);

      if (!mounted) return;

      if (user == null) {
        // No session → go to Sign-in
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SignInScreen()),
          );
        }
        return;
      }

      // 2) Ensure /users/<uid> exists so Firestore rules allow reads
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snap = await userRef.get();
      if (!snap.exists) {
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'goal': '',
          'proofMode': false,
          'level': 1,
          'streak': 0,
          'isPremium': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // keep lastSeen fresh
        await userRef.set({'lastSeen': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }

      // 3) Read user data (now rules should permit)
      final doc = await userRef.get();
      final data = doc.data() ?? {};

      currentUser = UserModel(
        id: user.uid,
        name: (data['name'] ?? user.displayName ?? 'User') as String,
        email: (data['email'] ?? user.email ?? '') as String,
        goal: (data['goal'] ?? '') as String,
        proofMode: (data['proofMode'] ?? false) as bool,
        level: (data['level'] ?? 1) as int,
        streak: (data['streak'] ?? 0) as int,
        isPremium: (data['isPremium'] ?? false) as bool,
      );

      _screens = [
        const DailyTasksScreen(),
        const ProgressScreen(),
        const CommunityScreen(),
        ProfileScreen(user: currentUser!),
      ];

      if (mounted) {
        setState(() => _loading = false);
      }
    } on FirebaseException catch (e) {
      // Surface permission errors clearly, but don’t crash UI
      debugPrint('❌ Firestore error: ${e.code} – ${e.message}');
      if (e.code == 'permission-denied') {
        // Optionally show a friendly screen or route to sign-in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied. Please sign in again.')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SignInScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message ?? e.code}')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
              color: Colors.black.withValues(alpha: 0.07),
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
              ? Colors.blueAccent.withValues(alpha: 0.15)
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
