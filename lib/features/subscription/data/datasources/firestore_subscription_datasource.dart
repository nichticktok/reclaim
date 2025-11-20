import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_dto.dart';

/// Data source for subscription data operations
/// Handles direct Firestore interactions
class FirestoreSubscriptionDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get subscription document
  Future<SubscriptionDto?> getSubscription(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('subscriptions')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (doc.docs.isEmpty) return null;
    return SubscriptionDto.fromFirestore(doc.docs.first);
  }

  /// Save subscription
  Future<void> saveSubscription(SubscriptionDto dto) async {
    await _firestore
        .collection('users')
        .doc(dto.userId)
        .collection('subscriptions')
        .doc(dto.id)
        .set(dto.toFirestore(), SetOptions(merge: true));

    // Update user's premium status
    await _firestore.collection('users').doc(dto.userId).update({
      'isPremium': dto.isPremium,
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String userId, String subscriptionId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subscriptions')
        .doc(subscriptionId)
        .update({
      'isActive': false,
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    // Update user's premium status
    await _firestore.collection('users').doc(userId).update({
      'isPremium': false,
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if user is premium
  Future<bool> isPremium(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;
    return doc.data()?['isPremium'] ?? false;
  }
}

