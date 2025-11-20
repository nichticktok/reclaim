import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Proud Message Screen (Onboarding)
/// Shows: "I'm proud of you for wanting to make changes"
/// This screen is shown during onboarding for motivation
class OnboardingProudMessage extends StatelessWidget {
  final Function()? onNext;
  final VoidCallback? onBack;

  const OnboardingProudMessage({
    super.key,
    this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingHeader(
                showBack: onBack != null,
                onBack: onBack,
              ),
              const Spacer(),
              const Text(
                'I\'m proud of you for wanting to make changes.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Let\'s examine your obstacles scientifically and see how habits and discipline can help you',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // "Got it" button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

