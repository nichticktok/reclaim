import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Goal Setting Screen
/// Part of onboarding flow
class OnboardingGoalSetting extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback? onBack;

  const OnboardingGoalSetting({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingGoalSetting> createState() => _OnboardingGoalSettingState();
}

class _OnboardingGoalSettingState extends State<OnboardingGoalSetting> {
  String? _selectedGoal;
  final List<String> _goals = [
    'Financial Freedom',
    'Physical Health',
    'Mental Clarity',
    'Career Success',
    'Relationships',
    'Personal Growth',
  ];

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
                showBack: widget.onBack != null,
                onBack: widget.onBack,
              ),
              const SizedBox(height: 48),
              const Text(
                'What\'s the endgame you\'re striving for?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Goal selection options
              Expanded(
                child: ListView.builder(
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    final isSelected = _selectedGoal == goal;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGoal = goal),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.orange.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.orange
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  goal,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.orange,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedGoal != null
                      ? () => widget.onNext({'goal': _selectedGoal!})
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGoal != null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.15),
                    foregroundColor: _selectedGoal != null
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.5),
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

