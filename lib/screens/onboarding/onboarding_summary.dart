import 'package:flutter/material.dart';

class OnboardingSummary extends StatelessWidget {
  final String name;
  final List<String> focusAreas;
  final bool proofMode;
  final VoidCallback onFinish;

  const OnboardingSummary({
    super.key,
    required this.name,
    required this.focusAreas,
    required this.proofMode,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                "Welcome, $name 👋",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Here’s your Reclaim setup summary:",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),

              // 🧩 Focus Areas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Your Focus Areas:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: focusAreas
                          .map((area) => Chip(
                                label: Text(area),
                                backgroundColor:
                                    Colors.blueAccent.withValues(alpha: 0.15),
                                labelStyle:
                                    const TextStyle(color: Colors.blueAccent),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🔒 Proof Mode Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: proofMode
                      ? Colors.greenAccent.withValues(alpha: 0.1)
                      : Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      proofMode ? Icons.verified_rounded : Icons.check_circle,
                      color:
                          proofMode ? Colors.greenAccent.shade700 : Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        proofMode
                            ? "Proof Mode enabled — you’ll verify each habit!"
                            : "Proof Mode disabled — you’ll track freely.",
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  ],
                ),
              ),

              const Spacer(),

              // 🎉 Finish Button
              ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Start My Journey →",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
