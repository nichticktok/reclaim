import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:recalim/core/models/habit_model.dart';
import '../../domain/repositories/tasks_repository.dart';

/// Firestore implementation of TasksRepository
class FirestoreTasksRepository implements TasksRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<HabitModel>> getHabits(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .orderBy('scheduledTime')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return HabitModel.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  @override
  Future<void> initializeDefaultTasks(
    String userId,
    Map<String, dynamic> onboardingData,
  ) async {
    // Check if user already has tasks
    final existingTasks = await getHabits(userId);
    if (existingTasks.isNotEmpty) {
      return; // User already has tasks, don't initialize
    }

    // Check if in debug mode (onboarding was skipped)

    final hardModeEnabled = onboardingData['hardModeEnabled'] as bool? ?? false;
    final defaultTasks = <HabitModel>[];

    // DEBUG MODE: Create 3 default tasks (2 without proof, 1 with proof)
    // This happens when onboarding is skipped in debug mode
    if (kDebugMode &&
        (onboardingData.isEmpty || !onboardingData.containsKey('habitsData'))) {
      defaultTasks.addAll([
        HabitModel(
          id: '',
          title: 'Wake up at 7:00 AM',
          description: 'Start your day with purpose',
          scheduledTime: '7:00 AM',
          requiresProof: false,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'easy',
          attribute: 'Discipline',
        ),
        HabitModel(
          id: '',
          title: 'Read for 30 minutes',
          description: 'Expand your knowledge',
          scheduledTime: '9:00 PM',
          requiresProof: false,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'medium',
          attribute: 'Wisdom',
        ),
        HabitModel(
          id: '',
          title: 'Exercise for 30 minutes',
          description: 'Physical activity for health',
          scheduledTime: '6:00 PM',
          requiresProof: true,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'medium',
          attribute: 'Strength',
        ),
      ]);
    } else {
      // NORMAL MODE: Create 3 tasks based on onboarding data (1 easy, 1 medium, 1 hard)
      final habitsData =
          onboardingData['habitsData'] as Map<String, dynamic>? ?? {};
      final commitmentLevel =
          onboardingData['commitmentLevel'] as String? ?? '50';
      final commitment = int.tryParse(commitmentLevel) ?? 50;

      // Determine task difficulty based on commitment level and onboarding answers
      // Higher commitment = more challenging tasks
      final taskPool = _generateTaskPool(
        habitsData,
        commitment,
        hardModeEnabled,
      );

      // Select 3 tasks: 1 easy, 1 medium, 1 hard
      final easyTasks = taskPool
          .where((t) => t.difficulty == 'easy')
          .take(1)
          .toList();
      final mediumTasks = taskPool
          .where((t) => t.difficulty == 'medium')
          .take(1)
          .toList();
      final hardTasks = taskPool
          .where((t) => t.difficulty == 'hard')
          .take(1)
          .toList();

      defaultTasks.addAll([...easyTasks, ...mediumTasks, ...hardTasks]);

      // If we don't have enough tasks, fill with defaults
      while (defaultTasks.length < 3) {
        defaultTasks.add(
          HabitModel(
            id: '',
            title: 'Complete daily task',
            description: 'Stay consistent with your goals',
            scheduledTime: '12:00 PM',
            requiresProof: hardModeEnabled,
            isPreset: true,
            isSystemAssigned: true,
            difficulty: defaultTasks.isEmpty
                ? 'easy'
                : defaultTasks.length == 1
                ? 'medium'
                : 'hard',
            attribute: 'Discipline',
          ),
        );
      }
    }

    // Apply hard mode: if enabled, all tasks require proof
    if (hardModeEnabled) {
      for (var task in defaultTasks) {
        task.requiresProof = true;
      }
    }

    // Save all default tasks
    final batch = _firestore.batch();
    for (var task in defaultTasks) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc();
      batch.set(docRef, task.toMap());
    }
    await batch.commit();
  }

  /// Generate a pool of tasks based on onboarding data and commitment level
  List<HabitModel> _generateTaskPool(
    Map<String, dynamic> habitsData,
    int commitment,
    bool hardModeEnabled,
  ) {
    final tasks = <HabitModel>[];

    // Easy tasks (low commitment threshold)
    if (habitsData.containsKey('wake_up')) {
      final wakeTime = habitsData['wake_up'] as String? ?? '7:00 AM';
      tasks.add(
        HabitModel(
          id: '',
          title: 'Wake up at $wakeTime',
          description: 'Start your day with purpose',
          scheduledTime: wakeTime,
          requiresProof: false,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'easy',
          attribute: 'Discipline',
        ),
      );
    }

    if (habitsData.containsKey('water')) {
      final waterAmount = habitsData['water'] as String? ?? '2L';
      tasks.add(
        HabitModel(
          id: '',
          title: 'Drink $waterAmount of water',
          description: 'Stay hydrated throughout the day',
          scheduledTime: '8:00 AM',
          requiresProof: false,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'easy',
          attribute: 'Discipline',
        ),
      );
    }

    // Medium tasks (moderate commitment)
    if (habitsData.containsKey('reading')) {
      tasks.add(
        HabitModel(
          id: '',
          title: 'Read for 30 minutes',
          description: 'Expand your knowledge',
          scheduledTime: '9:00 PM',
          requiresProof: commitment > 60,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'medium',
          attribute: 'Wisdom',
        ),
      );
    }

    if (habitsData.containsKey('exercise')) {
      tasks.add(
        HabitModel(
          id: '',
          title: 'Exercise for 30 minutes',
          description: 'Physical activity for health',
          scheduledTime: '6:00 PM',
          requiresProof: commitment > 50,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'medium',
          attribute: 'Strength',
        ),
      );
    }

    // Hard tasks (high commitment)
    if (habitsData.containsKey('meditation')) {
      tasks.add(
        HabitModel(
          id: '',
          title: 'Meditate for 15 minutes',
          description: 'Mindfulness and mental clarity',
          scheduledTime: '7:00 AM',
          requiresProof: commitment > 40,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'hard',
          attribute: 'Focus',
        ),
      );
    }

    // Add more tasks based on commitment level
    if (commitment > 70) {
      tasks.add(
        HabitModel(
          id: '',
          title: 'Cold shower',
          description: 'Build mental resilience',
          scheduledTime: '6:30 AM',
          requiresProof: true,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'hard',
          attribute: 'Strength',
        ),
      );
    }

    if (commitment > 60) {
      tasks.add(
        HabitModel(
          id: '',
          title: 'Journal for 10 minutes',
          description: 'Reflect on your day',
          scheduledTime: '10:00 PM',
          requiresProof: false,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'medium',
          attribute: 'Wisdom',
        ),
      );
    }

    // Ensure we have at least some tasks
    if (tasks.isEmpty) {
      tasks.addAll([
        HabitModel(
          id: '',
          title: 'Wake up at 7:00 AM',
          description: 'Start your day with purpose',
          scheduledTime: '7:00 AM',
          requiresProof: false,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'easy',
          attribute: 'Discipline',
        ),
        HabitModel(
          id: '',
          title: 'Drink 2L of water',
          description: 'Stay hydrated',
          scheduledTime: '8:00 AM',
          requiresProof: false,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'easy',
          attribute: 'Discipline',
        ),
        HabitModel(
          id: '',
          title: 'Exercise',
          description: 'Physical activity',
          scheduledTime: '6:00 PM',
          requiresProof: hardModeEnabled,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'medium',
          attribute: 'Strength',
        ),
        HabitModel(
          id: '',
          title: 'Read',
          description: 'Expand knowledge',
          scheduledTime: '9:00 PM',
          requiresProof: hardModeEnabled,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'medium',
          attribute: 'Wisdom',
        ),
        HabitModel(
          id: '',
          title: 'Meditate',
          description: 'Mindfulness practice',
          scheduledTime: '7:00 AM',
          requiresProof: hardModeEnabled,
          isPreset: true,
          isSystemAssigned: true,
          difficulty: 'hard',
          attribute: 'Focus',
        ),
      ]);
    }

    return tasks;
  }

  @override
  Future<HabitModel> getHabitById(String habitId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .get();

    if (!doc.exists) throw Exception('Habit not found');

    return HabitModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .add(habit.toMap());
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Validate that habit has an ID
    if (habit.id.isEmpty) {
      debugPrint('⚠️ Cannot update habit with empty ID. Creating new habit instead.');
      // If ID is empty, create a new habit instead
      await addHabit(habit);
      return;
    }

    // Get the map and remove 'id' field (Firestore doesn't allow updating document ID)
    final habitMap = habit.toMap();
    habitMap.remove('id');

    // Debug: Log what we're updating
    debugPrint('🔄 Updating habit ${habit.id} with deletionStatus: ${habit.deletionStatus}');
    debugPrint('📦 Update map keys: ${habitMap.keys.toList()}');
    debugPrint('📦 deletionStatus in map: ${habitMap['deletionStatus']}');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habit.id)
        .update(habitMap);
    
    debugPrint('✅ Successfully updated habit ${habit.id} in Firestore');
  }

  @override
  Future<void> deleteHabit(String habitId, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Delete the habit
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .delete();

    // Save deletion reason to user preferences for future reference
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('preferences')
        .set({
          'lastDeletionReason': reason,
          'lastDeletionDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// Get the last deletion reason
  Future<String?> getLastDeletionReason(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .get();

    if (doc.exists) {
      return doc.data()?['lastDeletionReason'] as String?;
    }
    return null;
  }

  @override
  Future<void> completeHabit(String habitId, {String? proof}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final today = _getTodayDateString();
    final updates = <String, dynamic>{
      'completed': true,
      'lastCompletedAt': FieldValue.serverTimestamp(),
      'dailyCompletion.$today': true,
      'dailySkipped.$today': false, // Clear skip if completing
    };

    if (proof != null) {
      updates['proofs.$today'] = proof;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .update(updates);
  }

  @override
  Future<void> skipHabit(String habitId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final today = _getTodayDateString();
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .update({
          'dailySkipped.$today': true,
          'dailyCompletion.$today': false, // Clear completion if skipping
        });
  }

  /// Get today's date string (YYYY-MM-DD)
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<HabitModel>> getTodayHabits(String userId) async {
    // Note: Despite the name "getTodayHabits", this method returns ALL habits
    // The filtering by date happens in the UI layer (daily_tasks_screen.dart)
    // This allows users to view tasks for any date (today, past, or future)
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .orderBy('scheduledTime')
        .get();

    final today = _getTodayDateString();

    final habits = snapshot.docs.map((doc) {
      final data = doc.data();
      final dailyCompletion =
          data['dailyCompletion'] as Map<String, dynamic>? ?? {};
      final dailySkipped = data['dailySkipped'] as Map<String, dynamic>? ?? {};
      final isCompletedToday = dailyCompletion[today] == true;

      return HabitModel.fromMap({
        ...data,
        'id': doc.id,
        'completed': isCompletedToday, // Set completed based on today's status
        'dailySkipped': dailySkipped, // Include skipped status
      });
    }).toList();

    // Return ALL habits - filtering by selected date happens in the UI
    return habits;
  }

  @override
  Future<void> submitProof(String habitId, String proof) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final today = _getTodayDateString();
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .update({
          'proofs.$today': proof,
          'dailyCompletion.$today': true,
          'lastCompletedAt': FieldValue.serverTimestamp(),
          'completed': true,
        });
  }

  @override
  Future<void> undoCompleteHabit(String habitId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final today = _getTodayDateString();
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habitId)
        .update({
          'dailyCompletion.$today': FieldValue.delete(),
          'proofs.$today': FieldValue.delete(),
          'completed': false,
        });
  }
}
