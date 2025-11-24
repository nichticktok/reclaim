import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'attribute_calculator.dart';
import 'package:recalim/core/models/habit_model.dart';
import '../../features/progress/data/repositories/firestore_user_stats_repository.dart';

/// Service that computes user attributes from app data
/// Bridges the gap between app data models and AttributeCalculator
class AttributeService {
  final AttributeCalculator _calculator;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AttributeService({
    AttributeCalculator? calculator,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _calculator = calculator ?? AttributeCalculator(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Calculate attributes from current user data
  Future<Map<String, double>> calculateUserAttributes() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    // Collect all metrics
    final metrics = await _collectMetrics(user.uid);

    // Calculate attributes
    return _calculator.calculate(metrics);
  }

  /// Collect all raw metrics from various data sources
  Future<Map<String, double>> _collectMetrics(String userId) async {
    final metrics = <String, double>{};

    try {
      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      // Get stats
      final statsRepo = FirestoreUserStatsRepository();
      final stats = await statsRepo.getUserStats(userId);

      // Task metrics
      metrics['tasksCompleted'] = stats.totalTasksCompleted.toDouble();
      metrics['currentStreak'] = stats.currentStreak.toDouble();
      metrics['longestStreak'] = stats.longestStreak.toDouble();

      // Get habits to calculate completion rate
      final habitsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .get();

      final habits = habitsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return HabitModel.fromMap({
              ...data,
              'id': doc.id,
            });
          })
          .toList();

      // Calculate task completion rate (last 7 days)
      metrics['taskCompletionRate'] = _calculateCompletionRate(habits);

      // Calculate consistency score
      metrics['consistencyScore'] = _calculateConsistencyScore(habits);

      // Count proofs submitted
      metrics['proofSubmitted'] = _countProofs(habits).toDouble();

      // Time-based metrics (from user data or habits)
      metrics['workoutMinutes'] =
          (userData['totalWorkoutMinutes'] ?? 0).toDouble();
      metrics['meditationMinutes'] =
          (userData['totalMeditationMinutes'] ?? 0).toDouble();
      metrics['readingMinutes'] =
          (userData['totalReadingMinutes'] ?? 0).toDouble();

      // Quality metrics
      metrics['sleepQuality'] =
          (userData['averageSleepQuality'] ?? 70.0).toDouble();

      // Engagement metrics
      metrics['socialInteractions'] =
          (userData['socialInteractions'] ?? 0).toDouble();
      metrics['reflectionCount'] =
          (userData['reflectionCount'] ?? 0).toDouble();
      metrics['achievementsUnlocked'] =
          (userData['achievementsUnlocked'] ?? 0).toDouble();
    } catch (e) {
      // Log error but continue with partial metrics
      debugPrint('Error collecting metrics: $e');
    }

    return metrics;
  }

  /// Calculate task completion rate for last 7 days
  double _calculateCompletionRate(List<HabitModel> habits) {
    if (habits.isEmpty) return 0.0;

    final now = DateTime.now();
    int totalTasks = 0;
    int completedTasks = 0;

    for (var i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = HabitModel.getDateString(date);

      for (var habit in habits) {
        totalTasks++;
        if (habit.dailyCompletion[dateStr] == true) {
          completedTasks++;
        }
      }
    }

    return totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
  }

  /// Calculate consistency score (how consistent user is)
  double _calculateConsistencyScore(List<HabitModel> habits) {
    if (habits.isEmpty) return 0.0;

    final now = DateTime.now();
    int daysWithTasks = 0;
    int totalDays = 0;

    for (var i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = HabitModel.getDateString(date);

      bool hasCompletedTask = false;
      for (var habit in habits) {
        if (habit.dailyCompletion[dateStr] == true) {
          hasCompletedTask = true;
          break;
        }
      }

      if (hasCompletedTask) {
        daysWithTasks++;
      }
      totalDays++;
    }

    return totalDays > 0 ? (daysWithTasks / totalDays) : 0.0;
  }

  /// Count total proofs submitted
  int _countProofs(List<HabitModel> habits) {
    int count = 0;
    for (var habit in habits) {
      for (var proof in habit.proofs.values) {
        if (proof.isNotEmpty) {
          count++;
        }
      }
    }
    return count;
  }

  /// Update user's ratings in Firestore
  Future<void> updateUserRatings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final attributes = await calculateUserAttributes();

    await _firestore.collection('users').doc(user.uid).update({
      'ratings': attributes,
      'ratingsUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}

