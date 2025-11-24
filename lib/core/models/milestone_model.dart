import 'package:cloud_firestore/cloud_firestore.dart';

class MilestoneModel {
  final String id;
  final String userId;
  final int totalDays; // Total days in the milestone (e.g., 30, 60, 90)
  final String name; // e.g., "1 Month", "2 Months", "3 Months"
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  MilestoneModel({
    required this.id,
    required this.userId,
    required this.totalDays,
    required this.name,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate current day in milestone (1-based)
  int getCurrentDay() {
    if (!isActive) return 0;
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;
    return (difference + 1).clamp(1, totalDays);
  }

  /// Calculate progress percentage (0.0 to 1.0)
  double getProgressPercentage() {
    if (!isActive) return 0.0;
    final currentDay = getCurrentDay();
    return (currentDay / totalDays).clamp(0.0, 1.0);
  }

  /// Check if milestone is completed
  bool isCompleted() {
    if (!isActive) return false;
    return getCurrentDay() >= totalDays;
  }

  /// Get remaining days
  int getRemainingDays() {
    if (!isActive) return 0;
    final currentDay = getCurrentDay();
    return (totalDays - currentDay).clamp(0, totalDays);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'totalDays': totalDays,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MilestoneModel.fromMap(Map<String, dynamic> map) {
    return MilestoneModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      totalDays: map['totalDays'] ?? 30,
      name: map['name'] ?? '1 Month',
      startDate: _parseDateTime(map['startDate']) ?? DateTime.now(),
      endDate: _parseDateTime(map['endDate']),
      isActive: map['isActive'] ?? true,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

