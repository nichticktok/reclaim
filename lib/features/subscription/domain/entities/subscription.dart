/// Subscription entity - Business model
/// This represents the domain concept of a subscription
class Subscription {
  final String id;
  final String userId;
  final String planId;
  final String planName;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? cancelledAt;
  final bool isPremium;

  Subscription({
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

  bool get isValid => isActive && endDate != null && endDate!.isAfter(DateTime.now());
  bool get isCancelled => cancelledAt != null;
}

