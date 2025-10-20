import 'package:flutter/material.dart';
import '../widgets/progress_ring.dart';
import '../widgets/custom_button.dart';
import '../models/user_model.dart';

class ProgramOverviewScreen extends StatelessWidget {
  final UserModel user;

  const ProgramOverviewScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    double progress = 0.6; // Placeholder for now

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Reclaim Overview"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              "Good ${_getGreeting()}, ${user.name.split(' ').first} 👋",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Here’s your progress so far today:",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 30),

            // Progress Ring
            Center(
              child: ProgressRing(
                progress: progress,
                label: "Today's Progress",
              ),
            ),

            const SizedBox(height: 30),

            // Quick stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBox("Habits", "5"),
                _statBox("Completed", "3"),
                _statBox("Proofs", "2"),
              ],
            ),

            const SizedBox(height: 40),

            // Motivational quote
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                "\"Discipline is remembering what you want most over what you want now.\"",
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 50),

            // Button to go to Daily Tasks
            CustomButton(
              text: "Go to Daily Tasks",
              onPressed: () {
                Navigator.pushNamed(context, '/daily_tasks');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "morning";
    if (hour < 18) return "afternoon";
    return "evening";
  }

  Widget _statBox(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
