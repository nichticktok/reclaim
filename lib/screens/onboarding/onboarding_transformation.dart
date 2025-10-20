import 'package:flutter/material.dart';

/// Reclaim — Onboarding Transformation
/// Step 13: Final cinematic screen
class OnboardingTransformation extends StatelessWidget {
  final VoidCallback onFinish;

  const OnboardingTransformation({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 42, color: Colors.orange.withOpacity(0.9)),
              const SizedBox(height: 60),

              Text(
                "After 66 days,",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "you’ll conquer the storm.",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.orange.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),
              Text(
                "A new chapter begins today.",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 10,
                    shadowColor:
                        const Color(0xFFFF7A00).withOpacity(0.5),
                  ),
                  child: const Text(
                    "Begin My Journey",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
