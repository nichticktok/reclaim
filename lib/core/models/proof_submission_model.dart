import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/proof_types.dart';

/// Model for proof submissions stored in the proofs collection
class ProofSubmission {
  final String id;
  final String habitId;
  final String userId;
  final String proofType; // text, photo, video, location, file
  final String? textContent; // For text proofs
  final String? mediaUrl; // Firebase Storage URL for photos/videos/files
  final String? locationLat; // For location proofs
  final String? locationLng; // For location proofs
  final String? fileName; // Original filename for file uploads
  final DateTime submittedAt;
  final String dateKey; // YYYY-MM-DD format

  ProofSubmission({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.proofType,
    this.textContent,
    this.mediaUrl,
    this.locationLat,
    this.locationLng,
    this.fileName,
    DateTime? submittedAt,
    required this.dateKey,
  }) : submittedAt = submittedAt ?? DateTime.now();

  /// Validate that the proof submission has the required fields for its type
  bool isValid() {
    switch (proofType) {
      case ProofTypes.text:
        return textContent != null && textContent!.trim().isNotEmpty;
      case ProofTypes.photo:
      case ProofTypes.video:
      case ProofTypes.file:
        return mediaUrl != null && mediaUrl!.isNotEmpty;
      case ProofTypes.location:
        return locationLat != null &&
            locationLng != null &&
            locationLat!.isNotEmpty &&
            locationLng!.isNotEmpty;
      case ProofTypes.any:
        // For 'any' type, at least one field must be populated
        return (textContent != null && textContent!.trim().isNotEmpty) ||
            (mediaUrl != null && mediaUrl!.isNotEmpty) ||
            (locationLat != null && locationLng != null);
      default:
        return false;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'userId': userId,
      'proofType': proofType,
      if (textContent != null) 'textContent': textContent,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (locationLat != null) 'locationLat': locationLat,
      if (locationLng != null) 'locationLng': locationLng,
      if (fileName != null) 'fileName': fileName,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'dateKey': dateKey,
    };
  }

  factory ProofSubmission.fromMap(Map<String, dynamic> map) {
    return ProofSubmission(
      id: map['id'] ?? '',
      habitId: map['habitId'] ?? '',
      userId: map['userId'] ?? '',
      proofType: map['proofType'] ?? ProofTypes.text,
      textContent: map['textContent'] as String?,
      mediaUrl: map['mediaUrl'] as String?,
      locationLat: map['locationLat'] as String?,
      locationLng: map['locationLng'] as String?,
      fileName: map['fileName'] as String?,
      submittedAt: map['submittedAt'] != null
          ? (map['submittedAt'] as Timestamp).toDate()
          : DateTime.now(),
      dateKey: map['dateKey'] ?? '',
    );
  }

  ProofSubmission copyWith({
    String? id,
    String? habitId,
    String? userId,
    String? proofType,
    String? textContent,
    String? mediaUrl,
    String? locationLat,
    String? locationLng,
    String? fileName,
    DateTime? submittedAt,
    String? dateKey,
  }) {
    return ProofSubmission(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      proofType: proofType ?? this.proofType,
      textContent: textContent ?? this.textContent,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      fileName: fileName ?? this.fileName,
      submittedAt: submittedAt ?? this.submittedAt,
      dateKey: dateKey ?? this.dateKey,
    );
  }
}

