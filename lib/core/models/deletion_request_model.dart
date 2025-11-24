import 'package:cloud_firestore/cloud_firestore.dart';

enum DeletionRequestStatus {
  pending,
  approved,
  rejected,
  expired,
}

extension DeletionRequestStatusExtension on DeletionRequestStatus {
  String get value {
    switch (this) {
      case DeletionRequestStatus.pending:
        return 'pending';
      case DeletionRequestStatus.approved:
        return 'approved';
      case DeletionRequestStatus.rejected:
        return 'rejected';
      case DeletionRequestStatus.expired:
        return 'expired';
    }
  }

  static DeletionRequestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return DeletionRequestStatus.approved;
      case 'rejected':
        return DeletionRequestStatus.rejected;
      case 'expired':
        return DeletionRequestStatus.expired;
      default:
        return DeletionRequestStatus.pending;
    }
  }
}

class DeletionRequestModel {
  final String id;
  final String userId;
  final String? habitId; // For habit deletion requests
  final String? habitTitle; // For habit deletion requests
  final String? planId; // For plan deletion requests
  final String? planTitle; // For plan deletion requests
  final String requestType; // 'habit' or 'plan'
  final String reason;
  final String accountabilityPartnerContact; // Phone number or email
  final String contactType; // 'phone' or 'email'
  final DeletionRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? response; // The actual response text (Y, YES, N, NO)
  final DateTime? expiresAt; // Optional expiration date

  DeletionRequestModel({
    required this.id,
    required this.userId,
    this.habitId,
    this.habitTitle,
    this.planId,
    this.planTitle,
    required this.requestType, // 'habit' or 'plan'
    required this.reason,
    required this.accountabilityPartnerContact,
    required this.contactType,
    this.status = DeletionRequestStatus.pending,
    DateTime? createdAt,
    this.respondedAt,
    this.response,
    this.expiresAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      if (habitId != null) 'habitId': habitId,
      if (habitTitle != null) 'habitTitle': habitTitle,
      if (planId != null) 'planId': planId,
      if (planTitle != null) 'planTitle': planTitle,
      'requestType': requestType,
      'reason': reason,
      'accountabilityPartnerContact': accountabilityPartnerContact,
      'contactType': contactType,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'response': response,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  factory DeletionRequestModel.fromMap(Map<String, dynamic> map) {
    return DeletionRequestModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      habitId: map['habitId'] as String?,
      habitTitle: map['habitTitle'] as String?,
      planId: map['planId'] as String?,
      planTitle: map['planTitle'] as String?,
      requestType: map['requestType'] ?? (map['habitId'] != null ? 'habit' : 'plan'), // Backward compatibility
      reason: map['reason'] ?? '',
      accountabilityPartnerContact: map['accountabilityPartnerContact'] ?? '',
      contactType: map['contactType'] ?? 'email',
      status: DeletionRequestStatusExtension.fromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
      response: map['response'] as String?,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  DeletionRequestModel copyWith({
    String? id,
    String? userId,
    String? habitId,
    String? habitTitle,
    String? planId,
    String? planTitle,
    String? requestType,
    String? reason,
    String? accountabilityPartnerContact,
    String? contactType,
    DeletionRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? response,
    DateTime? expiresAt,
  }) {
    return DeletionRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      habitTitle: habitTitle ?? this.habitTitle,
      planId: planId ?? this.planId,
      planTitle: planTitle ?? this.planTitle,
      requestType: requestType ?? this.requestType,
      reason: reason ?? this.reason,
      accountabilityPartnerContact: accountabilityPartnerContact ?? this.accountabilityPartnerContact,
      contactType: contactType ?? this.contactType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      response: response ?? this.response,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
  
  // Convenience getters for backward compatibility
  String get targetId => requestType == 'plan' ? (planId ?? '') : (habitId ?? '');
  String get targetTitle => requestType == 'plan' ? (planTitle ?? '') : (habitTitle ?? '');
}

