import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/progress_model.dart';
import '../../../../models/user_stats_model.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../data/repositories/firestore_progress_repository.dart';
import '../../data/repositories/firestore_user_stats_repository.dart';

class ProgressController extends ChangeNotifier {
  final ProgressRepository _repository = FirestoreProgressRepository();
  final FirestoreUserStatsRepository _statsRepository = FirestoreUserStatsRepository();
  
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

  /// Refresh progress data
  Future<void> refresh() async {
    await initialize(forceRefresh: true);
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

