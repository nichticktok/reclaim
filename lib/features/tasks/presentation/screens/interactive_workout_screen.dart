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
  bool _isRestingBetweenExercises = false; // Track if we're resting between exercises vs between sets
  bool _workoutCompleted = false;
  Map<int, List<bool>> _completedSets = {}; // exerciseIndex -> [set1 completed, set2 completed, ...]
  
  // Timer for tracking set duration
  Timer? _setTimer;
  int _setSecondsElapsed = 0;
  bool _setTimerRunning = false;
  DateTime? _setStartTime;
  
  // Overall workout timer
  Timer? _workoutTimer;
  int _workoutTotalSeconds = 0;
  DateTime? _workoutStartTime;

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _startWorkoutTimer();
  }
  
  void _startWorkoutTimer() {
    _workoutStartTime = DateTime.now();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_workoutStartTime != null) {
        setState(() {
          _workoutTotalSeconds = DateTime.now().difference(_workoutStartTime!).inSeconds;
        });
      }
    });
  }
  
  void _startSetTimer() {
    _setStartTime = DateTime.now();
    _setSecondsElapsed = 0;
    _setTimerRunning = true;
    
    _setTimer?.cancel();
    _setTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_setStartTime != null) {
        setState(() {
          _setSecondsElapsed = DateTime.now().difference(_setStartTime!).inSeconds;
        });
      }
    });
  }
  
  void _stopSetTimer() {
    _setTimer?.cancel();
    setState(() {
      _setTimerRunning = false;
      _setSecondsElapsed = 0;
      _setStartTime = null;
    });
  }
  
  /// Estimate time needed for a set based on reps
  int _estimateSetTime(int exerciseIndex) {
    final reps = _getRepsForExercise(exerciseIndex);
    // Try to parse reps (could be "10", "10-12", "30s", etc.)
    int repCount = 10; // Default
    if (reps.contains('-')) {
      // Range like "10-12", take the average
      final parts = reps.split('-');
      if (parts.length == 2) {
        final first = int.tryParse(parts[0].trim()) ?? 10;
        final second = int.tryParse(parts[1].trim()) ?? 12;
        repCount = ((first + second) / 2).round();
      }
    } else if (reps.endsWith('s')) {
      // Time-based like "30s"
      return int.tryParse(reps.replaceAll('s', '')) ?? 30;
    } else {
      repCount = int.tryParse(reps) ?? 10;
    }
    
    // Estimate: ~2-3 seconds per rep, minimum 20 seconds, maximum 120 seconds
    final estimatedSeconds = (repCount * 2.5).round();
    return estimatedSeconds.clamp(20, 120);
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
    } else {
      // Start set timer for first exercise
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startSetTimer();
        }
      });
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

  int _getRestBetweenExercises(int exerciseIndex) {
    if (exerciseIndex >= _exercises.length) return 90; // Default 90 seconds between exercises
    final exercise = _exercises[exerciseIndex];
    final rest = exercise['restBetweenExercises'];
    if (rest is num) {
      return rest.toInt();
    }
    return 90; // Default 90 seconds between exercises
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

    // Stop set timer
    _stopSetTimer();

    setState(() {
      _completedSets[_currentExerciseIndex]![_currentSet - 1] = true;
    });

    final totalSets = _getSetsForExercise(_currentExerciseIndex);
    
    if (_currentSet < totalSets) {
      // More sets remaining - start rest timer between sets
      _startRestTimer(isBetweenExercises: false);
    } else {
      // All sets completed for this exercise - check if there's a next exercise
      if (_currentExerciseIndex < _exercises.length - 1) {
        // There's a next exercise - start rest timer between exercises
        _startRestTimer(isBetweenExercises: true);
      } else {
        // No more exercises - complete workout
        _completeWorkout();
      }
    }
  }

  void _startRestTimer({required bool isBetweenExercises}) {
    final restSeconds = isBetweenExercises
        ? _getRestBetweenExercises(_currentExerciseIndex)
        : _getRestSecondsForExercise(_currentExerciseIndex);
    
    setState(() {
      _isResting = true;
      _isRestingBetweenExercises = isBetweenExercises;
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
          _isRestingBetweenExercises = false;
          timer.cancel();
          
          if (isBetweenExercises) {
            // Move to next exercise
            _moveToNextExercise();
          } else {
            // Move to next set
            _currentSet++;
            _startSetTimer();
          }
        }
      });
    });
  }

  void _skipRest() {
    final wasBetweenExercises = _isRestingBetweenExercises;
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _isRestingBetweenExercises = false;
    });
    
    if (wasBetweenExercises) {
      // Move to next exercise
      _moveToNextExercise();
    } else {
      // Move to next set
      _currentSet++;
      _startSetTimer();
    }
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _isResting = false;
        _isRestingBetweenExercises = false;
        _restSecondsRemaining = 0;
      });
      // Start set timer for first set of next exercise
      _startSetTimer();
    } else {
      // All exercises completed
      _completeWorkout();
    }
  }

  void _completeWorkout() {
    _restTimer?.cancel();
    _setTimer?.cancel();
    _workoutTimer?.cancel();
    setState(() {
      _workoutCompleted = true;
    });
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      _restTimer?.cancel();
      _stopSetTimer();
      setState(() {
        _currentExerciseIndex--;
        _currentSet = 1;
        _isResting = false;
        _restSecondsRemaining = 0;
      });
      // Start set timer for the previous exercise
      _startSetTimer();
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _setTimer?.cancel();
    _workoutTimer?.cancel();
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
            // Overall Workout Timer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Workout Time: ${_formatTime(_workoutTotalSeconds)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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

            // Rest Timer (if resting) - Display similar to set timer
            if (_isResting) ...[
              Container(
                padding: const EdgeInsets.all(20),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isRestingBetweenExercises ? 'Rest Between Exercises' : 'Rest Timer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!_isRestingBetweenExercises)
                          Text(
                            'Set $_currentSet of $totalSets',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          )
                        else
                          Text(
                            'Next: ${_currentExerciseIndex < _exercises.length - 1 ? _getExerciseName(_currentExerciseIndex + 1) : "Complete"}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Remaining',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(_restSecondsRemaining),
                              style: const TextStyle(
                                color: Color(0xFFFF6B35),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        Column(
                          children: [
                            const Text(
                              'Recommended',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(_isRestingBetweenExercises
                                  ? _getRestBetweenExercises(_currentExerciseIndex)
                                  : _getRestSecondsForExercise(_currentExerciseIndex)),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                      label: Text(
                        _isRestingBetweenExercises ? 'Skip to Next Exercise' : 'Skip Rest',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Sets Progress
            if (!_isResting) ...[
              // Set Timer Display
              Container(
                padding: const EdgeInsets.all(20),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Set Timer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Set $_currentSet of $totalSets',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Elapsed',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(_setSecondsElapsed),
                              style: const TextStyle(
                                color: Color(0xFFFF6B35),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        Column(
                          children: [
                            const Text(
                              'Recommended',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(_estimateSetTime(_currentExerciseIndex)),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!_setTimerRunning) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _startSetTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: const Text(
                          'Start Set Timer',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
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

