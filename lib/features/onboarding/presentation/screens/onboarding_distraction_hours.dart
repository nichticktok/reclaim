import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Distraction Hours Screen (Onboarding)
/// Shows: "How many hours a week do you waste on distractions in life?"
/// This screen is shown during onboarding to assess time wasted
class OnboardingDistractionHours extends StatefulWidget {
  final Function(int)? onNext;
  final VoidCallback? onBack;

  const OnboardingDistractionHours({
    super.key,
    this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingDistractionHours> createState() => _OnboardingDistractionHoursState();
}

class _OnboardingDistractionHoursState extends State<OnboardingDistractionHours> {
  double _hours = 10.0;

  @override
  Widget build(BuildContext context) {
    final hoursInt = _hours.round();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingHeader(
                showBack: widget.onBack != null,
                onBack: widget.onBack,
              ),
              const SizedBox(height: 48),
              const Text(
                'How many hours a week do you waste on distractions in life?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Eg. doom scrolling, procrastinating...',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Circular selector
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hoursInt.toString(),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'hours',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.orange,
                  thumbColor: Colors.orange,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _hours,
                  min: 0,
                  max: 50,
                  divisions: 50,
                  onChanged: (value) => setState(() => _hours = value),
                ),
              ),
              const Spacer(),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => widget.onNext?.call(hoursInt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
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

