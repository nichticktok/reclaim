import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/onboarding_header.dart';
import '../../../../providers/language_provider.dart';

/// Reclaim — Onboarding Journey Drive (Step 11)
class OnboardingJourneyDrive extends StatefulWidget {
  /// onNext receives a stable id: ambition | love | growth | peace | curiosity
  final Function(String) onNext;
  final VoidCallback onBack;

  const OnboardingJourneyDrive({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingJourneyDrive> createState() => _OnboardingJourneyDriveState();
}

class _OnboardingJourneyDriveState extends State<OnboardingJourneyDrive> {
  String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context, listen: true);

    // 🔤 Localized title + options from LanguageProvider mapping
    final String title = lang.t('onboarding_drive.title');
    final options = lang.options('onboarding_drive'); // List<LangOption>(id,label)

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Global header (reads progress from InheritedOnboardingProgress)
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

              const SizedBox(height: 32),

              // --- Options (labels localized; stable ids)
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
                          widget.onNext(opt.id); // ✅ pass stable id
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
