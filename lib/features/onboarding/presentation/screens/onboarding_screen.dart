import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../providers/language_provider.dart';

// Import all onboarding pages
import 'onboarding_name.dart';
import 'onboarding_age.dart';
import 'onboarding_gender.dart';
import 'onboarding_life_description.dart';
import 'onboarding_character.dart';
import 'onboarding_confirm_age.dart';
import 'onboarding_awakening.dart';
import 'onboarding_main_character.dart';
import 'onboarding_journey_drive.dart';
import 'onboarding_dark_habits.dart';
import 'onboarding_welcome_intro.dart';
import 'onboarding_character_selection.dart';
import 'onboarding_goal_setting.dart';
import 'onboarding_commitment.dart';
import 'onboarding_hard_mode.dart';
import 'onboarding_notifications.dart';
import 'onboarding_extra_tasks.dart';
import 'onboarding_program_overview.dart';
import 'onboarding_program_preview.dart';
import 'onboarding_program_customization.dart';
import 'onboarding_science_backed.dart';
import 'onboarding_66_days_explanation.dart';
import 'onboarding_progressive_difficulty.dart';
import 'onboarding_core_habits.dart';
import 'onboarding_habit_detail.dart';
import 'onboarding_penalty_system.dart';
import 'onboarding_rpg_game.dart';
import 'onboarding_habits_questions.dart';
import 'onboarding_value_assessment.dart';
import 'onboarding_distraction_hours.dart';
import 'onboarding_rating.dart';
import 'onboarding_potential_rating.dart';
import 'onboarding_analysis.dart';
import 'onboarding_real_stories.dart';
import 'onboarding_before_after.dart';
import 'onboarding_mission_awaken.dart';
import 'onboarding_proud_message.dart';
import 'onboarding_vow_questions.dart';
import 'onboarding_lock_in.dart';
import 'onboarding_final_truths.dart';
import 'onboarding_final_review.dart';
import 'onboarding_subscription_offer.dart';
import 'onboarding_refer_code.dart';
import '../widgets/onboarding_header.dart';

class OnboardingScreen extends StatefulWidget {
  final int? startStep; // ✅ optional
  const OnboardingScreen({super.key, this.startStep});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  bool _loading = true;

  // User Data - Comprehensive onboarding responses
  String? name;
  String? ageGroup;
  String? gender;
  String? lifeDescription;
  String? character;
  int? confirmedAge;
  String? mainCharacterFeeling;
  String? motivation;
  List<String>? darkHabits;
  
  // Additional onboarding data
  String? selectedCharacter;
  String? selectedGoal;
  String? commitmentLevel;
  bool? hardModeEnabled;
  Map<String, bool>? notificationSettings;
  Map<String, dynamic>? habitsData; // All habit questions responses
  double? hourlyValue;
  int? distractionHours;
  int? currentRating;
  int? potentialRating;
  List<String>? extraTasks;
  String? referCode;
  Map<String, bool>? vowAnswers;

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

  /// ✅ Save progress to Firestore with all collected data
  /// Uses subcollection structure for better scalability
  Future<void> _saveProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Build comprehensive onboarding data map
    final onboardingData = <String, dynamic>{
      // Basic Info
      if (name != null) 'name': name,
      if (ageGroup != null) 'ageGroup': ageGroup,
      if (gender != null) 'gender': gender,
      if (confirmedAge != null) 'confirmedAge': confirmedAge,
      
      // Character & Identity
      if (character != null) 'character': character,
      if (selectedCharacter != null) 'selectedCharacter': selectedCharacter,
      if (lifeDescription != null) 'lifeDescription': lifeDescription,
      if (mainCharacterFeeling != null) 'mainCharacterFeeling': mainCharacterFeeling,
      
      // Motivation & Goals
      if (motivation != null) 'motivation': motivation,
      if (selectedGoal != null) 'selectedGoal': selectedGoal,
      if (commitmentLevel != null) 'commitmentLevel': commitmentLevel,
      
      // Habits & Lifestyle
      if (darkHabits != null) 'darkHabits': darkHabits,
      if (habitsData != null) 'habitsData': habitsData,
      if (distractionHours != null) 'distractionHours': distractionHours,
      
      // Values & Assessment
      if (hourlyValue != null) 'hourlyValue': hourlyValue,
      if (currentRating != null) 'currentRating': currentRating,
      if (potentialRating != null) 'potentialRating': potentialRating,
      
      // Program Settings
      if (hardModeEnabled != null) 'hardModeEnabled': hardModeEnabled,
      if (notificationSettings != null) 'notificationSettings': notificationSettings,
      if (extraTasks != null) 'extraTasks': extraTasks,
      
      // Additional
      if (referCode != null) 'referCode': referCode,
      if (vowAnswers != null) 'vowAnswers': vowAnswers,
      
      // Metadata
      'onboardingStep': _currentStep,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Save onboarding data to subcollection (better structure)
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('onboarding')
        .doc('data')
        .set(onboardingData, SetOptions(merge: true));
    
    // Update main user document with flags only (lightweight)
    await _firestore.collection('users').doc(user.uid).set({
      'onboardingStep': _currentStep,
      'onboardingCompleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ✅ Mark onboarding completed and save final data
  /// Uses subcollection structure for better scalability
  Future<void> _markCompleted() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Build final comprehensive onboarding data
    final onboardingData = <String, dynamic>{
      // Basic Info
      if (name != null) 'name': name,
      if (ageGroup != null) 'ageGroup': ageGroup,
      if (gender != null) 'gender': gender,
      if (confirmedAge != null) 'confirmedAge': confirmedAge,
      
      // Character & Identity
      if (character != null) 'character': character,
      if (selectedCharacter != null) 'selectedCharacter': selectedCharacter,
      if (lifeDescription != null) 'lifeDescription': lifeDescription,
      if (mainCharacterFeeling != null) 'mainCharacterFeeling': mainCharacterFeeling,
      
      // Motivation & Goals
      if (motivation != null) 'motivation': motivation,
      if (selectedGoal != null) 'selectedGoal': selectedGoal,
      if (commitmentLevel != null) 'commitmentLevel': commitmentLevel,
      
      // Habits & Lifestyle
      if (darkHabits != null) 'darkHabits': darkHabits,
      if (habitsData != null) 'habitsData': habitsData,
      if (distractionHours != null) 'distractionHours': distractionHours,
      
      // Values & Assessment
      if (hourlyValue != null) 'hourlyValue': hourlyValue,
      if (currentRating != null) 'currentRating': currentRating,
      if (potentialRating != null) 'potentialRating': potentialRating,
      
      // Program Settings
      if (hardModeEnabled != null) 'hardModeEnabled': hardModeEnabled,
      if (notificationSettings != null) 'notificationSettings': notificationSettings,
      if (extraTasks != null) 'extraTasks': extraTasks,
      
      // Additional
      if (referCode != null) 'referCode': referCode,
      if (vowAnswers != null) 'vowAnswers': vowAnswers,
      
      // Metadata
      'completedAt': FieldValue.serverTimestamp(),
      'onboardingStep': _currentStep,
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Save final onboarding data to subcollection
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('onboarding')
        .doc('data')
        .set(onboardingData, SetOptions(merge: true));
    
    // Update main user document with flag only (lightweight)
    await _firestore.collection('users').doc(user.uid).set({
      'onboardingCompleted': true,
      'onboardingStep': _currentStep,
      'updatedAt': FieldValue.serverTimestamp(),
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

  /// Skip onboarding (debug mode only)
  Future<void> _skipOnboarding() async {
    await _markCompleted();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home_screen');
    }
  }

  /// ✅ All Screens - Complete onboarding flow
  List<Widget> get screens => [
        // 1. Welcome Intro
        OnboardingWelcomeIntro(
          onStart: nextStep,
        ),
        
        // 2. Name Input
        OnboardingName(
          onBack: _currentStep > 0 ? prevStep : null,
          onNext: (value) {
            name = value;
            nextStep();
          },
          onSkip: kDebugMode ? _skipOnboarding : null, // Debug skip only
        ),
        
        // 3. Age Selection
        OnboardingAge(
          onBack: prevStep,
          onNext: (value) {
            ageGroup = value;
            nextStep();
          },
        ),
        
        // 4. Gender Selection
        OnboardingGender(
          onBack: prevStep,
          onNext: (value) {
            gender = value;
            nextStep();
          },
        ),
        
        // 5. Character Selection
        OnboardingCharacterSelection(
          onBack: prevStep,
          onNext: (value) {
            selectedCharacter = value;
            nextStep();
          },
        ),
        
        // 6. Character Confirmation
        OnboardingCharacter(
          onBack: prevStep,
          onNext: (value) {
            character = value;
            nextStep();
          },
        ),
        
        // 7. Life Description
        OnboardingLifeDescription(
          onBack: prevStep,
          onNext: (desc) {
            lifeDescription = desc;
            nextStep();
          },
        ),
        
        // 8. Confirm Age
        OnboardingConfirmAge(
          name: name ?? 'User',
          gender: gender ?? 'Male',
          onBack: prevStep,
          onNext: (age) {
            confirmedAge = age;
            nextStep();
          },
        ),
        
        // 9. Awakening Message
        OnboardingAwakening(onNext: nextStep),
        
        // 10. Main Character Feeling
        OnboardingMainCharacter(
          onBack: prevStep,
          onNext: (answer) {
            mainCharacterFeeling = answer;
            nextStep();
          },
        ),
        
        // 11. Journey Drive
        OnboardingJourneyDrive(
          onBack: prevStep,
          onNext: (drive) {
            motivation = drive;
            nextStep();
          },
        ),
        
        // 12. Dark Habits
        OnboardingDarkHabits(
          onBack: prevStep,
          onNext: (habits) {
            darkHabits = habits;
            nextStep();
          },
        ),
        
        // 13. Proud Message
        OnboardingProudMessage(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 14. Value Assessment
        OnboardingValueAssessment(
          onBack: prevStep,
          onNext: (value) {
            hourlyValue = value.toDouble();
            nextStep();
          },
        ),
        
        // 15. Distraction Hours
        OnboardingDistractionHours(
          onBack: prevStep,
          onNext: (hours) {
            distractionHours = hours;
            nextStep();
          },
        ),
        
        // 16. Habits Questions - Wake Up
        OnboardingHabitsQuestions(
          questionType: 'wake_up',
          onBack: prevStep,
          onNext: (data) {
            habitsData ??= {};
            habitsData!['wake_up'] = data['wake_up'];
            nextStep();
          },
        ),
        
        // 17. Habits Questions - Water
        OnboardingHabitsQuestions(
          questionType: 'water',
          onBack: prevStep,
          onNext: (data) {
            habitsData ??= {};
            habitsData!['water'] = data['water'];
            nextStep();
          },
        ),
        
        // 18. Habits Questions - Exercise
        OnboardingHabitsQuestions(
          questionType: 'exercise',
          onBack: prevStep,
          onNext: (data) {
            habitsData ??= {};
            habitsData!['exercise'] = data['exercise'];
            nextStep();
          },
        ),
        
        // 19. Habits Questions - Meditation
        OnboardingHabitsQuestions(
          questionType: 'meditation',
          onBack: prevStep,
          onNext: (data) {
            habitsData ??= {};
            habitsData!['meditation'] = data['meditation'];
            nextStep();
          },
        ),
        
        // 20. Habits Questions - Reading
        OnboardingHabitsQuestions(
          questionType: 'reading',
          onBack: prevStep,
          onNext: (data) {
            habitsData ??= {};
            habitsData!['reading'] = data['reading'];
            nextStep();
          },
        ),
        
        // 21. Habits Questions - Social Media
        OnboardingHabitsQuestions(
          questionType: 'social_media',
          onBack: prevStep,
          onNext: (data) {
            habitsData ??= {};
            habitsData!['social_media'] = data['social_media'];
            nextStep();
          },
        ),
        
        // 22. Habits Questions - Cold Shower
        OnboardingHabitsQuestions(
          questionType: 'cold_shower',
          onBack: prevStep,
          onNext: (data) {
            habitsData ??= {};
            habitsData!['cold_shower'] = data['cold_shower'];
            nextStep();
          },
        ),
        
        // 23. Analysis Screen
        OnboardingAnalysis(
          onNext: nextStep,
        ),
        
        // 24. Current Rating
        OnboardingRating(
          onBack: prevStep,
          onNext: nextStep, // Rating screen doesn't return data, just shows info
        ),
        
        // 25. Potential Rating
        OnboardingPotentialRating(
          onBack: prevStep,
          onNext: nextStep, // Potential rating screen doesn't return data
        ),
        
        // 26. Goal Setting
        OnboardingGoalSetting(
          onBack: prevStep,
          onNext: (data) {
            selectedGoal = data['goal'] as String?;
            nextStep();
          },
        ),
        
        // 27. Commitment Selection
        OnboardingCommitment(
          onBack: prevStep,
          onNext: (days) {
            commitmentLevel = days.toString();
            nextStep();
          },
        ),
        
        // 28. Hard Mode Selection
        OnboardingHardMode(
          onBack: prevStep,
          onNext: (enabled) {
            hardModeEnabled = enabled;
            nextStep();
          },
        ),
        
        // 29. Notifications
        OnboardingNotifications(
          onBack: prevStep,
          onNext: (settings) {
            notificationSettings = settings;
            nextStep();
          },
        ),
        
        // 30. Science Backed Plan
        OnboardingScienceBacked(
          onNext: nextStep,
        ),
        
        // 31. 66 Days Explanation
        Onboarding66DaysExplanation(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 32. Progressive Difficulty
        OnboardingProgressiveDifficulty(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 33. Core Habits
        OnboardingCoreHabits(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 34. Habit Detail (Run example)
        OnboardingHabitDetail(
          habitId: 'run',
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 35. RPG Game Explanation
        OnboardingRPGGame(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 36. Penalty System
        OnboardingPenaltySystem(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 37. Real Stories
        OnboardingRealStories(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 38. Before/After
        OnboardingBeforeAfter(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 39. Mission Awaken
        OnboardingMissionAwaken(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 40. Vow Questions
        OnboardingVowQuestions(
          question: 'Do you vow to reflect on your path, even when the truth is uncomfortable?',
          onBack: prevStep,
          onNext: (answer) {
            vowAnswers ??= {};
            vowAnswers!['reflection_vow'] = answer;
            nextStep();
          },
        ),
        
        // 41. Program Overview
        OnboardingProgramOverview(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 42. Program Preview
        OnboardingProgramPreview(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 43. Extra Tasks
        OnboardingExtraTasks(
          onBack: prevStep,
          onNext: (tasks) {
            extraTasks = tasks;
            nextStep();
          },
        ),
        
        // 44. Program Customization
        OnboardingProgramCustomization(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 45. Subscription Offer
        OnboardingSubscriptionOffer(
          onBack: prevStep,
          onNext: nextStep,
          onSkip: nextStep,
        ),
        
        // 46. Refer Code
        OnboardingReferCode(
          onBack: prevStep,
          onNext: (code) {
            referCode = code;
            nextStep();
          },
        ),
        
        // 47. Final Truths
        OnboardingFinalTruths(
          onNext: nextStep,
        ),
        
        // 48. Lock In
        OnboardingLockIn(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 49. Final Review
        OnboardingFinalReview(
          onBack: prevStep,
          onNext: nextStep,
        ),
        
        // 50. Final Welcome Screen - Complete onboarding
        _WelcomeScreen(
          onComplete: () async {
            await _markCompleted();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home_screen');
            }
          },
        ),
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

/// ✅ Final Welcome Screen
class _WelcomeScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const _WelcomeScreen({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (no back button on final screen)
              OnboardingHeader(
                showBack: false,
                onBack: null,
              ),

              const Spacer(),

              // Welcome Icon/Emoji
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Welcome Title
              Center(
                child: Text(
                  lang.t('welcome'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Welcome Message
              Center(
                child: Text(
                  lang.t('welcome_message'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade400,
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    lang.t('get_started'),
                    style: const TextStyle(
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
