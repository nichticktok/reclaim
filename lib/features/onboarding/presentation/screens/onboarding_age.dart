import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/onboarding_header.dart';

/// Reclaim — Onboarding Age Selector
class OnboardingAge extends StatefulWidget {
  /// We'll pass a stable id (e.g., "18_24") rather than the localized label.
  final Function(String) onNext;
  final VoidCallback onBack;

  const OnboardingAge({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingAge> createState() => _OnboardingAgeState();
}

class _OnboardingAgeState extends State<OnboardingAge> {
  String? selectedId;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final String title = l10n.onboardingAgeTitle;
    // Resolve localized labels from ids
    final List<_AgeViewItem> items = [
      _AgeViewItem(id: '13_17', label: l10n.onboardingAge13_17),
      _AgeViewItem(id: '18_24', label: l10n.onboardingAge18_24),
      _AgeViewItem(id: '25_34', label: l10n.onboardingAge25_34),
      _AgeViewItem(id: '35_44', label: l10n.onboardingAge35_44),
      _AgeViewItem(id: '45_54', label: l10n.onboardingAge45_54),
      _AgeViewItem(id: '55_plus', label: l10n.onboardingAge55_plus),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingHeader(
                showBack: true,
                onBack: widget.onBack,
              ),

              const SizedBox(height: 48),

              // --- Question (from mapping) ---
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 32),

              // --- Options (labels fully localized) ---
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
                            opt.label, // localized via mapping
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

class _AgeViewItem {
  final String id;     // e.g., "18_24"
  final String label;  // localized label from LanguageProvider
  const _AgeViewItem({required this.id, required this.label});
}
