import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recalim/features/achievements/domain/entities/achievement_model.dart';
import 'package:recalim/core/models/habit_model.dart';

class AchievementsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<AchievementModel> _achievements = [];
  bool _loading = false;
  bool _initialized = false;

  List<AchievementModel> get achievements => _achievements;
  List<AchievementModel> get unlockedAchievements => _achievements.where((a) => a.isUnlocked).toList();
  List<AchievementModel> get inProgressAchievements => _achievements.where((a) => !a.isUnlocked && a.currentStreak > 0).toList();
  bool get loading => _loading;
  int get totalAchievements => _achievements.length;
  int get unlockedCount => unlockedAchievements.length;

  /// Initialize and load achievements
  Future<void> initialize({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) {
      debugPrint('🏆 AchievementsController already initialized, skipping...');
      return;
    }

    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _loadAchievements(user.uid);
        _initialized = true;
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load achievements from Firestore
  Future<void> _loadAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      _achievements = snapshot.docs
          .map((doc) => AchievementModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  /// Check and update achievement progress when a task is completed
  Future<void> checkAchievementsOnTaskCompletion(HabitModel habit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Calculate current consecutive streak for this task
      final streak = _calculateConsecutiveStreak(habit);
      
      // Check for achievement milestones (7, 14, 30 days)
      final milestones = [7, 14, 30];
      
      for (final days in milestones) {
        // Check if achievement exists for this task and milestone
        var achievement = _achievements.firstWhere(
          (a) => a.taskId == habit.id && a.requiredDays == days,
          orElse: () => AchievementModel(
            id: '',
            userId: user.uid,
            taskId: habit.id,
            taskTitle: habit.title,
            achievementType: 'consecutive_days',
            title: '',
            description: '',
            requiredDays: days,
          ),
        );

        // Get achievement details
        final achievementData = AchievementDefinitions.getAchievementForTask(habit.title, days);
        achievement.title = achievementData['title'] as String;
        achievement.description = achievementData['description'] as String;

        // Update streak
        achievement.currentStreak = streak;

        // Check if achievement should be unlocked
        if (streak >= days && !achievement.isUnlocked) {
          achievement.isUnlocked = true;
          achievement.unlockedAt = DateTime.now();
          
          // Save to Firestore
          await _saveAchievement(achievement);
          
          // Show notification (you can add a callback here)
          debugPrint('🎉 Achievement unlocked: ${achievement.title}');
        } else if (achievement.id.isEmpty && streak > 0) {
          // Create new achievement if it doesn't exist and user has started
          achievement.id = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('achievements')
              .doc()
              .id;
          await _saveAchievement(achievement);
        } else if (achievement.id.isNotEmpty) {
          // Update existing achievement
          await _saveAchievement(achievement);
        }
      }

      // Reload achievements
      await _loadAchievements(user.uid);
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  /// Calculate consecutive streak for a habit
  int _calculateConsecutiveStreak(HabitModel habit) {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    while (true) {
      final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      
      if (habit.dailyCompletion[dateStr] == true) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Save achievement to Firestore
  Future<void> _saveAchievement(AchievementModel achievement) async {
    try {
      await _firestore
          .collection('users')
          .doc(achievement.userId)
          .collection('achievements')
          .doc(achievement.id)
          .set(achievement.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving achievement: $e');
    }
  }

  /// Refresh achievements
  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadAchievements(user.uid);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

