import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/milestone_model.dart';
import '../../data/repositories/firestore_milestone_repository.dart';

class MilestoneController extends ChangeNotifier {
  final FirestoreMilestoneRepository _repository = FirestoreMilestoneRepository();
  
  MilestoneModel? _currentMilestone;
  bool _loading = false;

  MilestoneModel? get currentMilestone => _currentMilestone;
  bool get loading => _loading;

  /// Initialize and load current milestone
  Future<void> initialize() async {
    if (_loading) return;
    
    _loading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentMilestone = await _repository.getCurrentMilestone(user.uid);
      }
    } catch (e) {
      debugPrint('Error loading milestone: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Get current day (1-based) based on milestone
  int getCurrentDay() {
    if (_currentMilestone == null) return 1;
    return _currentMilestone!.getCurrentDay();
  }

  /// Get total days in milestone
  int getTotalDays() {
    if (_currentMilestone == null) return 30; // Default fallback
    return _currentMilestone!.totalDays;
  }

  /// Get progress percentage (0.0 to 1.0)
  double getProgressPercentage() {
    if (_currentMilestone == null) return 0.0;
    return _currentMilestone!.getProgressPercentage();
  }

  /// Get milestone name
  String getMilestoneName() {
    if (_currentMilestone == null) return 'Your Journey';
    return _currentMilestone!.name;
  }
}

