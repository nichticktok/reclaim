import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../widgets/proof_input_box.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _proofController = TextEditingController();
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    final HabitModel habit =
        ModalRoute.of(context)!.settings.arguments as HabitModel;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(habit.title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧩 Habit Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.description,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        "Scheduled: ${habit.scheduledTime}",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (habit.requiresProof)
                    Row(
                      children: const [
                        Icon(Icons.verified_user, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          "Proof required for this habit",
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🧾 Proof Input Section
            if (habit.requiresProof && !submitted)
              ProofInputBox(
                controller: _proofController,
                onSubmit: _handleProofSubmit,
                showAttachmentButton: true,
              ),

            const SizedBox(height: 20),

            // ✅ Completion Confirmation
            if (submitted)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 60),
                    const SizedBox(height: 10),
                    const Text(
                      "Task Completed!",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Go Back to Daily Tasks"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleProofSubmit() {
    if (_proofController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write something first.")),
      );
      return;
    }

    setState(() {
      submitted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Proof submitted successfully ✅")),
    );
  }
}
