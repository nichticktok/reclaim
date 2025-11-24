import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/custom_workout_plan.dart';
import '../controllers/workout_counter_controller.dart';

class CreateCustomWorkoutScreen extends StatefulWidget {
  final CustomWorkoutPlan? plan;

  const CreateCustomWorkoutScreen({super.key, this.plan});

  @override
  State<CreateCustomWorkoutScreen> createState() => _CreateCustomWorkoutScreenState();
}

class _CreateCustomWorkoutScreenState extends State<CreateCustomWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<CustomExercise> _exercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _planNameController.text = widget.plan!.planName;
      _descriptionController.text = widget.plan!.description ?? '';
      _exercises = List.from(widget.plan!.exercises);
    }
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) => _ExerciseDialog(
        onSave: (exercise) {
          setState(() {
            _exercises.add(exercise);
          });
        },
      ),
    );
  }

  void _editExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => _ExerciseDialog(
        exercise: _exercises[index],
        onSave: (exercise) {
          setState(() {
            _exercises[index] = exercise;
          });
        },
      ),
    );
  }

  void _deleteExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = context.read<WorkoutCounterController>();
      final plan = CustomWorkoutPlan(
        id: widget.plan?.id ?? '',
        userId: '', // Will be set in controller
        planName: _planNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        exercises: _exercises,
        createdAt: widget.plan?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        totalWorkouts: widget.plan?.totalWorkouts ?? 0,
        bestTime: widget.plan?.bestTime,
      );

      await controller.saveCustomWorkoutPlan(plan);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout plan saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: Text(
          widget.plan == null ? 'Create Workout Plan' : 'Edit Workout Plan',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Name
              TextFormField(
                controller: _planNameController,
                decoration: InputDecoration(
                  labelText: 'Plan Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a plan name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Exercises Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Exercises',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Exercise', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Exercises List
              if (_exercises.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exercises yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(_exercises.length, (index) {
                  final exercise = _exercises[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${exercise.sets} sets × ${exercise.reps} reps • Rest: ${exercise.restSeconds}s',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _editExercise(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteExercise(index),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Plan',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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

class _ExerciseDialog extends StatefulWidget {
  final CustomExercise? exercise;
  final Function(CustomExercise) onSave;

  const _ExerciseDialog({this.exercise, required this.onSave});

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _restSecondsController = TextEditingController();
  final _restBetweenExercisesController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      _nameController.text = widget.exercise!.name;
      _setsController.text = widget.exercise!.sets.toString();
      _repsController.text = widget.exercise!.reps;
      _restSecondsController.text = widget.exercise!.restSeconds.toString();
      _restBetweenExercisesController.text = widget.exercise!.restBetweenExercises.toString();
      _instructionsController.text = widget.exercise!.instructions ?? '';
    } else {
      _setsController.text = '3';
      _repsController.text = '10';
      _restSecondsController.text = '60';
      _restBetweenExercisesController.text = '90';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restSecondsController.dispose();
    _restBetweenExercisesController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final exercise = CustomExercise(
      name: _nameController.text.trim(),
      sets: int.parse(_setsController.text),
      reps: _repsController.text.trim(),
      restSeconds: int.parse(_restSecondsController.text),
      restBetweenExercises: int.parse(_restBetweenExercisesController.text),
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
    );

    widget.onSave(exercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text(
        widget.exercise == null ? 'Add Exercise' : 'Edit Exercise',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0D0D0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      decoration: InputDecoration(
                        labelText: 'Sets',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0D0D0F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 1) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: InputDecoration(
                        labelText: 'Reps',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0D0D0F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _restSecondsController,
                      decoration: InputDecoration(
                        labelText: 'Rest (seconds)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0D0D0F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _restBetweenExercisesController,
                      decoration: InputDecoration(
                        labelText: 'Rest Between Exercises (s)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0D0D0F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final num = int.tryParse(value);
                        if (num == null || num < 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  labelText: 'Instructions (Optional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF0D0D0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

