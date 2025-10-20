import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

/// Reclaim — Onboarding Awakening
/// Step 9: Cinematic transitional screen with dramatic text
class OnboardingAwakening extends StatefulWidget {
  final VoidCallback onNext;

  const OnboardingAwakening({super.key, required this.onNext});

  @override
  State<OnboardingAwakening> createState() => _OnboardingAwakeningState();
}

class _OnboardingAwakeningState extends State<OnboardingAwakening>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;
  Timer? _autoTimer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _fadeOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto-continue after a short pause
    _autoTimer = Timer(const Duration(milliseconds: 5500), _goNextSafely);
  }

  void _goNextSafely() {
    if (_completed) return;
    _completed = true;
    if (mounted) widget.onNext();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    // Provide defaults if keys not present yet
    final line1 = lang.t('awakening_line1'); // "You were just another face in"
    final line2 = lang.t('awakening_line2'); // "the crowd."
    final line3 = lang.t('awakening_line3'); // "Tired. Stuck. Running on\nautopilot... until now."
    final skip  = lang.t('next');            // reuse "Next →" label for Skip/Continue

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _goNextSafely, // tap anywhere to continue
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final fadeValue =
                  _controller.value < 0.6 ? _fadeIn.value : 1 - _fadeOut.value * 0.8;

              return Opacity(
                opacity: fadeValue.clamp(0.0, 1.0),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A0A0A),
                        Color(0xFF1A0A00),
                        Color(0xFF2D0F00),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Center content
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 42,
                                color: Colors.orange.withOpacity(0.9),
                                semanticLabel: 'Awakening',
                              ),
                              const SizedBox(height: 60),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: "$line1\n"),
                                    TextSpan(
                                      text: line2,
                                      style: TextStyle(
                                        color: Colors.orange.shade300,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                line3,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom-right "Skip / Continue" button
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: ElevatedButton.icon(
                          onPressed: _goNextSafely,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                            shadowColor: const Color(0xFFFF7A00).withOpacity(0.35),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text(
                            skip,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
