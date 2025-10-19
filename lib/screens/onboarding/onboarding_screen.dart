import 'package:flutter/material.dart';
import 'onboarding_name.dart';
import 'onboarding_focus.dart';
import 'onboarding_proof_mode.dart';
import 'onboarding_summary.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  String? name;
  List<String> selectedFocus = [];
  bool proofMode = false;

  final List<Widget> steps = [];

  @override
  void initState() {
    super.initState();
  }

  void nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      OnboardingName(onNext: (value) {
        name = value;
        nextStep();
      }),
      OnboardingFocus(onNext: (list) {
        selectedFocus = list;
        nextStep();
      }),
      OnboardingProofMode(onNext: (enabled) {
        proofMode = enabled;
        nextStep();
      }),
      OnboardingSummary(
        name: name ?? '',
        focusAreas: selectedFocus,
        proofMode: proofMode,
        onFinish: nextStep,
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: screens[_currentStep],
      ),
    );
  }
}
