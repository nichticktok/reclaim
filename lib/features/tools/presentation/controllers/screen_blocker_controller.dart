import 'dart:async';
import 'package:flutter/foundation.dart';

/// Controller for managing screen blocker state
/// Handles blocking duration, timer, and blocking status
class ScreenBlockerController extends ChangeNotifier {
  bool _isBlocked = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  DateTime? _blockEndTime;
  int _selectedDurationMinutes = 15;
  int _backgroundCount = 0; // Track how many times app went to background

  bool get isBlocked => _isBlocked;
  int get remainingSeconds => _remainingSeconds;
  DateTime? get blockEndTime => _blockEndTime;
  int get selectedDurationMinutes => _selectedDurationMinutes;
  int get backgroundCount => _backgroundCount;

  /// Get formatted remaining time string (MM:SS)
  String get remainingTimeString {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Set the duration for blocking (in minutes)
  void setDuration(int minutes) {
    if (minutes < 1 || minutes > 480) return; // Max 8 hours
    _selectedDurationMinutes = minutes;
    notifyListeners();
  }

  /// Start blocking the screen
  void startBlocking() {
    if (_isBlocked) return;

    _isBlocked = true;
    _remainingSeconds = _selectedDurationMinutes * 60;
    _blockEndTime = DateTime.now().add(Duration(minutes: _selectedDurationMinutes));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stopBlocking();
      }
    });

    notifyListeners();
  }

  /// Stop blocking the screen (can be called manually or when timer expires)
  void stopBlocking() {
    if (!_isBlocked) return;

    _isBlocked = false;
    _remainingSeconds = 0;
    _blockEndTime = null;
    _backgroundCount = 0; // Reset background count
    _timer?.cancel();
    _timer = null;

    notifyListeners();
  }

  /// Called when app goes to background during blocking
  void onAppBackgrounded() {
    if (_isBlocked) {
      _backgroundCount++;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

