import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool loading = false;
  final _iap = InAppPurchase.instance;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _iap.purchaseStream.listen((purchases) {
      for (var p in purchases) {
        if (p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored) {
          _markSubscribed(plan: "Store Subscription");
          _iap.completePurchase(p);
        }
      }
    });
  }

  /// 🔹 MARK SUBSCRIPTION IN FIRESTORE
  Future<void> _markSubscribed({required String plan}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'hasActiveSubscription': true,
      'subscriptionPlan': plan,
      'subscriptionExpiresAt':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Subscription successful ($plan)!")),
      );
      Navigator.pushReplacementNamed(context, '/home_screen');
    }
  }

  /// 🔹 IN-APP PURCHASE (Play Store / App Store)
  Future<void> _subscribeViaStore(String productId) async {
    setState(() => loading = true);
    try {
      final available = await _iap.isAvailable();
      if (!available) throw "Store not available.";
      final response = await _iap.queryProductDetails({productId});
      if (response.notFoundIDs.isNotEmpty) throw "Product not found.";
      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Store subscription failed: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// 🔹 STRIPE PAYMENT (Card, Apple Pay, Google Pay)
  Future<void> _subscribeViaStripe(String plan) async {
    setState(() => loading = true);
    try {
      // ⚠️ Normally you'd create a PaymentIntent on your backend here.
      // For now, this is a mock success flow.
      await Future.delayed(const Duration(seconds: 2));
      await _markSubscribed(plan: plan);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stripe payment failed: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Reclaim Premium"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  const Text("Premium Features",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _buildFeatureItem(Icons.auto_graph, "AI habit verification"),
                  _buildFeatureItem(
                      Icons.bar_chart_rounded, "Deep progress analytics"),
                  _buildFeatureItem(Icons.insights_rounded,
                      "Personalized insights & tips"),
                  _buildFeatureItem(
                      Icons.cloud_done_rounded, "Sync across devices"),
                  _buildFeatureItem(Icons.people_alt_rounded,
                      "Exclusive community access"),
                  _buildFeatureItem(Icons.emoji_events_rounded,
                      "Premium challenges & badges"),
                  const SizedBox(height: 30),
                  _buildPlanCard(
                    title: "Monthly Plan",
                    price: "\$4.99",
                    description: "Billed every month. Cancel anytime.",
                    highlight: false,
                    onPressed: () => _subscribeViaStripe("Monthly Plan"),
                  ),
                  const SizedBox(height: 16),
                  _buildPlanCard(
                    title: "Yearly Plan",
                    price: "\$39.99",
                    description: "Save 30% with the yearly plan!",
                    highlight: true,
                    onPressed: () => _subscribeViaStore("reclaim_yearly"),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Restore Purchase • Terms & Privacy",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Unlock Your Full Potential 🌟",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(
              "Access deeper analytics, AI insights, and advanced habit systems.",
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      );

  Widget _buildFeatureItem(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 15)),
          ],
        ),
      );

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String description,
    required bool highlight,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: highlight
            ? const LinearGradient(
                colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: highlight ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: highlight ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 17)),
          const SizedBox(height: 6),
          Text(price,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: highlight ? Colors.white : Colors.black87)),
          const SizedBox(height: 6),
          Text(description,
              style: TextStyle(
                  color: highlight ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 14)),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    highlight ? Colors.white : Colors.blueAccent,
                foregroundColor:
                    highlight ? Colors.blueAccent : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              onPressed: onPressed,
              child: const Text("Subscribe"),
            ),
          ),
        ],
      ),
    );
  }
}
