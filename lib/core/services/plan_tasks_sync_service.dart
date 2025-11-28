import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recalim/core/models/habit_model.dart';
import 'package:recalim/core/constants/proof_types.dart';
import '../../features/tasks/domain/repositories/tasks_repository.dart';
import '../../features/tasks/data/repositories/firestore_tasks_repository.dart';
import '../../features/projects/data/repositories/firestore_plan_repository.dart';

/// Service to sync workout and project plans into daily tasks
class PlanTasksSyncService {
  final TasksRepository _tasksRepository = FirestoreTasksRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sync workout plan days to daily tasks
  Future<void> syncWorkoutPlanToTasks(String workoutPlanId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      // Get workout plan and days
      final planDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_plans')
          .doc(workoutPlanId)
          .get();

      if (!planDoc.exists) return;

      final planData = planDoc.data()!;
      final planTitle = planData['goalType'] as String? ?? 'Workout Plan';
      final minutesPerSession = planData['minutesPerSession'] as int? ?? 30;

      // Get workout days
      final daysSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_plans')
          .doc(workoutPlanId)
          .collection('workout_days')
          .orderBy('scheduledDate')
          .get();

      final existingHabits = await _tasksRepository.getHabits(user.uid);
      final habits = <HabitModel>[];

      for (var dayDoc in daysSnapshot.docs) {
        final dayData = dayDoc.data();
        final scheduledDate = (dayData['scheduledDate'] as Timestamp).toDate();
        final dayLabel = dayData['dayLabel'] as String? ?? 'Workout';
        final focus = dayData['focus'] as String? ?? '';

        // Get exercises for this day
        final exercisesSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workout_plans')
            .doc(workoutPlanId)
            .collection('workout_days')
            .doc(dayDoc.id)
            .collection('exercises')
            .get();

        final exercises = exercisesSnapshot.docs.map((e) {
          final data = e.data();
          return {
            'name': data['name'] ?? '',
            'sets': data['sets'] ?? 3,
            'reps': data['reps'] ?? '10',
            'restSeconds': data['restSeconds'] ?? 60,
            'restBetweenExercises': data['restBetweenExercises'] ?? 90,
            'instructions': data['instructions'] ?? '',
          };
        }).toList();

        const taskTitle = 'Workout';
        final taskDescription = '$dayLabel • ${focus.isEmpty ? 'Follow the plan' : focus}';
        final dateKey = HabitModel.getDateString(scheduledDate);

        final metadataPayload = {
          'type': 'workout',
          'planId': workoutPlanId,
          'planTitle': planTitle,
          'workoutDayId': dayDoc.id,
          'dayLabel': dayLabel,
          'focus': focus,
          'scheduledDate': scheduledDate.toIso8601String(),
          'dueDate': scheduledDate.toIso8601String(), // Add dueDate like project tasks
          'dateKey': dateKey,
          'minutesPerSession': minutesPerSession,
          'exercises': exercises,
        };

        final existingHabit = _findExistingWorkoutHabit(
          existingHabits,
          dateKey,
          dayLabel,
        );

        if (existingHabit != null) {
          final updatedHabit = existingHabit.copyWith(
            title: taskTitle,
            description: taskDescription,
            scheduledTime: _getTimeFromDate(scheduledDate, isWorkout: true),
            specificDate: scheduledDate, // Update specificDate
            daysOfWeek: [], // Empty since using specificDate
            metadata: metadataPayload,
          );
          await _tasksRepository.updateHabit(updatedHabit);

          final index =
              existingHabits.indexWhere((habit) => habit.id == existingHabit.id);
          if (index != -1) {
            existingHabits[index] = updatedHabit;
          }
          continue;
        }

        final habit = HabitModel(
          id: '',
          title: taskTitle,
          description: taskDescription,
          scheduledTime: _getTimeFromDate(scheduledDate, isWorkout: true),
          requiresProof: true, // Workouts require proof
          isPreset: false,
          isSystemAssigned: true,
          difficulty: 'medium',
          attribute: 'Strength',
          createdAt: scheduledDate,
          specificDate: scheduledDate, // Use specificDate for date-specific tasks
          daysOfWeek: [], // Empty since using specificDate
          metadata: metadataPayload,
        );

        habits.add(habit);
        existingHabits.add(habit);
      }

      // Save all habits
      for (var habit in habits) {
        await _tasksRepository.addHabit(habit);
      }

      debugPrint('✅ Synced ${habits.length} workout days to daily tasks');
    } catch (e) {
      debugPrint('❌ Error syncing workout plan to tasks: $e');
      rethrow;
    }
  }

  /// Sync project tasks to daily tasks
  Future<void> syncProjectToTasks(String projectId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      // Get project
      final projectDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(projectId)
          .get();

      if (!projectDoc.exists) return;

      final projectData = projectDoc.data()!;
      final projectTitle = projectData['title'] as String? ?? 'Project';
      final projectCategory = projectData['category'] as String? ?? 'general';

      // Get milestones
      final milestonesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .orderBy('order')
          .get();

      final existingHabits = await _tasksRepository.getHabits(user.uid);
      final habits = <HabitModel>[];

      for (var milestoneDoc in milestonesSnapshot.docs) {
        final milestoneData = milestoneDoc.data();
        final milestoneTitle = milestoneData['title'] as String? ?? 'Milestone';

        // Get tasks for this milestone
        // Note: We can't use isNotEqualTo with orderBy without an index, so we filter in memory
        final tasksSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('projects')
            .doc(projectId)
            .collection('milestones')
            .doc(milestoneDoc.id)
            .collection('tasks')
            .orderBy('dueDate')
            .get();
        
        // Filter out completed tasks in memory
        final incompleteTasks = tasksSnapshot.docs.where((doc) {
          final status = doc.data()['status'] as String?;
          return status != 'done';
        }).toList();

        for (var taskDoc in incompleteTasks) {
          final taskData = taskDoc.data();
          final taskTitle = taskData['title'] as String? ?? 'Task';
          final taskDescription = taskData['description'] as String? ?? '';
          final dueDate = (taskData['dueDate'] as Timestamp).toDate();
          final estimatedHours = taskData['estimatedHours'] as double? ?? 0.0;
          
          // Get project proof type information
          final suggestedProofType = taskData['suggestedProofType'] as String?;
          final alternativeProofTypes = taskData['alternativeProofTypes'] as List<dynamic>?;
          final proofMechanism = taskData['proofMechanism'] as String?;
          final requiresProof = taskData['requiresProof'] as bool? ?? true;
          final requiresPeerApproval = taskData['requiresPeerApproval'] as bool? ?? false;

          final metadataPayload = {
            'type': 'project',
            'projectId': projectId,
            'projectTitle': projectTitle,
            'milestoneId': milestoneDoc.id,
            'milestoneTitle': milestoneTitle,
            'taskId': taskDoc.id,
            'dueDate': dueDate.toIso8601String(),
            'dateKey': HabitModel.getDateString(dueDate),
            'estimatedHours': estimatedHours,
            'projectCategory': projectCategory,
            // Store project proof type information
            if (suggestedProofType != null) 'suggestedProofType': suggestedProofType,
            if (alternativeProofTypes != null) 'alternativeProofTypes': alternativeProofTypes.map((e) => e.toString()).toList(),
            if (proofMechanism != null) 'proofMechanism': proofMechanism,
            'requiresProof': requiresProof,
            'requiresPeerApproval': requiresPeerApproval,
          };

          final existingHabit = _findExistingProjectHabit(
            existingHabits,
            metadataPayload['taskId'] as String,
            metadataPayload['dateKey'] as String,
            projectTitle,
            taskTitle,
          );

          if (existingHabit != null) {
            final updatedHabit = existingHabit.copyWith(
              description: taskDescription.isNotEmpty
                  ? '$taskDescription ($projectTitle - $milestoneTitle)'
                  : 'Complete task from $projectTitle - $milestoneTitle',
              scheduledTime: _getTimeFromDate(dueDate),
              specificDate: dueDate, // Update specificDate
              daysOfWeek: [], // Empty since using specificDate
              requiresProof: requiresProof,
              metadata: metadataPayload,
            );
            await _tasksRepository.updateHabit(updatedHabit);

            final index =
                existingHabits.indexWhere((habit) => habit.id == existingHabit.id);
            if (index != -1) {
              existingHabits[index] = updatedHabit;
            }
            continue;
          }

          final fullDescription = taskDescription.isNotEmpty
              ? '$taskDescription ($projectTitle - $milestoneTitle)'
              : 'Complete task from $projectTitle - $milestoneTitle';

          final habit = HabitModel(
            id: '',
            title: taskTitle,
            description: fullDescription,
            scheduledTime: _getTimeFromDate(dueDate),
            requiresProof: requiresProof, // Use project task's requiresProof setting
            isPreset: false,
            isSystemAssigned: true,
            difficulty: estimatedHours >= 3.0
                ? 'hard'
                : estimatedHours >= 1.5
                    ? 'medium'
                    : 'easy',
            attribute: 'Focus',
            createdAt: dueDate,
            specificDate: dueDate, // Use specificDate for date-specific tasks
            daysOfWeek: [], // Empty since using specificDate
            metadata: metadataPayload,
          );

          habits.add(habit);
          existingHabits.add(habit);
        }
      }

      // Save all habits
      for (var habit in habits) {
        await _tasksRepository.addHabit(habit);
      }

      debugPrint('✅ Synced ${habits.length} project tasks to daily tasks');
    } catch (e) {
      debugPrint('❌ Error syncing project to tasks: $e');
      rethrow;
    }
  }

  /// Get time string from date (defaults based on task type)
  String _getTimeFromDate(DateTime date, {bool isWorkout = false}) {
    // Default to 6 PM for workouts, 9 AM for project tasks
    return isWorkout ? '6:00 PM' : '9:00 AM';
  }

  HabitModel? _findExistingWorkoutHabit(
    List<HabitModel> habits,
    String dateKey,
    String? dayLabel,
  ) {
    for (final habit in habits) {
      final metadata = habit.metadata;
      final type = metadata['type'] as String?;
      final titleLower = habit.title.toLowerCase();
      final isWorkout = type == 'workout' || titleLower.contains('workout');
      if (!isWorkout) continue;

      final habitDateKey =
          metadata['dateKey'] as String? ?? HabitModel.getDateString(habit.createdAt);

      if (habitDateKey == dateKey) {
        return habit;
      }

      if (dayLabel != null && habit.description.contains(dayLabel)) {
        if (HabitModel.getDateString(habit.createdAt) == dateKey) {
          return habit;
        }
      }
    }
    return null;
  }

  HabitModel? _findExistingProjectHabit(
    List<HabitModel> habits,
    String taskId,
    String dateKey,
    String projectTitle,
    String taskTitle,
  ) {
    for (final habit in habits) {
      final metadata = habit.metadata;
      final type = metadata['type'] as String?;

      if (type == 'project' && metadata['taskId'] == taskId) {
        return habit;
      }

      if (type == null || type.isEmpty) {
        final sameTitle = habit.title == taskTitle;
        final sameDate = HabitModel.getDateString(habit.createdAt) == dateKey;
        if (sameTitle &&
            sameDate &&
            habit.description.contains(projectTitle)) {
          return habit;
        }
      }
    }
    return null;
  }

  /// Sync plan daily tasks to habits using specificDate field
  Future<void> syncPlanToTasks(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final planRepository = FirestorePlanRepository();
      final plan = await planRepository.getPlanById(planId);
      
      if (plan == null) {
        debugPrint('⚠️ Plan not found: $planId');
        return;
      }

      final existingHabits = await _tasksRepository.getHabits(user.uid);
      final habits = <HabitModel>[];

      // Iterate through all daily plans
      for (final dailyPlan in plan.dailyPlans) {
        // Iterate through tasks for each day
        for (final dailyTask in dailyPlan.tasks) {
          // Normalize taskDate to just the date part (no time) for consistent comparison
          final taskDate = dailyPlan.date;
          final normalizedTaskDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
          final dateKey = HabitModel.getDateString(normalizedTaskDate);

          // Check if habit already exists for this task on this date
          final existingHabit = _findExistingPlanHabit(
            existingHabits,
            planId,
            dailyTask.title,
            dateKey,
          );

          if (existingHabit != null) {
            // Only update if habit has a valid ID (is already saved in Firestore)
            if (existingHabit.id.isNotEmpty) {
              final updatedHabit = existingHabit.copyWith(
                title: dailyTask.title,
                description: dailyTask.description,
                scheduledTime: _getTimeFromDate(normalizedTaskDate),
                requiresProof: true, // All plan tasks require proof
                proofType: ProofTypes.text, // All plan tasks require text proof
                specificDate: normalizedTaskDate, // Use normalized date
                metadata: {
                  'type': 'plan',
                  'planId': planId,
                  'planTitle': plan.projectTitle,
                  'taskOrder': dailyTask.order,
                  'phase': dailyTask.phase,
                  'estimatedHours': dailyTask.estimatedHours,
                },
              );
              await _tasksRepository.updateHabit(updatedHabit);

              final index = existingHabits.indexWhere((h) => h.id == existingHabit.id);
              if (index != -1) {
                existingHabits[index] = updatedHabit;
              }
              continue;
            } else {
              // Habit exists in list but has no ID yet (not saved), skip and let it be created below
              debugPrint('⚠️ Existing habit found but has empty ID, will create new one');
            }
          }

          // Create new habit with specificDate (normalized to date only)
          final habit = HabitModel(
            id: '',
            title: dailyTask.title,
            description: dailyTask.description.isNotEmpty
                ? dailyTask.description
                : 'Task from ${plan.projectTitle}',
            scheduledTime: _getTimeFromDate(normalizedTaskDate),
            requiresProof: true, // All plan tasks require proof
            proofType: ProofTypes.text, // All plan tasks require text proof
            isPreset: false,
            isSystemAssigned: true,
            difficulty: dailyTask.estimatedHours >= 3.0
                ? 'hard'
                : dailyTask.estimatedHours >= 1.5
                    ? 'medium'
                    : 'easy',
            attribute: 'Focus',
            createdAt: DateTime.now(), // Set creation date to now so tasks appear immediately
            specificDate: normalizedTaskDate, // Use normalized date (date only, no time)
            daysOfWeek: [], // Empty daysOfWeek since we're using specificDate
            metadata: {
              'type': 'plan',
              'planId': planId,
              'planTitle': plan.projectTitle,
              'taskOrder': dailyTask.order,
              'phase': dailyTask.phase,
              'estimatedHours': dailyTask.estimatedHours,
            },
          );

          habits.add(habit);
          existingHabits.add(habit);
        }
      }

      // Save all new habits
      for (var habit in habits) {
        await _tasksRepository.addHabit(habit);
      }

      debugPrint('✅ Synced ${habits.length} plan tasks to daily habits');
    } catch (e) {
      debugPrint('❌ Error syncing plan to tasks: $e');
      rethrow;
    }
  }

  HabitModel? _findExistingPlanHabit(
    List<HabitModel> habits,
    String planId,
    String taskTitle,
    String dateKey,
  ) {
    for (final habit in habits) {
      final metadata = habit.metadata;
      final type = metadata['type'] as String?;

      // Check if it's a plan habit with same planId, title, and date
      if (type == 'plan' && metadata['planId'] == planId) {
        final habitDateKey = habit.specificDate != null
            ? HabitModel.getDateString(habit.specificDate!)
            : metadata['dateKey'] as String?;
        
        if (habit.title == taskTitle && habitDateKey == dateKey) {
          return habit;
        }
      }
    }
    return null;
  }
}

