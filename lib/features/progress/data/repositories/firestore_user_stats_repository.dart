import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/user_stats_model.dart';

/// Repository for user statistics (streak, progress, etc.)
class FirestoreUserStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user stats
  Future<UserStatsModel> getUserStats(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('current')
        .get();

    if (doc.exists) {
      return UserStatsModel.fromJson({...doc.data()!, 'userId': userId});
    }

    // Create default stats
    final defaultStats = UserStatsModel(userId: userId);
    await updateUserStats(defaultStats);
    return defaultStats;
  }

  /// Update user stats
  Future<void> updateUserStats(UserStatsModel stats) async {
    await _firestore
        .collection('users')
        .doc(stats.userId)
        .collection('stats')
        .doc('current')
        .set(stats.toJson(), SetOptions(merge: true));
  }

  /// Update specific stat fields
  Future<void> updateStats(String userId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('current')
        .set({
      ...updates,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Increment total tasks completed
  Future<void> incrementTasksCompleted(String userId) async {
    final stats = await getUserStats(userId);
    await updateStats(userId, {
      'totalTasksCompleted': stats.totalTasksCompleted + 1,
    });
  }

  /// Decrement total tasks completed
  Future<void> decrementTasksCompleted(String userId) async {
    final stats = await getUserStats(userId);
    if (stats.totalTasksCompleted > 0) {
      await updateStats(userId, {
        'totalTasksCompleted': stats.totalTasksCompleted - 1,
      });
    }
  }

  /// Update current streak
  Future<void> updateCurrentStreak(String userId, int streak) async {
    final stats = await getUserStats(userId);
    await updateStats(userId, {
      'currentStreak': streak,
      'longestStreak': streak > stats.longestStreak ? streak : stats.longestStreak,
    });
  }

  /// Update overall progress (0.0 to 1.0)
  Future<void> updateOverallProgress(String userId, double progress) async {
    await updateStats(userId, {
      'overallProgress': progress.clamp(0.0, 1.0),
    });
  }
}

