import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recalim/core/models/progress_model.dart';
import 'package:recalim/core/models/user_stats_model.dart';
import 'package:recalim/core/models/habit_model.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../data/repositories/firestore_progress_repository.dart';
import '../../data/repositories/firestore_user_stats_repository.dart';

class ProgressController extends ChangeNotifier {
  final ProgressRepository _repository = FirestoreProgressRepository();
  final FirestoreUserStatsRepository _statsRepository = FirestoreUserStatsRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  ProgressModel? _currentProgress;
  UserStatsModel? _userStats;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _completedTasks = 0;
  bool _loading = false;
  bool _initialized = false; // Track if already initialized

  ProgressModel? get currentProgress => _currentProgress;
  UserStatsModel? get userStats => _userStats;
  int get currentStreak => _userStats?.currentStreak ?? _currentStreak;
  int get longestStreak => _userStats?.longestStreak ?? _longestStreak;
  int get completedTasks => _userStats?.totalTasksCompleted ?? _completedTasks;
  bool get loading => _loading;

  /// Initialize and load progress (only if not already initialized)
  Future<void> initialize({bool forceRefresh = false}) async {
    // Skip if already initialized unless force refresh
    if (_initialized && !forceRefresh) {
      debugPrint('📊 ProgressController already initialized, skipping...');
      return;
    }

    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load today's progress
        _currentProgress = await _repository.getTodayProgress(user.uid);
        
        // Load user stats from stats collection
        _userStats = await _statsRepository.getUserStats(user.uid);
        
        // Update stats if they're outdated or missing
        await _updateStatsFromProgress(user.uid);
        
        // Fallback to repository methods if stats not available
        if (_userStats == null || _userStats!.currentStreak == 0) {
          _currentStreak = await _repository.getCurrentStreak(user.uid);
          _longestStreak = await _repository.getLongestStreak(user.uid);
          _completedTasks = await _repository.getTotalCompletedTasks(user.uid);
        }
        
        _initialized = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update stats collection from current progress
  Future<void> _updateStatsFromProgress(String userId) async {
    try {
      final currentStreak = await _repository.getCurrentStreak(userId);
      final longestStreak = await _repository.getLongestStreak(userId);
      final completedTasks = await _repository.getTotalCompletedTasks(userId);
      final overallProgress = _currentProgress?.successRate ?? 0.0;

      await _statsRepository.updateStats(userId, {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak > (_userStats?.longestStreak ?? 0) 
            ? longestStreak 
            : (_userStats?.longestStreak ?? 0),
        'totalTasksCompleted': completedTasks,
        'overallProgress': overallProgress / 100.0,
      });

      // Reload stats
      _userStats = await _statsRepository.getUserStats(userId);
    } catch (e) {
      debugPrint('Error updating stats: $e');
    }
  }

  /// Calculate overall progress percentage
  double get overallProgress {
    if (_currentProgress == null || _currentProgress!.totalHabits == 0) {
      return 0.0;
    }
    return _currentProgress!.successRate / 100;
  }

  /// Calculate progress from current tasks list (lightweight, no database query)
  void calculateProgressFromTasks(List<HabitModel> habits) {
    final today = DateTime.now();
    final todayStr = HabitModel.getTodayDateString();
    
    int totalHabits = habits.length;
    int completedHabits = habits.where((h) => h.isCompletedToday()).length;
    int verifiedHabits = habits.where((h) {
      final proof = h.getTodayProof();
      return proof != null && proof.isNotEmpty;
    }).length;
    
    // Update current progress model
    _currentProgress = ProgressModel(
      id: todayStr,
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      date: today,
      totalHabits: totalHabits,
      completedHabits: completedHabits,
      verifiedHabits: verifiedHabits,
    );
    
    _currentProgress!.calculateSuccessRate();
    
    // Update stats in database (async, don't wait)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _updateProgressInDatabase(user.uid, totalHabits, completedHabits, verifiedHabits);
    }
    
    notifyListeners();
  }

  /// Update progress in database (async, non-blocking)
  Future<void> _updateProgressInDatabase(String userId, int totalHabits, int completedHabits, int verifiedHabits) async {
    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
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
      
      // Update overall progress in stats
      final progressPercent = totalHabits > 0 ? (completedHabits / totalHabits) : 0.0;
      await _statsRepository.updateOverallProgress(userId, progressPercent);
    } catch (e) {
      debugPrint('Error updating progress in database: $e');
    }
  }

  /// Refresh progress data (lightweight version that uses current tasks)
  Future<void> refresh({List<HabitModel>? currentTasks}) async {
    if (currentTasks != null) {
      // Fast path: calculate from current tasks in memory
      calculateProgressFromTasks(currentTasks);
      
      // Also refresh stats from database (async, non-blocking)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _refreshStatsFromDatabase(user.uid);
      }
    } else {
      // Fallback: full refresh from database
      await initialize(forceRefresh: true);
    }
  }

  /// Refresh stats from database (async, non-blocking)
  Future<void> _refreshStatsFromDatabase(String userId) async {
    try {
      _userStats = await _statsRepository.getUserStats(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing stats from database: $e');
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

