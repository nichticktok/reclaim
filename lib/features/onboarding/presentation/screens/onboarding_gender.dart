import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';
import '../../../../l10n/app_localizations.dart';

/// Reclaim — Onboarding Gender Selector (Step 4)
class OnboardingGender extends StatefulWidget {
  /// onNext receives a stable id (e.g., "male", "female", "other", "prefer_not")
  final Function(String) onNext;
  final VoidCallback onBack;

  const OnboardingGender({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingGender> createState() => _OnboardingGenderState();
}

class _OnboardingGenderState extends State<OnboardingGender> {
  String? selectedId;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Localized title and option labels
    final String title = l10n.onboardingGenderTitle;
    final items = [
      _GenderItem(id: 'male', label: l10n.onboardingGenderMale),
      _GenderItem(id: 'female', label: l10n.onboardingGenderFemale),
      _GenderItem(id: 'other', label: l10n.onboardingGenderOther),
      _GenderItem(id: 'prefer_not', label: l10n.onboardingGenderPreferNot),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Unified header: reads progress from InheritedOnboardingProgress
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
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 32),

              // --- Options (localized labels; stable ids) ---
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final opt = items[index];
                    final isSelected = selectedId == opt.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedId = opt.id);
                        Future.delayed(const Duration(milliseconds: 250), () {
                          widget.onNext(opt.id); // store stable id
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.transparent,
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  )
                                ]
                              : const [],
                        ),
                        child: Center(
                          child: Text(
                            opt.label, // localized
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderItem {
  final String id;     // e.g., "male"
  final String label;  // localized label from LanguageProvider
  const _GenderItem({required this.id, required this.label});
}
