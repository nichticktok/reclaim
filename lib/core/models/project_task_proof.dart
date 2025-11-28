import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/project_proof_types.dart';

/// Model for project task proof submissions
class ProjectTaskProof {
  final String id;
  final String taskId;
  final String userId;
  final String proofType; // timedSession, reflectionNote, smallMediaClip, externalOutput
  final Duration? timeSpent; // For timed sessions
  final List<String>? reflectionAnswers; // For reflection questions
  final String? mediaUrl; // For audio/video clips (Firebase Storage URL)
  final String? externalLink; // For GitHub/screenshots/links
  final String? screenshotUrl; // For external output screenshots
  final Map<String, dynamic>? sessionData; // Additional tracking data
  final DateTime sessionStart;
  final DateTime sessionEnd;
  final String dateKey; // YYYY-MM-DD format
  final List<String>? progressNotes; // For timed sessions
  final bool? needsReview; // Whether answers need review
  final Map<int, String>? reviewData; // Map of question index to correct answer for review

  ProjectTaskProof({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.proofType,
    this.timeSpent,
    this.reflectionAnswers,
    this.mediaUrl,
    this.externalLink,
    this.screenshotUrl,
    this.sessionData,
    required this.sessionStart,
    required this.sessionEnd,
    required this.dateKey,
    this.progressNotes,
    this.needsReview,
    this.reviewData,
  });

  /// Validate that the proof submission has the required fields for its type
  bool isValid() {
    switch (proofType) {
      case ProjectProofTypes.timedSession:
        return timeSpent != null && timeSpent!.inSeconds > 0;
      case ProjectProofTypes.reflectionNote:
        return reflectionAnswers != null &&
            reflectionAnswers!.isNotEmpty &&
            reflectionAnswers!.every((answer) => answer.trim().isNotEmpty);
      case ProjectProofTypes.smallMediaClip:
        return mediaUrl != null && mediaUrl!.isNotEmpty;
      case ProjectProofTypes.externalOutput:
        return (externalLink != null && externalLink!.isNotEmpty) ||
            (screenshotUrl != null && screenshotUrl!.isNotEmpty);
      default:
        return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'proofType': proofType,
      if (timeSpent != null) 'timeSpent': timeSpent!.inSeconds,
      if (reflectionAnswers != null) 'reflectionAnswers': reflectionAnswers,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (externalLink != null) 'externalLink': externalLink,
      if (screenshotUrl != null) 'screenshotUrl': screenshotUrl,
      if (sessionData != null) 'sessionData': sessionData,
      'sessionStart': Timestamp.fromDate(sessionStart),
      'sessionEnd': Timestamp.fromDate(sessionEnd),
      'dateKey': dateKey,
      if (progressNotes != null) 'progressNotes': progressNotes,
      if (needsReview != null) 'needsReview': needsReview,
      if (reviewData != null) 'reviewData': reviewData?.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  factory ProjectTaskProof.fromMap(Map<String, dynamic> map) {
    return ProjectTaskProof(
      id: map['id'] ?? '',
      taskId: map['taskId'] ?? '',
      userId: map['userId'] ?? '',
      proofType: map['proofType'] ?? ProjectProofTypes.timedSession,
      timeSpent: map['timeSpent'] != null
          ? Duration(seconds: map['timeSpent'] as int)
          : null,
      reflectionAnswers: map['reflectionAnswers'] != null
          ? List<String>.from(map['reflectionAnswers'])
          : null,
      mediaUrl: map['mediaUrl'] as String?,
      externalLink: map['externalLink'] as String?,
      screenshotUrl: map['screenshotUrl'] as String?,
      sessionData: map['sessionData'] != null
          ? Map<String, dynamic>.from(map['sessionData'])
          : null,
      sessionStart: map['sessionStart'] != null
          ? (map['sessionStart'] as Timestamp).toDate()
          : DateTime.now(),
      sessionEnd: map['sessionEnd'] != null
          ? (map['sessionEnd'] as Timestamp).toDate()
          : DateTime.now(),
      dateKey: map['dateKey'] ?? '',
      progressNotes: map['progressNotes'] != null
          ? List<String>.from(map['progressNotes'])
          : null,
      needsReview: map['needsReview'] as bool?,
      reviewData: map['reviewData'] != null
          ? (map['reviewData'] as Map).map((k, v) => MapEntry(int.parse(k.toString()), v.toString()))
          : null,
    );
  }

  ProjectTaskProof copyWith({
    String? id,
    String? taskId,
    String? userId,
    String? proofType,
    Duration? timeSpent,
    List<String>? reflectionAnswers,
    String? mediaUrl,
    String? externalLink,
    String? screenshotUrl,
    Map<String, dynamic>? sessionData,
    DateTime? sessionStart,
    DateTime? sessionEnd,
    String? dateKey,
    List<String>? progressNotes,
    bool? needsReview,
    Map<int, String>? reviewData,
  }) {
    return ProjectTaskProof(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      proofType: proofType ?? this.proofType,
      timeSpent: timeSpent ?? this.timeSpent,
      reflectionAnswers: reflectionAnswers ?? this.reflectionAnswers,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      externalLink: externalLink ?? this.externalLink,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      sessionData: sessionData ?? this.sessionData,
      sessionStart: sessionStart ?? this.sessionStart,
      sessionEnd: sessionEnd ?? this.sessionEnd,
      dateKey: dateKey ?? this.dateKey,
      progressNotes: progressNotes ?? this.progressNotes,
      needsReview: needsReview ?? this.needsReview,
      reviewData: reviewData ?? this.reviewData,
    );
  }

  /// Generate a human-readable proof summary
  String generateProofSummary() {
    switch (proofType) {
      case ProjectProofTypes.timedSession:
        final hours = timeSpent!.inHours;
        final minutes = timeSpent!.inMinutes % 60;
        final timeStr = hours > 0
            ? '${hours}h ${minutes}m'
            : '${minutes}m';
        final notesStr = progressNotes != null && progressNotes!.isNotEmpty
            ? '\nProgress: ${progressNotes!.join(", ")}'
            : '';
        return 'Worked for $timeStr.$notesStr';
      case ProjectProofTypes.reflectionNote:
        return 'Reflection: ${reflectionAnswers!.join(" | ")}';
      case ProjectProofTypes.smallMediaClip:
        return 'Media clip recorded (${timeSpent?.inSeconds ?? 0}s)';
      case ProjectProofTypes.externalOutput:
        if (externalLink != null) {
          return 'External output: $externalLink';
        } else if (screenshotUrl != null) {
          return 'Screenshot uploaded';
        }
        return 'External output submitted';
      default:
        return 'Proof submitted';
    }
  }
}

