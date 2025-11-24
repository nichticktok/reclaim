import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  String id;
  String userId;
  String taskId; // The habit/task this achievement is for
  String taskTitle; // Title of the task
  String achievementType; // 'consecutive_days', 'total_completions', etc.
  String title; // Achievement title (e.g., "Early Riser")
  String description; // Achievement description
  int requiredDays; // Days required to unlock (e.g., 7 for "Early Riser")
  int currentStreak; // Current consecutive days completed
  bool isUnlocked; // Whether the achievement has been unlocked
  DateTime? unlockedAt; // When the achievement was unlocked
  DateTime createdAt;

  AchievementModel({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.taskTitle,
    required this.achievementType,
    required this.title,
    required this.description,
    required this.requiredDays,
    this.currentStreak = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate progress percentage (0.0 to 1.0)
  double get progress {
    if (requiredDays == 0) return 1.0;
    return (currentStreak / requiredDays).clamp(0.0, 1.0);
  }

  // Check if achievement is close to being unlocked (80%+)
  bool get isCloseToUnlock => progress >= 0.8 && !isUnlocked;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'achievementType': achievementType,
      'title': title,
      'description': description,
      'requiredDays': requiredDays,
      'currentStreak': currentStreak,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      taskId: json['taskId'] as String,
      taskTitle: json['taskTitle'] as String,
      achievementType: json['achievementType'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      requiredDays: json['requiredDays'] as int,
      currentStreak: json['currentStreak'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? (json['unlockedAt'] as Timestamp).toDate()
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

// Achievement definitions - predefined achievement types
class AchievementDefinitions {
  // Get achievement title and description based on task title and days
  static Map<String, dynamic> getAchievementForTask(String taskTitle, int days) {
    final titleLower = taskTitle.toLowerCase();
    
    // Early riser achievement
    if (titleLower.contains('wake') || titleLower.contains('6') || titleLower.contains('morning')) {
      if (days == 7) {
        return {
          'title': 'Early Riser',
          'description': 'Woke up early for 7 days straight! 🌅',
          'icon': '🌅',
        };
      } else if (days == 14) {
        return {
          'title': 'Dawn Warrior',
          'description': 'Two weeks of early mornings! ⚡',
          'icon': '⚡',
        };
      } else if (days == 30) {
        return {
          'title': 'Sunrise Master',
          'description': 'A full month of early mornings! 👑',
          'icon': '👑',
        };
      }
    }
    
    // Exercise achievements
    if (titleLower.contains('exercise') || titleLower.contains('workout') || titleLower.contains('gym')) {
      if (days == 7) {
        return {
          'title': 'Week Warrior',
          'description': 'Exercised for 7 days straight! 💪',
          'icon': '💪',
        };
      } else if (days == 14) {
        return {
          'title': 'Fitness Champion',
          'description': 'Two weeks of consistent workouts! 🏆',
          'icon': '🏆',
        };
      } else if (days == 30) {
        return {
          'title': 'Iron Will',
          'description': 'A full month of dedication! 🔥',
          'icon': '🔥',
        };
      }
    }
    
    // Meditation achievements
    if (titleLower.contains('meditate') || titleLower.contains('meditation')) {
      if (days == 7) {
        return {
          'title': 'Zen Beginner',
          'description': 'Meditated for 7 days straight! 🧘',
          'icon': '🧘',
        };
      } else if (days == 14) {
        return {
          'title': 'Mindful Master',
          'description': 'Two weeks of mindfulness! ✨',
          'icon': '✨',
        };
      } else if (days == 30) {
        return {
          'title': 'Enlightened One',
          'description': 'A full month of meditation! 🕉️',
          'icon': '🕉️',
        };
      }
    }
    
    // Reading achievements
    if (titleLower.contains('read') || titleLower.contains('book')) {
      if (days == 7) {
        return {
          'title': 'Bookworm',
          'description': 'Read for 7 days straight! 📚',
          'icon': '📚',
        };
      } else if (days == 14) {
        return {
          'title': 'Knowledge Seeker',
          'description': 'Two weeks of reading! 📖',
          'icon': '📖',
        };
      } else if (days == 30) {
        return {
          'title': 'Scholar',
          'description': 'A full month of reading! 🎓',
          'icon': '🎓',
        };
      }
    }
    
    // Water/drinking achievements
    if (titleLower.contains('water') || titleLower.contains('drink')) {
      if (days == 7) {
        return {
          'title': 'Hydration Hero',
          'description': 'Stayed hydrated for 7 days! 💧',
          'icon': '💧',
        };
      } else if (days == 14) {
        return {
          'title': 'Aqua Master',
          'description': 'Two weeks of proper hydration! 🌊',
          'icon': '🌊',
        };
      } else if (days == 30) {
        return {
          'title': 'Water Warrior',
          'description': 'A full month of hydration! 🏊',
          'icon': '🏊',
        };
      }
    }
    
    // Generic achievements
    if (days == 7) {
      return {
        'title': 'Week Warrior',
        'description': 'Completed this task for 7 days straight! 🎯',
        'icon': '🎯',
      };
    } else if (days == 14) {
      return {
        'title': 'Consistency King',
        'description': 'Two weeks of dedication! 👑',
        'icon': '👑',
      };
    } else if (days == 30) {
      return {
        'title': 'Habit Master',
        'description': 'A full month of consistency! 🌟',
        'icon': '🌟',
      };
    }
    
    // Default
    return {
      'title': 'Achievement Unlocked',
      'description': 'Completed this task for $days days! 🎉',
      'icon': '🎉',
    };
  }
}

