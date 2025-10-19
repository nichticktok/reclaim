import 'package:flutter/material.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/task_detail_screen.dart'; // ✅ important import

void main() {
  runApp(const ReclaimApp());
}

class ReclaimApp extends StatelessWidget {
  const ReclaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reclaim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
      ),

      // ✅ make sure this is correct:
      home: const OnboardingScreen(),

      routes: {
        '/home': (context) => const HomeScreen(),
        '/task_detail': (context) => const TaskDetailScreen(), // ✅ added here
      },
    );
  }
}
