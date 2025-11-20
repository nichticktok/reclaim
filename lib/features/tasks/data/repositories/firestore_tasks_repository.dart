import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/habit_model.dart';
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

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          return HabitModel.fromMap({
            ...data,
            'id': doc.id,
          });
        })
        .toList();
  }

  @override
  Future<void> initializeDefaultTasks(String userId, Map<String, dynamic> onboardingData) async {
    // Check if user already has tasks
    final existingTasks = await getHabits(userId);
    if (existingTasks.isNotEmpty) {
      return; // User already has tasks, don't initialize
    }

    final hardModeEnabled = onboardingData['hardModeEnabled'] as bool? ?? false;
    final habitsData = onboardingData['habitsData'] as Map<String, dynamic>? ?? {};
    final extraTasks = onboardingData['extraTasks'] as List<dynamic>? ?? [];
    
    final defaultTasks = <HabitModel>[];

    // Create tasks based on onboarding habits data (mark as preset)
    if (habitsData.containsKey('wake_up')) {
      final wakeTime = habitsData['wake_up'] as String? ?? '7:00 AM';
      defaultTasks.add(HabitModel(
        id: '', // Will be set by Firestore
        title: 'Wake up at $wakeTime',
        description: 'Start your day with purpose',
        scheduledTime: wakeTime,
        requiresProof: hardModeEnabled, // Proof required if hard mode
        isPreset: true, // Mark as preset task
      ));
    }

    if (habitsData.containsKey('water')) {
      final waterAmount = habitsData['water'] as String? ?? '2L';
      defaultTasks.add(HabitModel(
        id: '',
        title: 'Drink $waterAmount of water',
        description: 'Stay hydrated throughout the day',
        scheduledTime: '8:00 AM',
        requiresProof: false, // Water doesn't typically need proof
        isPreset: true, // Mark as preset task
      ));
    }

    if (habitsData.containsKey('exercise')) {
      defaultTasks.add(HabitModel(
        id: '',
        title: 'Exercise',
        description: 'Physical activity for health',
        scheduledTime: '6:00 PM',
        requiresProof: !hardModeEnabled, // Proof if NOT hard mode (hard mode will override)
        isPreset: true, // Mark as preset task
      ));
    }

    if (habitsData.containsKey('meditation')) {
      defaultTasks.add(HabitModel(
        id: '',
        title: 'Meditate',
        description: 'Mindfulness and mental clarity',
        scheduledTime: '7:00 AM',
        requiresProof: false,
        isPreset: true, // Mark as preset task
      ));
    }

    if (habitsData.containsKey('reading')) {
      defaultTasks.add(HabitModel(
        id: '',
        title: 'Read',
        description: 'Expand your knowledge',
        scheduledTime: '9:00 PM',
        requiresProof: !hardModeEnabled,
        isPreset: true, // Mark as preset task
      ));
    }

    // Add extra tasks from onboarding (these are user-added, not preset)
    for (var taskName in extraTasks) {
      defaultTasks.add(HabitModel(
        id: '',
        title: taskName.toString(),
        description: 'Custom task from onboarding',
        scheduledTime: '12:00 PM',
        requiresProof: hardModeEnabled,
        isPreset: false, // User-added task, can be deleted
      ));
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

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .doc(habit.id)
        .update(habit.toMap());
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

  /// Get today's date string (YYYY-MM-DD)
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<HabitModel>> getTodayHabits(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .orderBy('scheduledTime')
        .get();

    final today = _getTodayDateString();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final dailyCompletion = data['dailyCompletion'] as Map<String, dynamic>? ?? {};
      final isCompletedToday = dailyCompletion[today] == true;
      
      return HabitModel.fromMap({
        ...data,
        'id': doc.id,
        'completed': isCompletedToday, // Set completed based on today's status
      });
    }).toList();
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

