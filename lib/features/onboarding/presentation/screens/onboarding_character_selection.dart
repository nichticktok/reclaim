import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Character Selection Screen
/// Part of onboarding flow
class OnboardingCharacterSelection extends StatefulWidget {
  final Function(String) onNext;
  final VoidCallback? onBack;

  const OnboardingCharacterSelection({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingCharacterSelection> createState() => _OnboardingCharacterSelectionState();
}

class _OnboardingCharacterSelectionState extends State<OnboardingCharacterSelection> {
  String? _selectedCharacter;

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
                'Choose your character',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              // Character selection UI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCharacterOption('male', 'Male', Icons.person),
                  _buildCharacterOption('female', 'Female', Icons.person_outline),
                ],
              ),
              const Spacer(),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedCharacter != null
                      ? () => widget.onNext(_selectedCharacter!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCharacter != null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.15),
                    foregroundColor: _selectedCharacter != null
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

  Widget _buildCharacterOption(String value, String label, IconData icon) {
    final isSelected = _selectedCharacter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCharacter = value),
      child: Container(
        width: 140,
        height: 180,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: isSelected ? Colors.orange : Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

