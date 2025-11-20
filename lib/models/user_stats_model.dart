import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatsModel {
  final String userId;
  int currentStreak;
  int longestStreak;
  int totalTasksCompleted;
  double overallProgress; // 0.0 to 1.0
  DateTime lastUpdated;

  UserStatsModel({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalTasksCompleted = 0,
    this.overallProgress = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Helper method to convert Firestore Timestamp or String to DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is DateTime) {
      return value;
    }
    
    if (value is String) {
      return DateTime.tryParse(value);
    }
    
    return null;
  }

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      userId: json['userId'] ?? '',
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalTasksCompleted: json['totalTasksCompleted'] ?? 0,
      overallProgress: (json['overallProgress'] ?? 0.0).toDouble(),
      lastUpdated: _parseDateTime(json['lastUpdated']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalTasksCompleted': totalTasksCompleted,
      'overallProgress': overallProgress,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

