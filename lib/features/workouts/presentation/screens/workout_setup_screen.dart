import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/workout_planning_input.dart';
import '../controllers/workouts_controller.dart';
import 'review_workout_plan_screen.dart';

class WorkoutSetupScreen extends StatefulWidget {
  const WorkoutSetupScreen({super.key});

  @override
  State<WorkoutSetupScreen> createState() => _WorkoutSetupScreenState();
}

class _WorkoutSetupScreenState extends State<WorkoutSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  String _goalType = 'general_health';
  String _fitnessLevel = 'beginner';
  final List<String> _selectedEquipment = ['bodyweight'];
  int _sessionsPerWeek = 3;
  int _minutesPerSession = 30;
  int _durationWeeks = 4;
  String? _constraints;
  String? _preference;
  final List<String> _bodyFocusAreas = [];
  String? _workoutTime;
  String? _intensityPreference;
  bool? _hasPreviousExperience;
  String? _currentActivityLevel;

  final List<String> _goalTypes = [
    'fat_loss',
    'strength',
    'stamina',
    'muscle_build',
    'general_health',
  ];

  final List<String> _fitnessLevels = [
    'beginner',
    'intermediate',
    'advanced',
  ];

  final List<String> _equipmentOptions = [
    'bodyweight',
    'dumbbells',
    'resistance_bands',
    'gym',
    'kettlebells',
    'pull_up_bar',
    'yoga_mat',
  ];

  final List<String> _bodyFocusOptions = [
    'upper_body',
    'lower_body',
    'core',
    'full_body',
    'cardio',
    'flexibility',
  ];

  final List<String> _workoutTimeOptions = [
    'morning',
    'afternoon',
    'evening',
    'flexible',
  ];

  final List<String> _intensityOptions = [
    'low',
    'moderate',
    'high',
  ];

  final List<String> _activityLevels = [
    'sedentary',
    'lightly_active',
    'moderately_active',
    'very_active',
  ];

  String _getGoalDisplayName(String goal) {
    switch (goal) {
      case 'fat_loss':
        return 'Lose Fat';
      case 'strength':
        return 'Get Stronger';
      case 'stamina':
        return 'Improve Stamina';
      case 'muscle_build':
        return 'Build Muscle';
      case 'general_health':
        return 'Stay Active';
      default:
        return goal;
    }
  }

  String _getBodyFocusDisplayName(String focus) {
    switch (focus) {
      case 'upper_body':
        return 'Upper Body';
      case 'lower_body':
        return 'Lower Body';
      case 'core':
        return 'Core';
      case 'full_body':
        return 'Full Body';
      case 'cardio':
        return 'Cardio';
      case 'flexibility':
        return 'Flexibility';
      default:
        return focus;
    }
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<WorkoutsController>();
    final input = WorkoutPlanningInput(
      goalType: _goalType,
      fitnessLevel: _fitnessLevel,
      equipment: _selectedEquipment,
      sessionsPerWeek: _sessionsPerWeek,
      minutesPerSession: _minutesPerSession,
      durationWeeks: _durationWeeks,
      constraints: _constraints?.isEmpty ?? true ? null : _constraints,
      preference: _preference?.isEmpty ?? true ? null : _preference,
      bodyFocusAreas: _bodyFocusAreas.isEmpty ? null : _bodyFocusAreas,
      workoutTime: _workoutTime,
      intensityPreference: _intensityPreference,
      hasPreviousExperience: _hasPreviousExperience,
      currentActivityLevel: _currentActivityLevel,
    );

    try {
      await controller.generatePlan(input);
      if (!mounted) return;

      // Navigate to review plan screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewWorkoutPlanScreen(input: input),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          'Workout AI Assistant',
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
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.7, // 70% through setup
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Step 1 of 2',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
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
                      // Header
                      const Text(
                        'Let\'s create your personalized workout plan',
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

                      // Goal Type Section
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

                      // Fitness Level Section
                      _buildSectionHeader('What\'s your fitness level?', Icons.trending_up),
                      const SizedBox(height: 12),
                      Row(
                        children: _fitnessLevels.map((level) {
                          final isSelected = _fitnessLevel == level;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(level.toUpperCase()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _fitnessLevel = level);
                                },
                                selectedColor: Colors.orange,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: const Color(0xFF1A1A1A),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Current Activity Level
                      _buildSectionHeader('How active are you currently?', Icons.directions_run),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activityLevels.map((level) {
                          final isSelected = _currentActivityLevel == level;
                          return ChoiceChip(
                            label: Text(level.replaceAll('_', ' ').toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _currentActivityLevel = selected ? level : null);
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

                      // Previous Experience
                      _buildSectionHeader('Do you have previous workout experience?', Icons.history),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Yes'),
                              selected: _hasPreviousExperience == true,
                              onSelected: (selected) {
                                setState(() => _hasPreviousExperience = selected ? true : null);
                              },
                              selectedColor: Colors.orange,
                              labelStyle: TextStyle(
                                color: _hasPreviousExperience == true ? Colors.white : Colors.white70,
                              ),
                              backgroundColor: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('No'),
                              selected: _hasPreviousExperience == false,
                              onSelected: (selected) {
                                setState(() => _hasPreviousExperience = selected ? false : null);
                              },
                              selectedColor: Colors.orange,
                              labelStyle: TextStyle(
                                color: _hasPreviousExperience == false ? Colors.white : Colors.white70,
                              ),
                              backgroundColor: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Equipment Section
                      _buildSectionHeader('What equipment do you have access to?', Icons.sports_gymnastics),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _equipmentOptions.map((equipment) {
                          final isSelected = _selectedEquipment.contains(equipment);
                          return FilterChip(
                            label: Text(equipment.replaceAll('_', ' ').toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedEquipment.add(equipment);
                                } else {
                                  _selectedEquipment.remove(equipment);
                                }
                                // Ensure at least one is selected
                                if (_selectedEquipment.isEmpty) {
                                  _selectedEquipment.add('bodyweight');
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

                      // Body Focus Areas
                      _buildSectionHeader('What areas would you like to focus on? (Optional)', Icons.accessibility_new),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _bodyFocusOptions.map((focus) {
                          final isSelected = _bodyFocusAreas.contains(focus);
                          return FilterChip(
                            label: Text(_getBodyFocusDisplayName(focus)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _bodyFocusAreas.add(focus);
                                } else {
                                  _bodyFocusAreas.remove(focus);
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

                      // Workout Time Preference
                      _buildSectionHeader('Preferred workout time? (Optional)', Icons.access_time),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _workoutTimeOptions.map((time) {
                          final isSelected = _workoutTime == time;
                          return ChoiceChip(
                            label: Text(time.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _workoutTime = selected ? time : null);
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

                      // Intensity Preference
                      _buildSectionHeader('Intensity preference? (Optional)', Icons.speed),
                      const SizedBox(height: 12),
                      Row(
                        children: _intensityOptions.map((intensity) {
                          final isSelected = _intensityPreference == intensity;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(intensity.toUpperCase()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _intensityPreference = selected ? intensity : null);
                                },
                                selectedColor: Colors.orange,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                                backgroundColor: const Color(0xFF1A1A1A),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Sessions per week
                      _buildSectionHeader('How many days per week?', Icons.calendar_today),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_sessionsPerWeek days per week',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: _sessionsPerWeek.toDouble(),
                              min: 2,
                              max: 6,
                              divisions: 4,
                              label: '$_sessionsPerWeek days',
                              activeColor: Colors.orange,
                              onChanged: (value) => setState(() => _sessionsPerWeek = value.toInt()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Minutes per session
                      _buildSectionHeader('How long per session?', Icons.timer),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_minutesPerSession minutes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: _minutesPerSession.toDouble(),
                              min: 15,
                              max: 90,
                              divisions: 15,
                              label: '$_minutesPerSession min',
                              activeColor: Colors.orange,
                              onChanged: (value) => setState(() => _minutesPerSession = value.toInt()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Duration
                      _buildSectionHeader('How long do you want this plan?', Icons.date_range),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_durationWeeks weeks',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: _durationWeeks.toDouble(),
                              min: 2,
                              max: 12,
                              divisions: 10,
                              label: '$_durationWeeks weeks',
                              activeColor: Colors.orange,
                              onChanged: (value) => setState(() => _durationWeeks = value.toInt()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Constraints (optional)
                      _buildSectionHeader('Any injuries or limitations? (Optional)', Icons.medical_services),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _constraints,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'e.g., Knee pain, Lower back issues, No jumping',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Leave blank if none',
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
                        onChanged: (value) => setState(() => _constraints = value),
                      ),
                      const SizedBox(height: 32),

                      // Additional Preferences
                      _buildSectionHeader('Additional preferences? (Optional)', Icons.tune),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _preference,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'e.g., Home workouts only, Low impact preferred',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Any other preferences or requirements',
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
                        onChanged: (value) => setState(() => _preference = value),
                      ),
                      const SizedBox(height: 40),

                      // Generate Plan Button
                      Consumer<WorkoutsController>(
                        builder: (context, controller, child) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.loading ? null : _generatePlan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: controller.loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.auto_awesome, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Generate My Plan',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
