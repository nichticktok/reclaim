import 'package:cloud_firestore/cloud_firestore.dart';

class HabitModel {
  String id;
  final String title;
  final String description;
  final String scheduledTime;
  bool completed;
  bool requiresProof; // Base proof requirement (can be overridden by hard mode)
  final bool isPreset; // Whether this is a preset task (cannot be deleted)
  DateTime createdAt;
  DateTime? lastCompletedAt;
  
  // Proof tracking per day
  Map<String, String> proofs; // Map of date (YYYY-MM-DD) to proof text
  Map<String, bool> dailyCompletion; // Map of date (YYYY-MM-DD) to completion status

  HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    this.completed = false,
    this.requiresProof = false,
    this.isPreset = false, // Default to false (user-added task)
    DateTime? createdAt,
    this.lastCompletedAt,
    Map<String, String>? proofs,
    Map<String, bool>? dailyCompletion,
  }) : createdAt = createdAt ?? DateTime.now(),
       proofs = proofs ?? {},
       dailyCompletion = dailyCompletion ?? {};

  /// Check if proof is required (considers hard mode)
  bool isProofRequired(bool hardModeEnabled) {
    return hardModeEnabled || requiresProof;
  }

  /// Get today's date string (YYYY-MM-DD)
  static String getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check if task is completed today
  bool isCompletedToday() {
    final today = getTodayDateString();
    return dailyCompletion[today] ?? false;
  }

  /// Get proof for today
  String? getTodayProof() {
    final today = getTodayDateString();
    return proofs[today];
  }

  /// Mark as completed for today
  void markCompletedToday({String? proof}) {
    final today = getTodayDateString();
    dailyCompletion[today] = true;
    if (proof != null) {
      proofs[today] = proof;
    }
    lastCompletedAt = DateTime.now();
    completed = true; // For backward compatibility
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime,
      'completed': completed,
      'requiresProof': requiresProof,
      'isPreset': isPreset,
      'createdAt': Timestamp.fromDate(createdAt), // Use Firestore Timestamp
      if (lastCompletedAt != null) 'lastCompletedAt': Timestamp.fromDate(lastCompletedAt!),
      'proofs': proofs,
      'dailyCompletion': dailyCompletion,
    };
  }

  /// Helper method to convert Firestore Timestamp or String to DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    // If it's a Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }
    
    // If it's already a DateTime
    if (value is DateTime) {
      return value;
    }
    
    // If it's a String, try to parse it
    if (value is String) {
      return DateTime.tryParse(value);
    }
    
    return null;
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledTime: map['scheduledTime'] ?? '',
      completed: map['completed'] ?? false,
      requiresProof: map['requiresProof'] ?? false,
      isPreset: map['isPreset'] ?? false,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastCompletedAt: _parseDateTime(map['lastCompletedAt']),
      proofs: map['proofs'] != null 
          ? Map<String, String>.from(map['proofs'])
          : {},
      dailyCompletion: map['dailyCompletion'] != null
          ? Map<String, bool>.from(map['dailyCompletion'].map((k, v) => MapEntry(k.toString(), v as bool)))
          : {},
    );
  }
}
