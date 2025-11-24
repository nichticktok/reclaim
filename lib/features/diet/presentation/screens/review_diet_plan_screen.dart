import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/diet_planning_input.dart';
import '../controllers/diet_controller.dart';

class ReviewDietPlanScreen extends StatelessWidget {
  final DietPlanningInput input;

  const ReviewDietPlanScreen({
    super.key,
    required this.input,
  });

  String _getGoalDisplayName(String goal) {
    switch (goal) {
      case 'weight_loss':
        return 'Lose Weight';
      case 'weight_gain':
        return 'Gain Weight';
      case 'muscle_gain':
        return 'Build Muscle';
      case 'maintenance':
        return 'Maintain Weight';
      case 'general_health':
        return 'General Health';
      default:
        return goal.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          'Review Your Diet Plan',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DietController>(
        builder: (context, controller, child) {
          final plan = controller.generatedPlan;
          if (plan == null) {
            return const Center(
              child: Text(
                'No plan generated',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu, color: Colors.orange, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getGoalDisplayName(input.goalType),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '1 week • ${input.dietType.replaceAll('_', ' ').toUpperCase()}',
                        style: TextStyle(
                          color: Colors.orange.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Weeks List
                Text(
                  'Your Meal Plan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...plan.weeks.map((week) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week ${week.weekNumber}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...week.days.map((day) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D0D0F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  day.date,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${day.totalCalories} calories',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...day.meals.map((meal) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              meal.mealType == 'breakfast'
                                                  ? Icons.wb_sunny
                                                  : meal.mealType == 'lunch'
                                                      ? Icons.lunch_dining
                                                      : meal.mealType == 'dinner'
                                                          ? Icons.dinner_dining
                                                          : Icons.cookie,
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${meal.name} (${meal.calories} cal)',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (meal.cookingSchedule != null && meal.cookingSchedule!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 24, top: 4),
                                            child: Text(
                                              '⏰ ${meal.cookingSchedule}',
                                              style: TextStyle(
                                                color: Colors.orange.withValues(alpha: 0.8),
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                if (day.cookingSchedule != null && day.cookingSchedule!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.schedule,
                                            color: Colors.orange,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              day.cookingSchedule!,
                                              style: TextStyle(
                                                color: Colors.orange.withValues(alpha: 0.9),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Diet plan saved successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm & Save Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

