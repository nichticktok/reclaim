import 'package:flutter/material.dart';
import 'dart:async';

/// Analysis/Loading Screen
/// Shows: "Analysing your current habits..." with animated progress bar
class OnboardingAnalysis extends StatefulWidget {
  final Function()? onNext;

  const OnboardingAnalysis({
    super.key,
    this.onNext,
  });

  @override
  State<OnboardingAnalysis> createState() => _OnboardingAnalysisState();
}

class _OnboardingAnalysisState extends State<OnboardingAnalysis> {
  double _progress = 0.0;
  Timer? _timer;
  int _currentStep = 0;
  
  final List<String> _analysisSteps = [
    'Analyzing your responses...',
    'Calculating your baseline...',
    'Generating your personalized program...',
    'Almost done...',
  ];

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _progress += 0.02;
          if (_progress >= 1.0) {
            _progress = 1.0;
            timer.cancel();
            // Auto-advance after completion
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && widget.onNext != null) {
                widget.onNext!();
              }
            });
          } else {
            // Update step based on progress
            final newStep = (_progress * _analysisSteps.length).floor();
            if (newStep != _currentStep && newStep < _analysisSteps.length) {
              _currentStep = newStep;
            }
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        size: 50,
                        color: Colors.orange,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                'Analysing your current habits...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Progress bar
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Current step text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _analysisSteps[_currentStep.clamp(0, _analysisSteps.length - 1)],
                  key: ValueKey(_currentStep),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              // Percentage
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

