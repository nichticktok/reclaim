import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Habits Questions Screen (Onboarding)
/// Shows: Questions about current habits with sliders
/// This screen is shown during onboarding to gather habit baseline data
class OnboardingHabitsQuestions extends StatefulWidget {
  final Function(Map<String, dynamic>)? onNext;
  final VoidCallback? onBack;
  final String questionType; // 'wake_up', 'water', 'exercise', 'meditation', 'reading', 'social_media', 'cold_shower'

  const OnboardingHabitsQuestions({
    super.key,
    required this.questionType,
    this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingHabitsQuestions> createState() => _OnboardingHabitsQuestionsState();
}

class _OnboardingHabitsQuestionsState extends State<OnboardingHabitsQuestions> {
  double _value = 0.5;

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
              Text(
                _getQuestionText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Character illustration with animated icon
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.withValues(alpha: 0.2),
                              Colors.orange.withValues(alpha: 0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getIconForQuestion(),
                          size: 70,
                          color: Colors.orange,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              // Slider
              Text(
                _getValueText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.orange,
                  thumbColor: Colors.orange,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _value,
                  onChanged: (value) => setState(() => _value = value),
                ),
              ),
              const Spacer(),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => widget.onNext?.call({
                    widget.questionType: _getValueText(),
                  }),
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

  String _getQuestionText() {
    switch (widget.questionType) {
      case 'wake_up':
        return 'What time do you usually wake up at right now?';
      case 'water':
        return 'How much water do you drink a day right now?';
      case 'exercise':
        return 'How many hours do you usually work out in a week?';
      case 'meditation':
        return 'How much time do you spend on meditating in a week?';
      case 'reading':
        return 'How much time do you spend on reading books in a week?';
      case 'social_media':
        return 'How much time do you spend on social media in a day?';
      case 'cold_shower':
        return 'How often do you take a cold shower in a week?';
      case 'running':
        return 'How much do you usually run in a week?';
      default:
        return 'Habit Question';
    }
  }

  IconData _getIconForQuestion() {
    switch (widget.questionType) {
      case 'wake_up':
        return Icons.wb_sunny_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'meditation':
        return Icons.self_improvement_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'social_media':
        return Icons.phone_android_rounded;
      case 'cold_shower':
        return Icons.shower_rounded;
      case 'running':
        return Icons.directions_run_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _getValueText() {
    switch (widget.questionType) {
      case 'wake_up':
        final hour = (6 + (_value * 6)).round();
        return '$hour:00 AM';
      case 'water':
        final liters = (0.5 + (_value * 3.5)).toStringAsFixed(1);
        return '$liters L';
      case 'exercise':
      case 'meditation':
      case 'reading':
        final hours = (_value * 10).toStringAsFixed(1);
        return '$hours hrs';
      case 'social_media':
        final hours = (_value * 8).toStringAsFixed(1);
        return '$hours hrs';
      case 'cold_shower':
        final times = (_value * 7).round();
        return '$times times';
      case 'running':
        final km = (_value * 20).toStringAsFixed(1);
        return '$km km';
      default:
        return (_value * 100).toStringAsFixed(0);
    }
  }
}

