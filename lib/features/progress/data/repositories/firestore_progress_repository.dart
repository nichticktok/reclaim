import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recalim/core/models/progress_model.dart';
import '../../domain/repositories/progress_repository.dart';

/// Firestore implementation of ProgressRepository
class FirestoreProgressRepository implements ProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<ProgressModel> getTodayProgress(String userId) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Get all habits for the user
    final habitsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .get();

    final totalHabits = habitsSnapshot.docs.length;
    int completedHabits = 0;
    int verifiedHabits = 0;

    // Check today's completion status for each habit
    for (var doc in habitsSnapshot.docs) {
      final data = doc.data();
      final dailyCompletion = data['dailyCompletion'] as Map<String, dynamic>? ?? {};
      final proofs = data['proofs'] as Map<String, dynamic>? ?? {};
      
      if (dailyCompletion[todayStr] == true) {
        completedHabits++;
        // Check if proof exists for today
        if (proofs[todayStr] != null && proofs[todayStr].toString().isNotEmpty) {
          verifiedHabits++;
        }
      }
    }

    // Create or update progress model
    final progress = ProgressModel(
      id: todayStr,
      userId: userId,
      date: today,
      totalHabits: totalHabits,
      completedHabits: completedHabits,
      verifiedHabits: verifiedHabits,
    );
    
    progress.calculateSuccessRate();

    // Save to Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(todayStr)
        .set(progress.toJson(), SetOptions(merge: true));

    return progress;
  }

  @override
  Future<List<ProgressModel>> getProgressHistory(String userId, {int days = 7}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProgressModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> updateProgress(ProgressModel progress) async {
    final todayStr = '${progress.date.year}-${progress.date.month.toString().padLeft(2, '0')}-${progress.date.day.toString().padLeft(2, '0')}';

    await _firestore
        .collection('users')
        .doc(progress.userId)
        .collection('progress')
        .doc(todayStr)
        .set(progress.toJson(), SetOptions(merge: true));
  }

  @override
  Future<int> getCurrentStreak(String userId) async {
    // Calculate streak from daily completion data in habits
    final habitsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .get();

    if (habitsSnapshot.docs.isEmpty) return 0;

    // Get all habits and check daily completion
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    while (true) {
      final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      bool allCompleted = true;
      
      // Check if all habits were completed on this date
      for (var doc in habitsSnapshot.docs) {
        final data = doc.data();
        final dailyCompletion = data['dailyCompletion'] as Map<String, dynamic>? ?? {};
        if (dailyCompletion[dateStr] != true) {
          allCompleted = false;
          break;
        }
      }
      
      if (allCompleted && habitsSnapshot.docs.isNotEmpty) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  @override
  Future<int> getLongestStreak(String userId) async {
    // Calculate longest streak from progress history
    final habitsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .get();

    if (habitsSnapshot.docs.isEmpty) return 0;

    // Get all progress documents
    final progressSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .orderBy('date', descending: true)
        .get();

    if (progressSnapshot.docs.isEmpty) return 0;

    int longestStreak = 0;
    int currentStreak = 0;
    
    for (var doc in progressSnapshot.docs) {
      final data = doc.data();
      final completedHabits = data['completedHabits'] ?? 0;
      final totalHabits = data['totalHabits'] ?? 0;
      
      // Consider a day successful if all habits completed
      if (totalHabits > 0 && completedHabits == totalHabits) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    return longestStreak;
  }

  @override
  Future<int> getTotalCompletedTasks(String userId) async {
    // Count all completed tasks across all days from dailyCompletion maps
    final habitsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .get();

    int totalCompleted = 0;
    
    for (var doc in habitsSnapshot.docs) {
      final data = doc.data();
      final dailyCompletion = data['dailyCompletion'] as Map<String, dynamic>? ?? {};
      // Count all true values (completed days)
      totalCompleted += dailyCompletion.values.where((v) => v == true).length;
    }

    return totalCompleted;
  }
}

