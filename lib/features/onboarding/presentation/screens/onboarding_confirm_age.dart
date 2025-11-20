import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';
import '../../../../l10n/app_localizations.dart';

/// Reclaim — Onboarding Confirm Age (no asset images)
/// Step 7: Shows name, gender (as icon + localized label), and a scrollable age picker.
class OnboardingConfirmAge extends StatefulWidget {
  final String name;

  /// Expect a stable gender id: 'male' | 'female' | 'other' | 'prefer_not'
  /// (If your caller still passes localized text, normalize it before constructing this widget.)
  final String gender;

  final VoidCallback onBack;
  final Function(int) onNext;

  const OnboardingConfirmAge({
    super.key,
    required this.name,
    required this.gender,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<OnboardingConfirmAge> createState() => _OnboardingConfirmAgeState();
}

class _OnboardingConfirmAgeState extends State<OnboardingConfirmAge> {
  int selectedAge = 18;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: selectedAge - 10);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _genderIcon(String id) {
    switch (id) {
      case 'male':
        return Icons.male_rounded;
      case 'female':
        return Icons.female_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Normalize gender id (defensive)
    final genderId = (() {
      final g = widget.gender.trim().toLowerCase();
      if (g == 'male' || g == 'female' || g == 'other' || g == 'prefer_not') return g;
      // attempt to map common English labels
      if (g == 'm') return 'male';
      if (g == 'f') return 'female';
      // fallback
      return 'other';
    })();
    final genderLabel = genderId == 'male' ? l10n.onboardingGenderMale
        : genderId == 'female' ? l10n.onboardingGenderFemale
        : genderId == 'other' ? l10n.onboardingGenderOther
        : l10n.onboardingGenderPreferNot;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ Global header (progress + back + language)
              OnboardingHeader(
                showBack: true,
                onBack: widget.onBack,
              ),

              const SizedBox(height: 40),

              // --- Title (localized) ---
              Text(
                // You can keep using 'howOld' or create a dedicated key like 'onboarding_confirm_age.title'
                l10n.howOld,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // --- Character Avatar (icon)
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white12,
                child: Icon(
                  _genderIcon(genderId),
                  size: 70,
                  color: Colors.orangeAccent,
                ),
              ),

              const SizedBox(height: 16),

              // --- Name + Gender Tag (gender label localized) ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _genderIcon(genderId),
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          genderLabel, // ✅ localized gender
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- Age Picker (numbers localized) ---
              Expanded(
                child: Center(
                  child: SizedBox(
                    height: 150,
                    child: ListWheelScrollView.useDelegate(
                      controller: _scrollController,
                      physics: const FixedExtentScrollPhysics(),
                      itemExtent: 48,
                      onSelectedItemChanged: (index) {
                        setState(() => selectedAge = index + 10);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final age = index + 10; // 10..99
                          final isSelected = age == selectedAge;
                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isSelected ? 28 : 20,
                                color: isSelected ? Colors.white : Colors.white54,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                              ),
                              child: Text(age.toString()), // ✅ localized digits
                            ),
                          );
                        },
                        childCount: 90, // ages 10–99
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Confirm Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onNext(selectedAge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFFFF7A00).withValues(alpha: 0.4),
                  ),
                  child: Text(
                    l10n.confirm,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
