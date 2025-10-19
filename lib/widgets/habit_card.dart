import 'package:flutter/material.dart';
import '../models/habit_model.dart';

class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final VoidCallback onTap;
  final VoidCallback? onComplete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circle icon / completion indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: habit.completed
                    ? Colors.greenAccent.withOpacity(0.3)
                    : Colors.grey.shade200,
              ),
              child: Icon(
                habit.completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: habit.completed ? Colors.green : Colors.grey,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Habit title & details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        habit.scheduledTime,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (habit.requiresProof) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.verified_user,
                            size: 16, color: Colors.blueAccent),
                      ]
                    ],
                  ),
                ],
              ),
            ),

            // Action button
            IconButton(
              icon: Icon(
                habit.completed ? Icons.check_circle : Icons.arrow_forward_ios,
                color: habit.completed ? Colors.green : Colors.grey.shade400,
              ),
              onPressed: onComplete ?? onTap,
            ),
          ],
        ),
      ),
    );
  }
}
