import 'package:flutter/material.dart';
import '../widgets/onboarding_header.dart';

/// Extra Tasks Screen (Onboarding)
/// Shows: "Do you want to add any extra tasks to the program? (Max 2)"
/// This screen is shown during onboarding to allow custom task selection
class OnboardingExtraTasks extends StatefulWidget {
  final Function(List<String>)? onNext;
  final VoidCallback? onBack;

  const OnboardingExtraTasks({
    super.key,
    this.onNext,
    this.onBack,
  });

  @override
  State<OnboardingExtraTasks> createState() => _OnboardingExtraTasksState();
}

class _OnboardingExtraTasksState extends State<OnboardingExtraTasks> {
  final List<String> _selectedTasks = [];
  final List<String> _availableTasks = [
    'Journalling',
    'Push up',
    'No fap',
    'Cold shower',
    'Meditation',
    'Reading',
  ];

  void _toggleTask(String task) {
    setState(() {
      if (_selectedTasks.contains(task)) {
        _selectedTasks.remove(task);
      } else if (_selectedTasks.length < 2) {
        _selectedTasks.add(task);
      }
    });
  }

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
                'Do you want to add any extra tasks to the program? (Max 2)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Task selection grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _availableTasks.length,
                  itemBuilder: (context, index) {
                    final task = _availableTasks[index];
                    final isSelected = _selectedTasks.contains(task);
                    final isDisabled = !isSelected && _selectedTasks.length >= 2;
                    return GestureDetector(
                      onTap: isDisabled ? null : () => _toggleTask(task),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orange
                                : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.orange,
                                  size: 24,
                                )
                              else
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.white54,
                                  size: 24,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                task,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => widget.onNext?.call(_selectedTasks),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
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
}

