import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/custom_workout_plan.dart';
import '../controllers/workout_counter_controller.dart';

class CustomWorkoutTimerScreen extends StatefulWidget {
  final CustomWorkoutPlan plan;

  const CustomWorkoutTimerScreen({super.key, required this.plan});

  @override
  State<CustomWorkoutTimerScreen> createState() => _CustomWorkoutTimerScreenState();
}

class _CustomWorkoutTimerScreenState extends State<CustomWorkoutTimerScreen> {
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  bool _isRestingBetweenExercises = false;
  bool _workoutCompleted = false;
  final Map<int, List<bool>> _completedSets = {};

  // Timer for tracking set duration
  Timer? _setTimer;
  int _setSecondsElapsed = 0;
  bool _setTimerRunning = false;
  DateTime? _setStartTime;

  // Overall workout timer
  Timer? _workoutTimer;
  int _workoutTotalSeconds = 0;
  DateTime? _workoutStartTime;
  DateTime? _workoutEndTime;

  @override
  void initState() {
    super.initState();
    _initializeExercises();
    _startWorkoutTimer();
  }

  void _initializeExercises() {
    for (int i = 0; i < widget.plan.exercises.length; i++) {
      _completedSets[i] = List.filled(widget.plan.exercises[i].sets, false);
    }

    if (widget.plan.exercises.isEmpty) {
      _workoutCompleted = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startSetTimer();
        }
      });
    }
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

  void _completeSet() {
    if (_currentExerciseIndex >= widget.plan.exercises.length) return;

    final completedSets = _completedSets[_currentExerciseIndex] ?? [];
    if (_currentSet <= completedSets.length) {
      completedSets[_currentSet - 1] = true;
      _completedSets[_currentExerciseIndex] = completedSets;
    }

    _stopSetTimer();

    final totalSets = widget.plan.exercises[_currentExerciseIndex].sets;

    if (_currentSet < totalSets) {
      _startRestTimer(isBetweenExercises: false);
    } else {
      if (_currentExerciseIndex < widget.plan.exercises.length - 1) {
        _startRestTimer(isBetweenExercises: true);
      } else {
        _completeWorkout();
      }
    }
  }

  void _startRestTimer({required bool isBetweenExercises}) {
    final restSeconds = isBetweenExercises
        ? widget.plan.exercises[_currentExerciseIndex].restBetweenExercises
        : widget.plan.exercises[_currentExerciseIndex].restSeconds;

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
            _moveToNextExercise();
          } else {
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
      _moveToNextExercise();
    } else {
      _currentSet++;
      _startSetTimer();
    }
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < widget.plan.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _isResting = false;
        _isRestingBetweenExercises = false;
        _restSecondsRemaining = 0;
      });
      _startSetTimer();
    } else {
      _completeWorkout();
    }
  }

  void _completeWorkout() {
    _restTimer?.cancel();
    _setTimer?.cancel();
    _workoutTimer?.cancel();
    _workoutEndTime = DateTime.now();

    final completionTime = _workoutEndTime!.difference(_workoutStartTime!);
    
    // Update workout completion stats
    if (mounted) {
      try {
        final controller = context.read<WorkoutCounterController>();
        controller.updateWorkoutCompletion(widget.plan.id, completionTime);
      } catch (e) {
        debugPrint('Error updating workout completion: $e');
      }
    }

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
      final completionTime = _workoutEndTime!.difference(_workoutStartTime!);
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
                'You completed ${widget.plan.exercises.length} exercises',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Time: ${_formatTime(completionTime.inSeconds)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                icon: const Icon(Icons.done, color: Colors.white),
                label: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.plan.exercises.isEmpty) {
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

    final totalSets = widget.plan.exercises[_currentExerciseIndex].sets;
    final reps = widget.plan.exercises[_currentExerciseIndex].reps;
    final exerciseName = widget.plan.exercises[_currentExerciseIndex].name;
    final instructions = widget.plan.exercises[_currentExerciseIndex].instructions ?? '';
    final completedSetsForExercise = _completedSets[_currentExerciseIndex] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: Text(
          'Exercise ${_currentExerciseIndex + 1} of ${widget.plan.exercises.length}',
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

            // Rest Timer (if resting)
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
                        Text(
                          _isRestingBetweenExercises
                              ? 'Next: ${_currentExerciseIndex < widget.plan.exercises.length - 1 ? widget.plan.exercises[_currentExerciseIndex + 1].name : "Complete"}'
                              : 'Set $_currentSet of $totalSets',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

            // Set Timer Display
            if (!_isResting) ...[
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
                    Text(
                      _formatTime(_setSecondsElapsed),
                      style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
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
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
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
                    value: (_currentExerciseIndex + 1) / widget.plan.exercises.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_currentExerciseIndex + 1} / ${widget.plan.exercises.length} exercises',
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

