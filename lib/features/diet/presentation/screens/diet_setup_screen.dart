import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/diet_planning_input.dart';
import '../controllers/diet_controller.dart';
import 'review_diet_plan_screen.dart';

class DietSetupScreen extends StatefulWidget {
  const DietSetupScreen({super.key});

  @override
  State<DietSetupScreen> createState() => _DietSetupScreenState();
}

class _DietSetupScreenState extends State<DietSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  String _goalType = 'weight_loss';
  String _dietType = 'balanced';
  String _activityLevel = 'moderately_active';
  // Diet plans are fixed to 1 week only
  static const int _durationWeeks = 1;
  int? _targetCalories;
  int? _currentWeight;
  int? _targetWeight;
  final List<String> _allergies = [];
  final List<String> _dislikes = [];
  final List<String> _preferences = [];
  String? _mealFrequency;
  String? _cookingSkill;
  String? _budget;
  String? _timeAvailable;
  bool? _mealPrepFriendly;
  String? _dietaryRestrictions;
  final List<String> _cookingTimeSlots = [];
  String? _cookingCapacity;
  String? _cookingSchedule;

  final List<String> _goalTypes = [
    'weight_loss',
    'weight_gain',
    'muscle_gain',
    'maintenance',
    'general_health',
  ];

  final List<String> _dietTypes = [
    'balanced',
    'vegetarian',
    'vegan',
    'keto',
    'paleo',
    'mediterranean',
    'low_carb',
    'high_protein',
  ];

  final List<String> _activityLevels = [
    'sedentary',
    'lightly_active',
    'moderately_active',
    'very_active',
  ];

  final List<String> _cookingTimeSlotOptions = [
    'morning',
    'afternoon',
    'evening',
    'night',
    'weekend',
    'weekday',
  ];

  final List<String> _cookingCapacityOptions = [
    'single_meal',
    'batch_cooking',
    'full_day_prep',
    'weekly_prep',
  ];

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

  String _getDietTypeDisplayName(String type) {
    return type.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _getCookingCapacityDisplayName(String capacity) {
    switch (capacity) {
      case 'single_meal':
        return 'Single Meal';
      case 'batch_cooking':
        return 'Batch Cooking';
      case 'full_day_prep':
        return 'Full Day Prep';
      case 'weekly_prep':
        return 'Weekly Prep';
      default:
        return capacity.replaceAll('_', ' ').toUpperCase();
    }
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<DietController>();
    final input = DietPlanningInput(
      goalType: _goalType,
      dietType: _dietType,
      activityLevel: _activityLevel,
      durationWeeks: _durationWeeks, // Fixed to 1 week
      targetCalories: _targetCalories,
      currentWeight: _currentWeight,
      targetWeight: _targetWeight,
      allergies: _allergies.isEmpty ? null : _allergies,
      dislikes: _dislikes.isEmpty ? null : _dislikes,
      preferences: _preferences.isEmpty ? null : _preferences,
      mealFrequency: _mealFrequency,
      cookingSkill: _cookingSkill,
      budget: _budget,
      timeAvailable: _timeAvailable,
      mealPrepFriendly: _mealPrepFriendly,
      dietaryRestrictions: _dietaryRestrictions?.isEmpty ?? true ? null : _dietaryRestrictions,
      cookingTimeSlots: _cookingTimeSlots.isEmpty ? null : _cookingTimeSlots,
      cookingCapacity: _cookingCapacity,
      cookingSchedule: _cookingSchedule?.isEmpty ?? true ? null : _cookingSchedule,
    );

    try {
      await controller.generatePlan(input);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewDietPlanScreen(input: input),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          'Diet Plan AI Assistant',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.7,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Step 1 of 2',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Let\'s create your personalized diet plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Answer a few questions to get started',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Goal Type
                      _buildSectionHeader('What\'s your primary goal?', Icons.flag),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _goalTypes.map((goal) {
                          final isSelected = _goalType == goal;
                          return ChoiceChip(
                            label: Text(_getGoalDisplayName(goal)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _goalType = goal);
                            },
                            selectedColor: Colors.orange,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: const Color(0xFF1A1A1A),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Diet Type
                      _buildSectionHeader('What diet type do you prefer?', Icons.restaurant_menu),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dietTypes.map((type) {
                          final isSelected = _dietType == type;
                          return ChoiceChip(
                            label: Text(_getDietTypeDisplayName(type)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _dietType = type);
                            },
                            selectedColor: Colors.orange,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: const Color(0xFF1A1A1A),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Activity Level
                      _buildSectionHeader('How active are you?', Icons.directions_run),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activityLevels.map((level) {
                          final isSelected = _activityLevel == level;
                          return ChoiceChip(
                            label: Text(level.replaceAll('_', ' ').toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _activityLevel = level);
                            },
                            selectedColor: Colors.orange,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            backgroundColor: const Color(0xFF1A1A1A),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Cooking Time Slots
                      _buildSectionHeader('When can you cook? (Select all that apply)', Icons.access_time),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _cookingTimeSlotOptions.map((slot) {
                          final isSelected = _cookingTimeSlots.contains(slot);
                          return FilterChip(
                            label: Text(slot.replaceAll('_', ' ').toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _cookingTimeSlots.add(slot);
                                } else {
                                  _cookingTimeSlots.remove(slot);
                                }
                              });
                            },
                            selectedColor: Colors.orange,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            backgroundColor: const Color(0xFF1A1A1A),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Cooking Capacity
                      _buildSectionHeader('How much can you cook at once?', Icons.restaurant),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _cookingCapacityOptions.map((capacity) {
                          final isSelected = _cookingCapacity == capacity;
                          return ChoiceChip(
                            label: Text(_getCookingCapacityDisplayName(capacity)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _cookingCapacity = selected ? capacity : null);
                            },
                            selectedColor: Colors.orange,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: const Color(0xFF1A1A1A),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Cooking Schedule (Optional detailed notes)
                      _buildSectionHeader('Cooking Schedule Details (Optional)', Icons.calendar_today),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _cookingSchedule,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'e.g., "Cook breakfast daily, meal prep on Sunday"',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Describe your cooking schedule in detail',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                        ),
                        onChanged: (value) => setState(() => _cookingSchedule = value.isEmpty ? null : value),
                      ),
                      const SizedBox(height: 32),

                      // Optional fields
                      _buildSectionHeader('Target Calories (Optional)', Icons.local_fire_department),
                      const SizedBox(height: 12),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'e.g., 2000',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Leave blank for AI to calculate',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _targetCalories = value.isEmpty ? null : int.tryParse(value);
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Generate Button
                      Consumer<DietController>(
                        builder: (context, controller, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: controller.loading ? null : _generatePlan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: controller.loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Generate Diet Plan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

