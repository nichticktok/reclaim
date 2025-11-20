import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/mastery_repository.dart';
import '../../data/repositories/firestore_mastery_repository.dart';

/// Mastery Controller
/// Handles: Rank progression (Bronze V to Legend I), XP tracking, achievements
class MasteryController extends ChangeNotifier {
  final MasteryRepository _repository = FirestoreMasteryRepository();
  bool _loading = false;
  String _currentRank = 'Bronze V';
  int _currentXP = 0;
  int _requiredXP = 1000;
  int _level = 1;
  int _totalXP = 0;
  List<Map<String, dynamic>> _achievements = [];
  String? _error;

  bool get loading => _loading;
  String get currentRank => _currentRank;
  int get currentXP => _currentXP;
  int get requiredXP => _requiredXP;
  int get level => _level;
  int get totalXP => _totalXP;
  List<Map<String, dynamic>> get achievements => _achievements;
  String? get error => _error;
  double get progress => _requiredXP > 0 ? (_currentXP / _requiredXP).clamp(0.0, 1.0) : 0.0;

  /// Initialize and load mastery data
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      final data = await _repository.getMasteryData(user.uid);
      _currentRank = (data['rank'] ?? 'Bronze V') as String;
      _currentXP = (data['xp'] ?? 0) as int;
      _level = (data['level'] ?? 1) as int;
      _totalXP = (data['totalXP'] ?? 0) as int;
      _requiredXP = _calculateRequiredXP(_currentRank);

      _achievements = await _repository.getAchievements(user.uid);
      debugPrint('✅ Mastery loaded: Rank $_currentRank, XP $_currentXP/$_requiredXP');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading mastery: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add XP and check for rank up
  Future<void> addXP(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      final oldRank = _currentRank;
      await _repository.addXP(user.uid, amount);
      
      // Reload mastery data to get updated rank
      final data = await _repository.getMasteryData(user.uid);
      _currentRank = (data['rank'] ?? 'Bronze V') as String;
      _currentXP = (data['xp'] ?? 0) as int;
      _level = (data['level'] ?? 1) as int;
      _totalXP = (data['totalXP'] ?? 0) as int;
      _requiredXP = _calculateRequiredXP(_currentRank);

      if (_currentRank != oldRank) {
        debugPrint('🎉 Rank up! From $oldRank to $_currentRank');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error adding XP: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  int _calculateRequiredXP(String rank) {
    final ranks = [
      'Bronze V', 'Bronze IV', 'Bronze III', 'Bronze II', 'Bronze I',
      'Silver V', 'Silver IV', 'Silver III', 'Silver II', 'Silver I',
      'Gold V', 'Gold IV', 'Gold III', 'Gold II', 'Gold I',
      'Platinum V', 'Platinum IV', 'Platinum III', 'Platinum II', 'Platinum I',
      'Diamond V', 'Diamond IV', 'Diamond III', 'Diamond II', 'Diamond I',
      'Legend V', 'Legend IV', 'Legend III', 'Legend II', 'Legend I',
    ];
    final index = ranks.indexOf(rank);
    return 1000 + (index * 500);
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

