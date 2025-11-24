import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/ai_workout_controller.dart';
import '../../domain/repositories/ai_workout_repository.dart';
import '../../../../features/workouts/domain/entities/workout_planning_input.dart';

class AiWorkoutScreen extends StatefulWidget {
  const AiWorkoutScreen({super.key});

  @override
  State<AiWorkoutScreen> createState() => _AiWorkoutScreenState();
}

class _AiWorkoutScreenState extends State<AiWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form State
  String _goalType = 'Muscle Build';
  String _fitnessLevel = 'Intermediate';
  final List<String> _equipment = ['Gym'];
  int _sessionsPerWeek = 3;
  int _minutesPerSession = 45;
  int _durationWeeks = 4;
  String? _constraints;
  String? _preference;
  final List<String> _bodyFocusAreas = ['Full Body'];
  String _workoutTime = 'Morning';
  String _intensityPreference = 'Moderate';
  bool _hasPreviousExperience = true;
  String _currentActivityLevel = 'Moderately Active';

  // Options
  final List<String> _goalOptions = [
    'Fat Loss',
    'Strength',
    'Stamina',
    'Muscle Build',
    'General Health',
  ];
  final List<String> _fitnessLevelOptions = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];
  final List<String> _equipmentOptions = [
    'Bodyweight',
    'Dumbbells',
    'Resistance Bands',
    'Gym',
    'Kettlebells',
  ];
  final List<String> _bodyFocusOptions = [
    'Upper Body',
    'Lower Body',
    'Core',
    'Full Body',
    'Cardio',
  ];
  final List<String> _timeOptions = ['Morning', 'Afternoon', 'Evening', 'Any'];
  final List<String> _intensityOptions = ['Low', 'Moderate', 'High'];
  final List<String> _activityLevelOptions = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AiWorkoutController(
        AiWorkoutRepositoryImpl(
          FirebaseFirestore.instance,
          FirebaseAuth.instance,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Workout Preferences')),
        body: Consumer<AiWorkoutController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show success message if saved
            if (controller.isSaved) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preferences saved successfully!'),
                  ),
                );
                controller.reset(); // Reset state after showing snackbar
              });
            }

            return _buildInputForm(controller);
          },
        ),
      ),
    );
  }

  Widget _buildInputForm(AiWorkoutController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Goals & Fitness'),
            _buildDropdown(
              'Goal',
              _goalType,
              _goalOptions,
              (v) => setState(() => _goalType = v!),
            ),
            _buildDropdown(
              'Fitness Level',
              _fitnessLevel,
              _fitnessLevelOptions,
              (v) => setState(() => _fitnessLevel = v!),
            ),
            _buildDropdown(
              'Activity Level',
              _currentActivityLevel,
              _activityLevelOptions,
              (v) => setState(() => _currentActivityLevel = v!),
            ),
            SwitchListTile(
              title: const Text('Previous Experience'),
              value: _hasPreviousExperience,
              onChanged: (v) => setState(() => _hasPreviousExperience = v),
            ),

            _buildSectionTitle('Schedule & Duration'),
            _buildSlider(
              'Days per week',
              _sessionsPerWeek.toDouble(),
              1,
              7,
              6,
              (v) => setState(() => _sessionsPerWeek = v.toInt()),
            ),
            _buildSlider(
              'Minutes per session',
              _minutesPerSession.toDouble(),
              15,
              120,
              21,
              (v) => setState(() => _minutesPerSession = v.toInt()),
            ),
            _buildSlider(
              'Program Duration (Weeks)',
              _durationWeeks.toDouble(),
              1,
              12,
              11,
              (v) => setState(() => _durationWeeks = v.toInt()),
            ),
            _buildDropdown(
              'Preferred Time',
              _workoutTime,
              _timeOptions,
              (v) => setState(() => _workoutTime = v!),
            ),

            _buildSectionTitle('Equipment & Focus'),
            _buildMultiSelect('Equipment', _equipmentOptions, _equipment),
            _buildMultiSelect('Body Focus', _bodyFocusOptions, _bodyFocusAreas),
            _buildDropdown(
              'Intensity',
              _intensityPreference,
              _intensityOptions,
              (v) => setState(() => _intensityPreference = v!),
            ),

            _buildSectionTitle('Personalization'),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Injuries / Constraints (Optional)',
              ),
              onChanged: (v) => _constraints = v,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Additional Preferences (Optional)',
              ),
              onChanged: (v) => _preference = v,
            ),

            const SizedBox(height: 24),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  controller.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final input = WorkoutPlanningInput(
                    goalType: _goalType,
                    fitnessLevel: _fitnessLevel,
                    equipment: _equipment,
                    sessionsPerWeek: _sessionsPerWeek,
                    minutesPerSession: _minutesPerSession,
                    durationWeeks: _durationWeeks,
                    constraints: _constraints,
                    preference: _preference,
                    bodyFocusAreas: _bodyFocusAreas,
                    workoutTime: _workoutTime,
                    intensityPreference: _intensityPreference,
                    hasPreviousExperience: _hasPreviousExperience,
                    currentActivityLevel: _currentActivityLevel,
                  );
                  controller.savePreferences(input);
                }
              },
              child: const Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value'),
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toInt().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMultiSelect(
    String label,
    List<String> options,
    List<String> selectedValues,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Wrap(
          spacing: 8.0,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedValues.add(option);
                  } else {
                    selectedValues.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
