import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../data/repositories/firestore_subscription_repository.dart';
import '../../data/models/subscription_dto.dart';

class SubscriptionController extends ChangeNotifier {
  final SubscriptionRepository _repository = FirestoreSubscriptionRepository();
  
  bool _loading = false;
  bool _isPremium = false;
  Map<String, dynamic>? _subscription;

  bool get loading => _loading;
  bool get isPremium => _isPremium;
  Map<String, dynamic>? get subscription => _subscription;

  /// Initialize and load subscription status
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _isPremium = await _repository.isPremium(user.uid);
        _subscription = await _repository.getSubscription(user.uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save subscription
  Future<void> saveSubscription(Map<String, dynamic> subscriptionData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    _setLoading(true);
    try {
      // Convert Map to Subscription DTO
      final dto = SubscriptionDto(
        id: subscriptionData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        planId: subscriptionData['planId'] ?? '',
        planName: subscriptionData['planName'] ?? 'Premium',
        isActive: subscriptionData['isActive'] ?? true,
        isPremium: subscriptionData['isPremium'] ?? true,
        startDate: subscriptionData['startDate'] != null
            ? DateTime.parse(subscriptionData['startDate'])
            : DateTime.now(),
        endDate: subscriptionData['endDate'] != null
            ? DateTime.parse(subscriptionData['endDate'])
            : null,
      );

      // Save to repository
      await _repository.saveSubscription(user.uid, subscriptionData);
      
      _isPremium = dto.isPremium;
      _subscription = subscriptionData;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');
    if (_subscription == null) throw Exception('No subscription to cancel');

    _setLoading(true);
    try {
      // Get subscription ID from _subscription
      final subscriptionId = _subscription!['id'] as String?;
      if (subscriptionId != null) {
        await _repository.cancelSubscription(user.uid);
      }
      
      _isPremium = false;
      _subscription = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

