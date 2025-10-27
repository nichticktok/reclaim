import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import all onboarding pages
import 'onboarding_name.dart';
import 'onboarding_intro.dart';
import 'onboarding_age.dart';
import 'onboarding_gender.dart';
import 'onboarding_life_description.dart';
import 'onboarding_character.dart';
import 'onboarding_confirm_age.dart';
import 'onboarding_notification.dart';
import 'onboarding_awakening.dart';
import 'onboarding_main_character.dart';
import 'onboarding_journey_drive.dart';
import 'onboarding_dark_habits.dart';
import 'onboarding_transformation.dart';

class OnboardingScreen extends StatefulWidget {
  final int? startStep; // ✅ optional
  const OnboardingScreen({super.key, this.startStep});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  bool _loading = true;

  // User Data
  String? name;
  String? ageGroup;
  String? gender;
  String? lifeDescription;
  String? character;
  int? confirmedAge;
  String? mainCharacterFeeling;
  String? motivation;
  List<String>? darkHabits;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.startStep ?? 0; // ✅ start from saved step if provided
    _loadProgress();
  }

  /// ✅ Load user onboarding step from Firestore
  Future<void> _loadProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data() ?? {};
      setState(() {
        _currentStep = data['onboardingStep'] ?? widget.startStep ?? 0;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  /// ✅ Save progress to Firestore
  Future<void> _saveProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'onboardingStep': _currentStep,
      'onboardingCompleted': false,
    }, SetOptions(merge: true));
  }

  /// ✅ Mark onboarding completed
  Future<void> _markCompleted() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'onboardingCompleted': true,
      'onboardingStep': _currentStep,
    }, SetOptions(merge: true));
  }

  /// ✅ Move forward
  void nextStep() async {
    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
      await _saveProgress();
    } else {
      await _markCompleted();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home_screen');
      }
    }
  }

  /// ✅ Move backward
  void prevStep() async {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      await _saveProgress();
    }
  }

  /// ✅ All Screens (your existing pages)
  List<Widget> get screens => [
        OnboardingName(onNext: (value) {
          name = value;
          nextStep();
        }),
        OnboardingIntro(onStart: nextStep),
        OnboardingAge(onBack: prevStep, onNext: (value) {
          ageGroup = value;
          nextStep();
        }),
        OnboardingGender(onBack: prevStep, onNext: (value) {
          gender = value;
          nextStep();
        }),
        OnboardingLifeDescription(onBack: prevStep, onNext: (desc) {
          lifeDescription = desc;
          nextStep();
        }),
        OnboardingCharacter(onBack: prevStep, onNext: (value) {
          character = value;
          nextStep();
        }),
        OnboardingConfirmAge(
          name: name ?? 'User',
          gender: gender ?? 'Male',
          onBack: prevStep,
          onNext: (age) {
            confirmedAge = age;
            nextStep();
          },
        ),
        OnboardingNotification(name: name ?? 'User', onAccept: nextStep),
        OnboardingAwakening(onNext: nextStep),
        OnboardingMainCharacter(onBack: prevStep, onNext: (answer) {
          mainCharacterFeeling = answer;
          nextStep();
        }),
        OnboardingJourneyDrive(onBack: prevStep, onNext: (drive) {
          motivation = drive;
          nextStep();
        }),
        OnboardingDarkHabits(onBack: prevStep, onNext: (habits) {
          darkHabits = habits;
          nextStep();
        }),
        OnboardingTransformation(onFinish: () async {
          await _markCompleted();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home_screen');
          }
        }),
      ];

  int get totalSteps => screens.length;
  double get progress => (_currentStep + 1) / totalSteps;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    final current = screens[_currentStep];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOut,
        child: InheritedOnboardingProgress(
          progress: progress,
          stepIndex: _currentStep + 1,
          totalSteps: totalSteps,
          child: current,
        ),
      ),
    );
  }
}

/// ✅ Inherited widget (unchanged)
class InheritedOnboardingProgress extends InheritedWidget {
  final double progress;
  final int stepIndex;
  final int totalSteps;

  const InheritedOnboardingProgress({
    super.key,
    required this.progress,
    required this.stepIndex,
    required this.totalSteps,
    required super.child,
  });

  static InheritedOnboardingProgress? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<
          InheritedOnboardingProgress>();

  @override
  bool updateShouldNotify(covariant InheritedOnboardingProgress oldWidget) =>
      progress != oldWidget.progress ||
      stepIndex != oldWidget.stepIndex ||
      totalSteps != oldWidget.totalSteps;
}
