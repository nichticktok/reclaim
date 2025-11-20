import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingController extends ChangeNotifier {
  
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

  int get currentStep => _currentStep;
  bool get loading => _loading;

  /// Initialize and load progress
  Future<void> initialize({int? startStep}) async {
    _currentStep = startStep ?? 0;
    await _loadProgress();
  }

  /// Load user onboarding step from Firestore
  Future<void> _loadProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (doc.exists) {
      final data = doc.data() ?? {};
      _currentStep = data['onboardingStep'] ?? _currentStep;
    }
    
    _loading = false;
    notifyListeners();
  }

  /// Save progress to Firestore
  Future<void> saveProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'onboardingStep': _currentStep,
      'onboardingCompleted': false,
    }, SetOptions(merge: true));
  }

  /// Mark onboarding completed
  Future<void> markCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'onboardingCompleted': true,
      'onboardingStep': _currentStep,
    }, SetOptions(merge: true));
  }

  /// Move forward
  Future<void> nextStep(int totalSteps) async {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      await saveProgress();
      notifyListeners();
    } else {
      await markCompleted();
    }
  }

  /// Move backward
  Future<void> prevStep() async {
    if (_currentStep > 0) {
      _currentStep--;
      await saveProgress();
      notifyListeners();
    }
  }

  /// Update onboarding data
  void updateData(String key, dynamic value) {
    switch (key) {
      case 'name':
        name = value;
        break;
      case 'ageGroup':
        ageGroup = value;
        break;
      case 'gender':
        gender = value;
        break;
      case 'lifeDescription':
        lifeDescription = value;
        break;
      case 'character':
        character = value;
        break;
      case 'confirmedAge':
        confirmedAge = value;
        break;
      case 'mainCharacterFeeling':
        mainCharacterFeeling = value;
        break;
      case 'motivation':
        motivation = value;
        break;
      case 'darkHabits':
        darkHabits = value;
        break;
    }
  }
}

