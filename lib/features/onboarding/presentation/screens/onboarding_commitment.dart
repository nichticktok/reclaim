import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Commitment/Streak Selection Screen
/// Part of onboarding flow
class OnboardingCommitment extends StatefulWidget {
  final Function(int) onNext;
  final VoidCallback? onBack;

  const OnboardingCommitment({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingCommitment> createState() => _OnboardingCommitmentState();
}

class _OnboardingCommitmentState extends State<OnboardingCommitment> {
  int? _selectedDays;
  final List<Map<String, dynamic>> _options = [
    {'days': 7, 'percentage': '15%', 'label': '7 Days'},
    {'days': 14, 'percentage': '30%', 'label': '14 Days'},
    {'days': 30, 'percentage': '50%', 'label': '30 Days'},
    {'days': 50, 'percentage': '75%', 'label': '50 Days'},
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
                'Commit to growing with Reclaim',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Streak option cards
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final days = option['days'] as int;
                    final percentage = option['percentage'] as String;
                    final label = option['label'] as String;
                    final isSelected = _selectedDays == days;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDays = days),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orange
                                : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              percentage,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.orange
                                    : Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
                  onPressed: _selectedDays != null
                      ? () => widget.onNext(_selectedDays!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedDays != null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.15),
                    foregroundColor: _selectedDays != null
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

