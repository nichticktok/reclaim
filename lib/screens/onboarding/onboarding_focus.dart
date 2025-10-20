import 'package:flutter/material.dart';

class OnboardingFocus extends StatefulWidget {
  final Function(List<String>) onNext;
  const OnboardingFocus({super.key, required this.onNext});

  @override
  State<OnboardingFocus> createState() => _OnboardingFocusState();
}

class _OnboardingFocusState extends State<OnboardingFocus> {
  final List<String> _focusOptions = [
    "Health 🧘‍♂️",
    "Discipline ⏰",
    "Learning 📚",
    "Career 💼",
    "Mindfulness 🧠",
    "Relationships ❤️"
  ];

  final List<String> _selectedFocus = [];

  void toggleFocus(String focus) {
    setState(() {
      if (_selectedFocus.contains(focus)) {
        _selectedFocus.remove(focus);
      } else {
        _selectedFocus.add(focus);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Choose Your Focus Areas 🌱",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Pick the areas of life you want to work on. You can choose multiple.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: _focusOptions.map((focus) {
                    final selected = _selectedFocus.contains(focus);
                    return GestureDetector(
                      onTap: () => toggleFocus(focus),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.blueAccent.withValues(alpha: 0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? Colors.blueAccent
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            focus,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.normal,
                              color:
                                  selected ? Colors.blueAccent : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _selectedFocus.isNotEmpty
                    ? () => widget.onNext(_selectedFocus)
                    : null,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Continue →",
                  style: TextStyle(fontSize: 18, color: Colors.white),
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
