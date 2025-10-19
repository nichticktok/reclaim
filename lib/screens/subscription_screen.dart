import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
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
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Unlock Your Full Potential 🌟",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Access deeper analytics, AI insights, and advanced habit systems.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Feature List
            const Text(
              "Premium Features",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.auto_graph, "AI habit verification"),
            _buildFeatureItem(Icons.bar_chart_rounded, "Deep progress analytics"),
            _buildFeatureItem(Icons.insights_rounded, "Personalized insights & tips"),
            _buildFeatureItem(Icons.cloud_done_rounded, "Sync across devices"),
            _buildFeatureItem(Icons.people_alt_rounded, "Exclusive community access"),
            _buildFeatureItem(Icons.emoji_events_rounded, "Premium challenges & badges"),

            const SizedBox(height: 30),

            // Subscription Options
            _buildPlanCard(
              title: "Monthly Plan",
              price: "\$4.99",
              description: "Billed every month. Cancel anytime.",
              highlight: false,
              context: context,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              title: "Yearly Plan",
              price: "\$39.99",
              description: "Save 30% with the yearly plan!",
              highlight: true,
              context: context,
            ),

            const SizedBox(height: 30),

            // Restore / Terms
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String description,
    required bool highlight,
    required BuildContext context,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: highlight ? Colors.white70 : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    highlight ? Colors.white : Colors.blueAccent,
                foregroundColor:
                    highlight ? Colors.blueAccent : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text("Subscribed to $title! (Mock action for now)"),
                  ),
                );
              },
              child: Text("Subscribe"),
            ),
          ),
        ],
      ),
    );
  }
}
