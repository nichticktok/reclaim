import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/proof_types.dart';

class HabitModel {
  String id;
  final String title;
  final String description;
  final String scheduledTime;
  bool completed;
  bool requiresProof; // Base proof requirement (can be overridden by hard mode)
  final String? proofType; // Type of proof required: text, photo, video, location, file, any
  final bool isPreset; // Whether this is a preset task (cannot be deleted)
  final String difficulty; // 'easy', 'medium', 'hard' - only for system-assigned tasks
  final bool isSystemAssigned; // Whether this task was assigned by the system (from onboarding)
  final String? attribute; // "Wisdom", "Confidence", "Strength", "Discipline", "Focus" - for color coding
  final Map<String, dynamic> metadata; // Additional contextual data (e.g., workout details)
  final List<int> daysOfWeek; // Recurring schedule (1 = Monday ... 7 = Sunday)
  final DateTime? specificDate; // Specific date when this task should appear (overrides daysOfWeek)
  bool isActive; // Allows pausing a scheduled habit without deleting it
  final String? presetTaskId; // Link back to preset library document
  DateTime createdAt;
  DateTime? lastCompletedAt;
  String? deletionStatus; // Deletion status: null/false = no deletion, "pending" = deletion requested, "deleted" = deleted
  
  // Proof tracking per day
  Map<String, String> proofs; // Map of date (YYYY-MM-DD) to proof text
  Map<String, bool> dailyCompletion; // Map of date (YYYY-MM-DD) to completion status
  Map<String, bool> dailySkipped; // Map of date (YYYY-MM-DD) to skip status

  HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    this.completed = false,
    this.requiresProof = false,
    String? proofType,
    this.isPreset = false, // Default to false (user-added task)
    this.difficulty = 'medium', // Default difficulty
    this.isSystemAssigned = false, // Default to false (user-added task)
    this.attribute, // Attribute for color coding
    Map<String, dynamic>? metadata,
    List<int>? daysOfWeek,
    this.specificDate,
    this.isActive = true,
    this.presetTaskId,
    DateTime? createdAt,
    this.lastCompletedAt,
    this.deletionStatus, // null = false (no deletion), "pending" = pending, "deleted" = deleted
    Map<String, String>? proofs,
    Map<String, bool>? dailyCompletion,
    Map<String, bool>? dailySkipped,
  }) : createdAt = createdAt ?? DateTime.now(),
       proofs = proofs ?? {},
       dailyCompletion = dailyCompletion ?? {},
       dailySkipped = dailySkipped ?? {},
       metadata = metadata ?? {},
       daysOfWeek = daysOfWeek ?? _allDaysOfWeek,
       proofType = ProofTypes.isValid(proofType) ? proofType : (requiresProof ? ProofTypes.text : null) {
    // Only set isActive to false when deletionStatus is "deleted", not "pending"
    if (deletionStatus == "deleted") {
      isActive = false;
    }
  }

  static const List<int> _allDaysOfWeek = [1, 2, 3, 4, 5, 6, 7];

  /// Check if proof is required (considers hard mode)
  bool isProofRequired(bool hardModeEnabled) {
    return hardModeEnabled || requiresProof;
  }

  /// Determine if the habit should appear on a given date.
  bool isScheduledForDate(DateTime date) {
    // Don't show deleted habits, but show pending deletion habits (they just don't count)
    if (deletionStatus == "deleted") return false;
    if (!isActive) return false;

    // Normalize the check date to just year/month/day (remove time component)
    final checkDateNormalized = DateTime(date.year, date.month, date.day);
    
    // Check if the date is before the task creation date
    // Compare only dates (ignore time) to allow tasks created on the same day to appear
    final taskCreatedDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    if (checkDateNormalized.isBefore(taskCreatedDate)) {
      // Task hasn't been created yet on this date
      return false;
    }

    // Check specificDate first (highest priority)
    if (specificDate != null) {
      // Normalize specificDate to just year/month/day (remove time component)
      final specificDateNormalized = DateTime(specificDate!.year, specificDate!.month, specificDate!.day);
      
      // Debug logging (can be removed later)
      // debugPrint('🔍 Checking habit "$title": specificDate=$specificDateNormalized, checkDate=$checkDateNormalized, match=${specificDateNormalized.year == checkDateNormalized.year && specificDateNormalized.month == checkDateNormalized.month && specificDateNormalized.day == checkDateNormalized.day}');
      
      // Compare dates directly (both normalized to midnight)
      return specificDateNormalized.year == checkDateNormalized.year &&
             specificDateNormalized.month == checkDateNormalized.month &&
             specificDateNormalized.day == checkDateNormalized.day;
    }

    final dateKey = getDateString(date);

    // Fallback to metadata-based date checking (for backward compatibility)
    final metadataDateKey = metadata['dateKey'] as String?;
    if (metadataDateKey != null) {
      return metadataDateKey == dateKey;
    }

    final metadataScheduledDate = metadata['scheduledDate'] as String?;
    if (metadataScheduledDate != null) {
      final parsed = DateTime.tryParse(metadataScheduledDate);
      if (parsed != null) {
        return getDateString(parsed) == dateKey;
      }
    }

    // If no specific date, use daysOfWeek
    if (daysOfWeek.isEmpty) return true;
    return daysOfWeek.contains(date.weekday);
  }

  /// Get today's date string (YYYY-MM-DD)
  static String getTodayDateString() {
    final now = DateTime.now();
    return getDateString(now);
  }

  /// Get date string for a specific date (YYYY-MM-DD)
  static String getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if task is completed today
  bool isCompletedToday() {
    final today = getTodayDateString();
    return dailyCompletion[today] ?? false;
  }

  /// Check if task is completed for a specific date
  bool isCompletedForDate(DateTime date) {
    final dateString = getDateString(date);
    return dailyCompletion[dateString] ?? false;
  }

  /// Get proof for today
  String? getTodayProof() {
    final today = getTodayDateString();
    return proofs[today];
  }

  /// Get proof for a specific date
  String? getProofForDate(DateTime date) {
    final dateString = getDateString(date);
    return proofs[dateString];
  }

  /// Mark as completed for today
  void markCompletedToday({String? proof}) {
    final today = getTodayDateString();
    dailyCompletion[today] = true;
    dailySkipped[today] = false; // Clear skip if completing
    if (proof != null) {
      proofs[today] = proof;
    }
    lastCompletedAt = DateTime.now();
    completed = true; // For backward compatibility
  }

  /// Mark as completed for a specific date
  void markCompletedForDate(DateTime date, {String? proof}) {
    final dateString = getDateString(date);
    dailyCompletion[dateString] = true;
    dailySkipped[dateString] = false; // Clear skip if completing
    if (proof != null) {
      proofs[dateString] = proof;
    }
    lastCompletedAt = date;
    completed = true; // For backward compatibility
  }

  /// Check if task is skipped today
  bool isSkippedToday() {
    final today = getTodayDateString();
    return dailySkipped[today] ?? false;
  }

  /// Check if task is skipped for a specific date
  bool isSkippedForDate(DateTime date) {
    final dateString = getDateString(date);
    return dailySkipped[dateString] ?? false;
  }

  /// Mark as skipped for today
  void markSkippedToday() {
    final today = getTodayDateString();
    dailySkipped[today] = true;
    dailyCompletion[today] = false; // Clear completion if skipping
  }

  /// Mark as skipped for a specific date
  void markSkippedForDate(DateTime date) {
    final dateString = getDateString(date);
    dailySkipped[dateString] = true;
    dailyCompletion[dateString] = false; // Clear completion if skipping
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime,
      'completed': completed,
      'requiresProof': requiresProof,
      if (proofType != null) 'proofType': proofType,
      'isPreset': isPreset,
      'difficulty': difficulty,
      'isSystemAssigned': isSystemAssigned,
      'daysOfWeek': daysOfWeek,
      if (specificDate != null) 'specificDate': Timestamp.fromDate(specificDate!),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt), // Use Firestore Timestamp
      if (lastCompletedAt != null) 'lastCompletedAt': Timestamp.fromDate(lastCompletedAt!),
      'proofs': proofs,
      'dailyCompletion': dailyCompletion,
      'dailySkipped': dailySkipped,
      if (metadata.isNotEmpty) 'metadata': metadata,
      if (presetTaskId != null) 'presetTaskId': presetTaskId,
      'deletionStatus': deletionStatus, // Always include deletionStatus (can be null)
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
      proofType: map['proofType'] as String?,
      isPreset: map['isPreset'] ?? false,
      difficulty: map['difficulty'] ?? 'medium',
      isSystemAssigned: map['isSystemAssigned'] ?? false,
      attribute: map['attribute'] as String?,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastCompletedAt: _parseDateTime(map['lastCompletedAt']),
      daysOfWeek: map['daysOfWeek'] != null
          ? List<int>.from(map['daysOfWeek'])
          : _allDaysOfWeek,
      specificDate: _parseDateTime(map['specificDate']),
      presetTaskId: map['presetTaskId'] as String?,
      deletionStatus: map['deletionStatus'] as String?, // null, "pending", or "deleted"
      isActive: _determineIsActive(map, map['deletionStatus'] as String?),
      proofs: map['proofs'] != null 
          ? Map<String, String>.from(map['proofs'])
          : {},
      dailyCompletion: map['dailyCompletion'] != null
          ? Map<String, bool>.from(map['dailyCompletion'].map((k, v) => MapEntry(k.toString(), v as bool)))
          : {},
      dailySkipped: map['dailySkipped'] != null
          ? Map<String, bool>.from(map['dailySkipped'].map((k, v) => MapEntry(k.toString(), v as bool)))
          : {},
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : {},
    );
  }
  
  /// Determine isActive based on deletionStatus
  /// Only set isActive to false when deletionStatus is "deleted", not "pending"
  static bool _determineIsActive(Map<String, dynamic> map, String? deletionStatus) {
    if (deletionStatus == "deleted") {
      return false;
    }
    return map['isActive'] ?? true;
  }

  HabitModel copyWith({
    String? id,
    String? title,
    String? description,
    String? scheduledTime,
    bool? completed,
    bool? requiresProof,
    String? proofType,
    bool? isPreset,
    String? difficulty,
    bool? isSystemAssigned,
    String? attribute,
    Map<String, dynamic>? metadata,
    List<int>? daysOfWeek,
    DateTime? specificDate,
    bool? isActive,
    String? presetTaskId,
    DateTime? createdAt,
    DateTime? lastCompletedAt,
    Map<String, String>? proofs,
    Map<String, bool>? dailyCompletion,
    Map<String, bool>? dailySkipped,
    String? deletionStatus,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      completed: completed ?? this.completed,
      requiresProof: requiresProof ?? this.requiresProof,
      proofType: proofType ?? this.proofType,
      isPreset: isPreset ?? this.isPreset,
      difficulty: difficulty ?? this.difficulty,
      isSystemAssigned: isSystemAssigned ?? this.isSystemAssigned,
      attribute: attribute ?? this.attribute,
      metadata: metadata ?? this.metadata,
      daysOfWeek: daysOfWeek ?? List<int>.from(this.daysOfWeek),
      specificDate: specificDate ?? this.specificDate,
      isActive: isActive ?? this.isActive,
      presetTaskId: presetTaskId ?? this.presetTaskId,
      createdAt: createdAt ?? this.createdAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      proofs: proofs ?? Map<String, String>.from(this.proofs),
      dailyCompletion: dailyCompletion ?? Map<String, bool>.from(this.dailyCompletion),
      dailySkipped: dailySkipped ?? Map<String, bool>.from(this.dailySkipped),
      deletionStatus: deletionStatus ?? this.deletionStatus,
    );
  }
}
