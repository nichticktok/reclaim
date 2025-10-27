import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class SubscriptionService {
  final _iap = InAppPurchase.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> init() async {
    // initialize IAP connection
    await _iap.isAvailable();
    // maybe listen to purchase updates etc.
    _iap.purchaseStream.listen((purchaseDetailsList) {
      _handlePurchases(purchaseDetailsList);
    }, onError: (error) {
      // handle error
    });
  }

  Future<void> buySubscription(String productId) async {
    final productDetails = await _fetchProduct(productId);
    if (productDetails != null) {
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      _iap.buyNonConsumable(purchaseParam: purchaseParam); // or buySubscription
    }
  }

  Future<ProductDetails?> _fetchProduct(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isNotEmpty) {
      return response.productDetails.first;
    }
    return null;
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _verifyAndSave(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        // handle error
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndSave(PurchaseDetails purchase) async {
    // verify receipt / purchase on backend
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'hasActiveSubscription': true,
      'subscriptionExpiresAt': FieldValue.serverTimestamp().add(Duration(days: 30)), // or actual expiry
    }, SetOptions(merge: true));
  }

  // fallback via Stripe (card payments)
  Future<void> purchaseWithStripe({required String priceId}) async {
    // Use Stripe PaymentSheet or payment intent + ApplePay/GooglePay
    final user = _auth.currentUser;
    if (user == null) return;
    // create PaymentIntent on backend, then present PaymentSheet
    // after success, update Firestore same as above
  }

  Future<bool> checkSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    final bool subscribed = data['hasActiveSubscription'] ?? false;
    final Timestamp? expiry = data['subscriptionExpiresAt'];
    if (!subscribed) return false;
    if (expiry != null && expiry.toDate().isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }
}
