/// Abstract repository for subscription data operations
abstract class SubscriptionRepository {
  Future<void> saveSubscription(String userId, Map<String, dynamic> subscriptionData);
  Future<Map<String, dynamic>?> getSubscription(String userId);
  Future<void> cancelSubscription(String userId);
  Future<bool> isPremium(String userId);
}

