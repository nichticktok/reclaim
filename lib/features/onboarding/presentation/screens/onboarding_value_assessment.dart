import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Value Assessment Screen (Onboarding)
/// Shows: "If you're selling 1 hour of your life, how much would you charge?"
/// This screen is shown during onboarding to assess user's value of time
class OnboardingValueAssessment extends StatefulWidget {
  final Function(int)? onNext;
  final VoidCallback? onBack;

  const OnboardingValueAssessment({
    super.key,
    this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingValueAssessment> createState() => _OnboardingValueAssessmentState();
}

class _OnboardingValueAssessmentState extends State<OnboardingValueAssessment> {
  double _value = 10.0; // Default $10/hour

  @override
  Widget build(BuildContext context) {
    final hourlyValue = _value.round();
    final weeklySavings = (hourlyValue * 40).toStringAsFixed(0);
    final monthlySavings = (hourlyValue * 40 * 4).toStringAsFixed(0);

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
                'If you\'re selling 1 hour of your life, how much would you charge?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Value display
              Center(
                child: Text(
                  '\$${hourlyValue.toStringAsFixed(0)}/hour',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.orange,
                  thumbColor: Colors.orange,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _value,
                  min: 1,
                  max: 200,
                  divisions: 199,
                  onChanged: (value) => setState(() => _value = value),
                ),
              ),
              const SizedBox(height: 20),
              // Savings calculation
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSavingsRow('Weekly savings', '\$$weeklySavings'),
                    const SizedBox(height: 12),
                    _buildSavingsRow('Monthly savings', '\$$monthlySavings'),
                  ],
                ),
              ),
              const Spacer(),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => widget.onNext?.call(hourlyValue),
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

  Widget _buildSavingsRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

