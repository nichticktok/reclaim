import 'package:flutter/material.dart';
import 'package:recalim/core/widgets/reflection_card.dart';
import 'package:recalim/core/widgets/custom_button.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final TextEditingController _gratitudeController = TextEditingController();
  final TextEditingController _lessonController = TextEditingController();
  final TextEditingController _improvementController = TextEditingController();
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Daily Reflection"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: !submitted
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Take a few minutes to reflect on your day 🌙",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  ReflectionCard(
                    question: "1️⃣ What are you grateful for today?",
                    controller: _gratitudeController,
                  ),

                  const SizedBox(height: 16),

                  ReflectionCard(
                    question: "2️⃣ What did you learn today?",
                    controller: _lessonController,
                  ),

                  const SizedBox(height: 16),

                  ReflectionCard(
                    question: "3️⃣ What can you improve tomorrow?",
                    controller: _improvementController,
                  ),

                  const SizedBox(height: 30),

                  CustomButton(
                    text: "Save Reflection",
                    onPressed: _handleSubmit,
                  ),
                ],
              )
            : _thankYouView(),
      ),
    );
  }

  void _handleSubmit() {
    if (_gratitudeController.text.isEmpty ||
        _lessonController.text.isEmpty ||
        _improvementController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all reflections.")),
      );
      return;
    }

    setState(() => submitted = true);

    // (Future: Save reflection data locally or to Firebase)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reflection saved ✅")),
    );
  }

  Widget _thankYouView() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.self_improvement, color: Colors.blue, size: 60),
          const SizedBox(height: 16),
          const Text(
            "Great job reflecting today!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Your awareness today builds discipline tomorrow 💪",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          CustomButton(
            text: "Back to Home",
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
