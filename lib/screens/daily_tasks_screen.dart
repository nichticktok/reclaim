import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../widgets/habit_card.dart';
import '../widgets/proof_input_box.dart';
import '../models/user_model.dart'; // To access global proof mode (if stored in UserModel)

class DailyTasksScreen extends StatefulWidget {
  final UserModel? user; // optional user, holds proofMode flag
  const DailyTasksScreen({super.key, this.user});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  // Placeholder data for now
  List<HabitModel> habits = [
    HabitModel(
      id: '1',
      title: "Wake up at 7:00 AM",
      description: "Start the day early with purpose.",
      scheduledTime: "7:00 AM",
      requiresProof: false,
    ),
    HabitModel(
      id: '2',
      title: "Study for 1 hour",
      description: "Read and summarize from Atomic Habits.",
      scheduledTime: "9:00 AM",
      requiresProof: true,
    ),
    HabitModel(
      id: '3',
      title: "Workout",
      description: "30-minute bodyweight exercise.",
      scheduledTime: "6:00 PM",
      requiresProof: true,
    ),
  ];

  String selectedFilter = "All";

  @override
  Widget build(BuildContext context) {
    List<HabitModel> filteredHabits = _getFilteredHabits();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Today's Tasks"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // Filter tabs
          _buildFilterRow(),

          const SizedBox(height: 10),

          // Habits list
          Expanded(
            child: ListView.builder(
              itemCount: filteredHabits.length,
              itemBuilder: (context, index) {
                final habit = filteredHabits[index];
                return HabitCard(
                  habit: habit,
                  onTap: () => _handleHabitTap(habit),
                  onComplete: () => _handleHabitCompletion(habit),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Add Habit coming soon ✨")),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ✅ When user taps on a habit card
  void _handleHabitTap(HabitModel habit) {
    final bool proofRequired = habit.requiresProof || (widget.user?.proofMode ?? false);

    if (proofRequired) {
      _openProofDialog(habit);
    } else {
      Navigator.pushNamed(context, '/task_detail', arguments: habit);
    }
  }

  // ✅ When user tries to mark complete directly
  void _handleHabitCompletion(HabitModel habit) {
    final bool proofRequired = habit.requiresProof || (widget.user?.proofMode ?? false);

    if (proofRequired) {
      _openProofDialog(habit);
    } else {
      setState(() => habit.completed = !habit.completed);
    }
  }

  // ✅ Opens proof submission dialog
  void _openProofDialog(HabitModel habit) {
    final TextEditingController proofController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Submit Proof for \"${habit.title}\"",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ProofInputBox(
                  controller: proofController,
                  onSubmit: () {
                    if (proofController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please provide proof before completing."),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      habit.completed = true;
                    });
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Proof submitted for '${habit.title}' ✅"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Filtering logic
  List<HabitModel> _getFilteredHabits() {
    switch (selectedFilter) {
      case "Pending":
        return habits.where((h) => !h.completed).toList();
      case "Completed":
        return habits.where((h) => h.completed).toList();
      default:
        return habits;
    }
  }

  Widget _buildFilterRow() {
    final filters = ["All", "Pending", "Completed"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: filters.map((filter) {
        final bool isActive = selectedFilter == filter;
        return GestureDetector(
          onTap: () {
            setState(() => selectedFilter = filter);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.blueAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: Text(
              filter,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
