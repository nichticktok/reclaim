import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subscription.dart';

/// Subscription DTO - Data Transfer Object for Firestore
class SubscriptionDto {
  final String id;
  final String userId;
  final String planId;
  final String planName;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? cancelledAt;
  final bool isPremium;

  SubscriptionDto({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    this.isActive = false,
    this.startDate,
    this.endDate,
    this.cancelledAt,
    this.isPremium = false,
  });

  /// Convert from Firestore document
  factory SubscriptionDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionDto(
      id: doc.id,
      userId: data['userId'] ?? '',
      planId: data['planId'] ?? '',
      planName: data['planName'] ?? '',
      isActive: data['isActive'] ?? false,
      startDate: data['startDate'] != null 
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      isPremium: data['isPremium'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'planId': planId,
      'planName': planName,
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'isPremium': isPremium,
    };
  }

  /// Convert to domain entity
  Subscription toEntity() {
    return Subscription(
      id: id,
      userId: userId,
      planId: planId,
      planName: planName,
      isActive: isActive,
      startDate: startDate,
      endDate: endDate,
      cancelledAt: cancelledAt,
      isPremium: isPremium,
    );
  }

  /// Convert from domain entity
  factory SubscriptionDto.fromEntity(Subscription entity) {
    return SubscriptionDto(
      id: entity.id,
      userId: entity.userId,
      planId: entity.planId,
      planName: entity.planName,
      isActive: entity.isActive,
      startDate: entity.startDate,
      endDate: entity.endDate,
      cancelledAt: entity.cancelledAt,
      isPremium: entity.isPremium,
    );
  }
}

