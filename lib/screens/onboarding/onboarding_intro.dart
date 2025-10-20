import 'package:flutter/material.dart';

/// Reclaim — Onboarding Intro (no image)
/// Headline + subcopy + orange CTA. One-file, drop-in screen.
class OnboardingIntro extends StatelessWidget {
  final VoidCallback onStart;
  final String programName; // e.g., "Reclaim" or "life reset program"

  const OnboardingIntro({
    super.key,
    required this.onStart,
    this.programName = 'Reclaim',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Small emblem
              Icon(
                Icons.auto_awesome_rounded,
                size: 24,
                color: Colors.white.withOpacity(0.9),
              ),

              const SizedBox(height: 20),

              // Headline
              Text(
                'Understanding more\nabout your situation',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 12),

              // Subheadline
              Text(
                'Answer all questions honestly',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              // Description
              Text(
                'We will use the answers to design a tailor-made $programName program for you.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // CTA (custom orange button to match mock)
              _StartButton(
                label: "Let's start",
                onPressed: onStart,
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _StartButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // Colors tuned to look like the mock: bright orange with soft border/shadow
    const orange = Color(0xFFFF7A00);
    const orangeDark = Color(0xFFE56D00);
    const border = Color(0xFFFFC48A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [orange, orangeDark],
            ),
            border: Border.all(color: border, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                spreadRadius: 1,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
