import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:recalim/core/providers/language_provider.dart' show LangOption;

/// Reclaim — Onboarding Life Description (Step 5)
class OnboardingLifeDescription extends StatefulWidget {
  /// onNext receives a stable id (e.g., "life_satisfied", not the localized label)
  final Function(String) onNext;
  final VoidCallback onBack;

  const OnboardingLifeDescription({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingLifeDescription> createState() =>
      _OnboardingLifeDescriptionState();
}

class _OnboardingLifeDescriptionState extends State<OnboardingLifeDescription> {
  String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // 🔤 Localized title + options
    final String title = l10n.onboardingLifeTitle;
    final options = [
      LangOption(id: 'life_satisfied', label: l10n.onboardingLifeSatisfied),
      LangOption(id: 'life_self_improve', label: l10n.onboardingLifeSelfImprove),
      LangOption(id: 'life_okay_neutral', label: l10n.onboardingLifeOkayNeutral),
      LangOption(id: 'life_often_sad', label: l10n.onboardingLifeOftenSad),
      LangOption(id: 'life_lowest_need_help', label: l10n.onboardingLifeLowestNeedHelp),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Shared header (progress/back/language from context)
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
                  itemCount: options.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    final isSelected = selectedId == opt.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedId = opt.id);
                        Future.delayed(const Duration(milliseconds: 250), () {
                          widget.onNext(opt.id); // ✅ pass stable id only
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 16,
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
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            opt.label, // ✅ localized via mapping
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
