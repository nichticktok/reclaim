import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/onboarding_header.dart';
import '../../providers/language_provider.dart';

/// Reclaim — Onboarding Dark Habits (Step 12)
class OnboardingDarkHabits extends StatefulWidget {
  /// onNext receives a list of stable ids (e.g., ["procrastination","overthinking"])
  final Function(List<String>) onNext;
  final VoidCallback onBack;

  const OnboardingDarkHabits({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingDarkHabits> createState() => _OnboardingDarkHabitsState();
}

class _OnboardingDarkHabitsState extends State<OnboardingDarkHabits> {
  final Set<String> selected = <String>{};

  void _toggle(String id) {
    setState(() {
      if (selected.contains(id)) {
        selected.remove(id);
      } else {
        selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context, listen: true);

    // 🔤 Localized title + options from LanguageProvider
    final String title = lang.t('onboarding_dark.title');
    final options = lang.options('onboarding_dark'); // List<LangOption>(id,label)

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Shared header (progress/back/language via context)
              OnboardingHeader(
                showBack: true,
                onBack: widget.onBack,
              ),

              const SizedBox(height: 48),

              // --- Question (localized) ---
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),

              // --- Habit Chips (localized labels; stable ids) ---
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: options.map((opt) {
                  final isSelected = selected.contains(opt.id);
                  return GestureDetector(
                    onTap: () => _toggle(opt.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? Colors.orangeAccent : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        opt.label, // localized
                        style: TextStyle(
                          color: isSelected ? Colors.orange : Colors.white,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // --- Continue Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => widget.onNext(selected.toList()), // ✅ stable ids out
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
                    // localized common button text
                    // (you already have 'continue' in your mapping)
                    // if you prefer a screen-specific label, add onboarding_dark.cta
                    'Continue',
                    // lang.t('continue'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.3,
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
