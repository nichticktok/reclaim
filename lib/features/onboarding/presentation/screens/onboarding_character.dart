import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/onboarding_header.dart';
import '../../../../providers/language_provider.dart';

/// Reclaim — Onboarding Character Selection (No Images)
class OnboardingCharacter extends StatefulWidget {
  final Function(String) onNext;
  final VoidCallback onBack;

  const OnboardingCharacter({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingCharacter> createState() => _OnboardingCharacterState();
}

class _OnboardingCharacterState extends State<OnboardingCharacter> {
  String? selectedCharacter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);
    bool isSelected(String c) => selectedCharacter == c;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ Unified header (progress + back + language)
              OnboardingHeader(
                showBack: true,
                onBack: widget.onBack,
              ),

              const SizedBox(height: 40),

              // --- Title ---
              Text(
                lang.t('chooseCharacter'), // add this key in LanguageProvider
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              // --- Character Selection (Icons) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCharacterOption(
                    label: lang.t('female'), // "Female"
                    icon: Icons.female_rounded,
                    selected: isSelected("Female"),
                    onTap: () => setState(() => selectedCharacter = "Female"),
                  ),
                  _buildCharacterOption(
                    label: lang.t('male'), // "Male"
                    icon: Icons.male_rounded,
                    selected: isSelected("Male"),
                    onTap: () => setState(() => selectedCharacter = "Male"),
                  ),
                ],
              ),

              const Spacer(),

              // --- Continue Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedCharacter == null
                      ? null
                      : () => widget.onNext(selectedCharacter!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFFFF7A00).withValues(alpha: 0.4),
                  ),
                  child: Text(
                    lang.t('continue'), // add this key (e.g. "Continue")
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.2,
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

  Widget _buildCharacterOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0x33FF7A00)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: selected ? const Color(0xFFFF7A00) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: selected ? Colors.orange : Colors.white70,
              size: 70,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.orange : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
