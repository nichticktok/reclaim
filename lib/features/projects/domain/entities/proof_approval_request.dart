import 'package:cloud_firestore/cloud_firestore.dart';

/// Entity for peer approval requests for project task proofs
class ProofApprovalRequest {
  final String id;
  final String proofId;
  final String taskId;
  final String requesterId;
  final String approverContact; // email or phone
  final String contactType; // 'email' or 'phone'
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final String? response;

  ProofApprovalRequest({
    required this.id,
    required this.proofId,
    required this.taskId,
    required this.requesterId,
    required this.approverContact,
    required this.contactType,
    this.status = 'pending',
    DateTime? requestedAt,
    this.respondedAt,
    this.response,
  }) : requestedAt = requestedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'proofId': proofId,
      'taskId': taskId,
      'requesterId': requesterId,
      'approverContact': approverContact,
      'contactType': contactType,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (respondedAt != null) 'respondedAt': Timestamp.fromDate(respondedAt!),
      if (response != null) 'response': response,
    };
  }

  factory ProofApprovalRequest.fromMap(Map<String, dynamic> map, String id) {
    return ProofApprovalRequest(
      id: id,
      proofId: map['proofId'] ?? '',
      taskId: map['taskId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      approverContact: map['approverContact'] ?? '',
      contactType: map['contactType'] ?? 'email',
      status: map['status'] ?? 'pending',
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
      response: map['response'] as String?,
    );
  }

  ProofApprovalRequest copyWith({
    String? id,
    String? proofId,
    String? taskId,
    String? requesterId,
    String? approverContact,
    String? contactType,
    String? status,
    DateTime? requestedAt,
    DateTime? respondedAt,
    String? response,
  }) {
    return ProofApprovalRequest(
      id: id ?? this.id,
      proofId: proofId ?? this.proofId,
      taskId: taskId ?? this.taskId,
      requesterId: requesterId ?? this.requesterId,
      approverContact: approverContact ?? this.approverContact,
      contactType: contactType ?? this.contactType,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      response: response ?? this.response,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

