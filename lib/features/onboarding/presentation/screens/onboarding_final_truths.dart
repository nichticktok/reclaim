import 'package:flutter/material.dart';

/// Final Truths Screen (Onboarding)
/// Shows: "Before your journey begins, Reclaim must know a few final truths..."
/// This screen is shown during onboarding as a transition
class OnboardingFinalTruths extends StatefulWidget {
  final Function()? onNext;

  const OnboardingFinalTruths({
    super.key,
    this.onNext,
  });

  @override
  State<OnboardingFinalTruths> createState() => _OnboardingFinalTruthsState();
}

class _OnboardingFinalTruthsState extends State<OnboardingFinalTruths> {
  @override
  void initState() {
    super.initState();
    // Auto-advance after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.onNext != null) {
        widget.onNext!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.orange,
            ),
            const SizedBox(height: 40),
            const Text(
              'Before your journey begins, Reclaim\nmust know a few final\ntruths...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

