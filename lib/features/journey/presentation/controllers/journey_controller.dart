import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/journey_repository.dart';
import '../../data/repositories/firestore_journey_repository.dart';

/// Journey Controller
/// Handles: Mood tracking, daily journal entries, task completion tracking
class JourneyController extends ChangeNotifier {
  final JourneyRepository _repository = FirestoreJourneyRepository();
  bool _loading = false;
  int _currentDay = 1;
  String? _currentMood;
  String? _journalEntry;
  String? _error;
  bool _initialized = false; // Track if already initialized

  bool get loading => _loading;
  int get currentDay => _currentDay;
  String? get currentMood => _currentMood;
  String? get journalEntry => _journalEntry;
  String? get error => _error;

  /// Initialize and load current day data (only if not already initialized)
  Future<void> initialize({bool forceRefresh = false}) async {
    // Skip if already initialized unless force refresh
    if (_initialized && !forceRefresh) {
      debugPrint('🗺️ JourneyController already initialized, skipping...');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      _currentDay = await _repository.getCurrentDay(user.uid);
      
      // Load existing day entry
      final dayEntry = await _repository.getDayEntry(user.uid, _currentDay);
      if (dayEntry != null) {
        _currentMood = dayEntry['mood'] as String?;
        _journalEntry = dayEntry['journalEntry'] as String?;
      }
      
      _initialized = true;
      debugPrint('✅ Journey initialized: Day $_currentDay');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error initializing journey: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save mood selection
  Future<void> saveMood(String mood) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      await _repository.saveMood(user.uid, _currentDay, mood);
      _currentMood = mood;
      debugPrint('✅ Mood saved: $mood');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error saving mood: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Save journal entry
  Future<void> saveJournalEntry(String entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      await _repository.saveJournalEntry(user.uid, _currentDay, entry);
      _journalEntry = entry;
      debugPrint('✅ Journal entry saved');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error saving journal entry: $e');
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

