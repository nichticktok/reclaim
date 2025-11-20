import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/penalty_repository.dart';
import '../../data/repositories/firestore_penalty_repository.dart';

/// Penalty Controller
/// Handles: Penalty quest generation, completion tracking, reset logic
class PenaltyController extends ChangeNotifier {
  final PenaltyRepository _repository = FirestorePenaltyRepository();
  bool _loading = false;
  bool _hasPenalty = false;
  Map<String, dynamic>? _penaltyQuest;
  String? _error;

  bool get loading => _loading;
  bool get hasPenalty => _hasPenalty;
  Map<String, dynamic>? get penaltyQuest => _penaltyQuest;
  String? get error => _error;

  /// Initialize and check for active penalties
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _hasPenalty = await _repository.hasActivePenalty(user.uid);
      if (_hasPenalty) {
        _penaltyQuest = await _repository.getPenaltyQuest(user.uid);
      }
      debugPrint('✅ Penalty status: ${_hasPenalty ? "Active" : "None"}');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error checking penalty: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Generate penalty quest when day is missed
  Future<void> generatePenaltyQuest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      await _repository.generatePenaltyQuest(user.uid);
      _hasPenalty = true;
      _penaltyQuest = await _repository.getPenaltyQuest(user.uid);
      debugPrint('✅ Penalty quest generated');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error generating penalty quest: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Complete penalty quest
  Future<void> completePenaltyQuest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    if (_penaltyQuest == null) {
      _error = 'No active penalty quest';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      final questId = _penaltyQuest!['id'] as String? ?? '';
      await _repository.completePenaltyQuest(user.uid, questId);
      _hasPenalty = false;
      _penaltyQuest = null;
      debugPrint('✅ Penalty quest completed');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error completing penalty quest: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Reset to day 1 (if penalty quest failed)
  Future<void> resetToDayOne() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      await _repository.resetToDayOne(user.uid);
      _hasPenalty = false;
      _penaltyQuest = null;
      debugPrint('✅ Reset to day 1');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error resetting to day 1: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

