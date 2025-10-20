import 'package:flutter/material.dart';

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
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;

  // Collected data from the user
  String? name;
  String? ageGroup;
  String? gender;
  String? lifeDescription;
  String? character;
  int? confirmedAge;
  String? mainCharacterFeeling;
  String? motivation;
  List<String>? darkHabits;

  /// Dynamically build onboarding screens (safe and lazy-loaded)
  List<Widget> get screens => [
        // 1️⃣ Name
        OnboardingName(onNext: (value) {
          name = value;
          nextStep();
        }),

        // 2️⃣ Intro
        OnboardingIntro(onStart: nextStep),

        // 3️⃣ Age
        OnboardingAge(
          onBack: prevStep,
          onNext: (selectedAge) {
            ageGroup = selectedAge;
            nextStep();
          },
        ),

        // 4️⃣ Gender
        OnboardingGender(
          onBack: prevStep,
          onNext: (selectedGender) {
            gender = selectedGender;
            nextStep();
          },
        ),

        // 5️⃣ Life description
        OnboardingLifeDescription(
          onBack: prevStep,
          onNext: (desc) {
            lifeDescription = desc;
            nextStep();
          },
        ),

        // 6️⃣ Character selection
        OnboardingCharacter(
          onBack: prevStep,
          onNext: (selectedCharacter) {
            character = selectedCharacter;
            nextStep();
          },
        ),

        // 7️⃣ Confirm age
        OnboardingConfirmAge(
          name: name ?? 'User',
          gender: gender ?? 'Male',
          onBack: prevStep,
          onNext: (age) {
            confirmedAge = age;
            nextStep();
          },
        ),

        // 8️⃣ Notification
        OnboardingNotification(
          name: name ?? 'User',
          onAccept: nextStep,
        ),

        // 9️⃣ Awakening
        OnboardingAwakening(onNext: nextStep),

        // 🔟 Main character
        OnboardingMainCharacter(
          onBack: prevStep,
          onNext: (answer) {
            mainCharacterFeeling = answer;
            nextStep();
          },
        ),

        // 11️⃣ Journey drive
        OnboardingJourneyDrive(
          onBack: prevStep,
          onNext: (drive) {
            motivation = drive;
            nextStep();
          },
        ),

        // 12️⃣ Dark habits
        OnboardingDarkHabits(
          onBack: prevStep,
          onNext: (habits) {
            darkHabits = habits;
            nextStep();
          },
        ),

        // 13️⃣ Final transformation
        OnboardingTransformation(
          onFinish: () {
            Navigator.pushReplacementNamed(context, '/home_screen');
          },
        ),
      ];

  /// Total number of steps (auto-updates if you add/remove pages)
  int get totalSteps => screens.length;

  /// Current progress (0.0 – 1.0)
  double get progress => (_currentStep + 1) / totalSteps;

  /// Move forward to next screen
  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      Navigator.pushReplacementNamed(context, '/home_screen');
    }
  }

  /// Move back to previous screen
  void prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
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

/// ✅ Inherited widget to share progress + step info with all pages
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

  static InheritedOnboardingProgress? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<
        InheritedOnboardingProgress>();
  }

  @override
  bool updateShouldNotify(covariant InheritedOnboardingProgress oldWidget) =>
      progress != oldWidget.progress ||
      stepIndex != oldWidget.stepIndex ||
      totalSteps != oldWidget.totalSteps;
}
