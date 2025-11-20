import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/subscription_repository.dart';

/// Firestore implementation of SubscriptionRepository
class FirestoreSubscriptionRepository implements SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> saveSubscription(String userId, Map<String, dynamic> subscriptionData) async {
    await _firestore.collection('users').doc(userId).update({
      'isPremium': true,
      'subscription': subscriptionData,
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, dynamic>?> getSubscription(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    
    final data = doc.data() ?? {};
    return data['subscription'] as Map<String, dynamic>?;
  }

  @override
  Future<void> cancelSubscription(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isPremium': false,
      'subscription.cancelled': true,
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<bool> isPremium(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;
    
    final data = doc.data() ?? {};
    return data['isPremium'] ?? false;
  }
}

