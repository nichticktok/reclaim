// OnboardingHeader.dart (your file with tiny edits)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/language_provider.dart';
import '../screens/onboarding_screen.dart'; // InheritedOnboardingProgress

class OnboardingHeader extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;

  const OnboardingHeader({
    super.key,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final currentLang = lang.currentLang;

    final inherited = InheritedOnboardingProgress.of(context);
    final rawProgress = inherited?.progress ?? 0.0;
    final progressValue = rawProgress.clamp(0.0, 1.0);
    final totalSteps = inherited?.totalSteps ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalSteps > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
              minHeight: 6,
            ),
          ),

        if (totalSteps > 0) const SizedBox(height: 16),

        Row(
          children: [
            if (showBack)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onBack,
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
            if (showBack) const SizedBox(width: 12),

            const Spacer(),

            // 🌍 Language selector
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1A1A1A),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: const Text('English', style: TextStyle(color: Colors.white)),
                        trailing: currentLang == 'English'
                            ? const Icon(Icons.check, color: Colors.orange) : null,
                        onTap: () { lang.setLanguage('English'); Navigator.pop(context); },
                      ),
                      ListTile(
                        title: const Text('Nepali', style: TextStyle(color: Colors.white)),
                        trailing: currentLang == 'Nepali'
                            ? const Icon(Icons.check, color: Colors.orange) : null,
                        onTap: () { lang.setLanguage('Nepali'); Navigator.pop(context); },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(currentLang,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
