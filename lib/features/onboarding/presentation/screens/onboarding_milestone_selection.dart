import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Milestone Selection Screen (Onboarding)
/// Allows users to choose their milestone duration (1 month, 2 months, 3 months, etc.)
class OnboardingMilestoneSelection extends StatefulWidget {
  final Function(int, String) onNext; // (totalDays, name)
  final VoidCallback? onBack;

  const OnboardingMilestoneSelection({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingMilestoneSelection> createState() => _OnboardingMilestoneSelectionState();
}

class _OnboardingMilestoneSelectionState extends State<OnboardingMilestoneSelection> {
  int? selectedDays;
  String? selectedName;

  final List<Map<String, dynamic>> _milestoneOptions = [
    {'days': 30, 'name': '1 Month', 'description': 'Perfect for building new habits'},
    {'days': 60, 'name': '2 Months', 'description': 'Great for significant transformation'},
    {'days': 90, 'name': '3 Months', 'description': 'Ideal for lasting change'},
    {'days': 120, 'name': '4 Months', 'description': 'For deep transformation'},
    {'days': 180, 'name': '6 Months', 'description': 'Maximum commitment'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              
              // Title
              Text(
                'Choose Your Milestone',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set a goal that works for you. You can always extend it later.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // Milestone Options
              Expanded(
                child: ListView.separated(
                  itemCount: _milestoneOptions.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final option = _milestoneOptions[index];
                    final days = option['days'] as int;
                    final name = option['name'] as String;
                    final description = option['description'] as String;
                    final isSelected = selectedDays == days;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDays = days;
                          selectedName = name;
                        });
                        Future.delayed(const Duration(milliseconds: 250), () {
                          widget.onNext(days, name);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.orange,
                                size: 28,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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

