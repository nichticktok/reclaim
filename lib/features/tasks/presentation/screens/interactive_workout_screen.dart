import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recalim/core/models/habit_model.dart';

class InteractiveWorkoutScreen extends StatefulWidget {
  final HabitModel habit;

  const InteractiveWorkoutScreen({
    super.key,
    required this.habit,
  });

  @override
  State<InteractiveWorkoutScreen> createState() => _InteractiveWorkoutScreenState();
}

class _InteractiveWorkoutScreenState extends State<InteractiveWorkoutScreen> {
  List<Map<String, dynamic>> _exercises = [];
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  bool _workoutCompleted = false;
  Map<int, List<bool>> _completedSets = {}; // exerciseIndex -> [set1 completed, set2 completed, ...]

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    final metadata = widget.habit.metadata;
    final exercisesRaw = metadata['exercises'] as List<dynamic>? ?? [];
    _exercises = exercisesRaw
        .whereType<Map<String, dynamic>>()
        .where((exercise) => (exercise['name'] ?? '').toString().isNotEmpty)
        .toList();

    // Initialize completed sets tracking
    for (int i = 0; i < _exercises.length; i++) {
      final sets = _getSetsForExercise(i);
      _completedSets[i] = List.filled(sets, false);
    }

    if (_exercises.isEmpty) {
      // No exercises, mark as completed
      _workoutCompleted = true;
    }
  }

  int _getSetsForExercise(int exerciseIndex) {
    if (exerciseIndex >= _exercises.length) return 0;
    final exercise = _exercises[exerciseIndex];
    final sets = exercise['sets'];
    if (sets is num) {
      return sets.toInt();
    } else if (sets is String) {
      // Handle "AMRAP" or similar strings - default to 3
      return 3;
    }
    return 3; // Default
  }

  int _getRestSecondsForExercise(int exerciseIndex) {
    if (exerciseIndex >= _exercises.length) return 60;
    final exercise = _exercises[exerciseIndex];
    final rest = exercise['restSeconds'];
    if (rest is num) {
      return rest.toInt();
    }
    return 60; // Default
  }

  String _getRepsForExercise(int exerciseIndex) {
    if (exerciseIndex >= _exercises.length) return '10';
    final exercise = _exercises[exerciseIndex];
    return exercise['reps']?.toString() ?? '10';
  }

  String _getExerciseName(int exerciseIndex) {
    if (exerciseIndex >= _exercises.length) return 'Unknown';
    return _exercises[exerciseIndex]['name']?.toString() ?? 'Unknown';
  }

  String _getExerciseInstructions(int exerciseIndex) {
    if (exerciseIndex >= _exercises.length) return '';
    return _exercises[exerciseIndex]['instructions']?.toString() ?? '';
  }

  void _completeSet() {
    if (_currentExerciseIndex >= _exercises.length) return;

    setState(() {
      _completedSets[_currentExerciseIndex]![_currentSet - 1] = true;
    });

    final totalSets = _getSetsForExercise(_currentExerciseIndex);
    
    if (_currentSet < totalSets) {
      // More sets remaining - start rest timer
      _startRestTimer();
    } else {
      // All sets completed for this exercise
      _moveToNextExercise();
    }
  }

  void _startRestTimer() {
    final restSeconds = _getRestSecondsForExercise(_currentExerciseIndex);
    setState(() {
      _isResting = true;
      _restSecondsRemaining = restSeconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_restSecondsRemaining > 0) {
          _restSecondsRemaining--;
        } else {
          _isResting = false;
          _currentSet++;
          timer.cancel();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _currentSet++;
    });
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _isResting = false;
        _restSecondsRemaining = 0;
      });
    } else {
      // All exercises completed
      _completeWorkout();
    }
  }

  void _completeWorkout() {
    _restTimer?.cancel();
    setState(() {
      _workoutCompleted = true;
    });
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _currentSet = 1;
        _isResting = false;
        _restSecondsRemaining = 0;
        _restTimer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_workoutCompleted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0F),
        appBar: AppBar(
          title: const Text(
            'Workout Complete!',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Great job!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You completed ${_exercises.length} exercises',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true); // Return true to indicate completion
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                icon: const Icon(Icons.done, color: Colors.white),
                label: const Text(
                  'Mark as Complete',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_exercises.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0F),
        appBar: AppBar(
          title: const Text(
            'Workout',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'No exercises found',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final totalSets = _getSetsForExercise(_currentExerciseIndex);
    final reps = _getRepsForExercise(_currentExerciseIndex);
    final exerciseName = _getExerciseName(_currentExerciseIndex);
    final instructions = _getExerciseInstructions(_currentExerciseIndex);
    final completedSetsForExercise = _completedSets[_currentExerciseIndex] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: Text(
          'Exercise ${_currentExerciseIndex + 1} of ${_exercises.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: _currentExerciseIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousExercise,
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Name
            Text(
              exerciseName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Exercise Info
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.repeat,
                  label: '$totalSets sets',
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.fitness_center,
                  label: '$reps reps',
                ),
              ],
            ),

            if (instructions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFF6B35),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instructions,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Rest Timer (if resting)
            if (_isResting) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Rest Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatTime(_restSecondsRemaining),
                      style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _skipRest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      label: const Text(
                        'Skip Rest',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Sets Progress
            if (!_isResting) ...[
              Text(
                'Set $_currentSet of $totalSets',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Sets List
              ...List.generate(totalSets, (index) {
                final setNumber = index + 1;
                final isCompleted = completedSetsForExercise.length > index &&
                    completedSetsForExercise[index];
                final isCurrent = setNumber == _currentSet && !isCompleted;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
                        : isCompleted
                            ? Colors.green.withValues(alpha: 0.1)
                            : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFFFF6B35)
                          : isCompleted
                              ? Colors.green
                              : Colors.white.withValues(alpha: 0.1),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Set $setNumber',
                          style: TextStyle(
                            color: isCompleted
                                ? Colors.green
                                : isCurrent
                                    ? Colors.white
                                    : Colors.white70,
                            fontSize: 16,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        )
                      else if (isCurrent)
                        const Icon(
                          Icons.play_circle_outline,
                          color: Color(0xFFFF6B35),
                          size: 24,
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Complete Set Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completeSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white, size: 28),
                  label: Text(
                    _currentSet < totalSets
                        ? 'Complete Set $_currentSet'
                        : 'Complete Final Set',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            // Progress Indicator
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (_currentExerciseIndex + 1) / _exercises.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_currentExerciseIndex + 1} / ${_exercises.length} exercises',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFF6B35), size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

