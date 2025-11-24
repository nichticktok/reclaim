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

  Map<int, Map<String, dynamic>> _dayEntries = {};
  DateTime? _journeyStartDate;
  int _totalDays = 30;

  Map<int, Map<String, dynamic>> get dayEntries => _dayEntries;
  DateTime? get journeyStartDate => _journeyStartDate;
  int get totalDays => _totalDays;

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
      _journeyStartDate = await _repository.getJourneyStartDate(user.uid);
      
      // Load existing day entry for current day
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

  /// Load all day entries for timeline view
  Future<void> loadAllDayEntries({int totalDays = 30}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _totalDays = totalDays;
    _error = null;
    try {
      final dayNumbers = List.generate(totalDays, (index) => index + 1);
      _dayEntries = await _repository.getDayEntries(user.uid, dayNumbers);
      debugPrint('✅ Loaded ${_dayEntries.length} day entries');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading day entries: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Get date for a specific day number
  DateTime? getDateForDay(int dayNumber) {
    if (_journeyStartDate == null) return null;
    return _journeyStartDate!.add(Duration(days: dayNumber - 1));
  }

  /// Load entry for a specific day
  Future<void> loadDayEntry(int dayNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final entry = await _repository.getDayEntry(user.uid, dayNumber);
      if (entry != null) {
        _dayEntries[dayNumber] = entry;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading day entry: $e');
    }
  }

  int _viewingDay = 1;

  /// Load data for a specific day
  Future<void> loadDayData(int dayNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    _setLoading(true);
    _error = null;
    _viewingDay = dayNumber;
    
    try {
      final dayEntry = await _repository.getDayEntry(user.uid, dayNumber);
      if (dayEntry != null) {
        _currentMood = dayEntry['mood'] as String?;
        _journalEntry = dayEntry['journalEntry'] as String?;
      } else {
        _currentMood = null;
        _journalEntry = null;
      }
      debugPrint('✅ Loaded day $dayNumber data');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading day data: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Save mood selection
  Future<void> saveMood(String mood, {int? dayNumber}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    final targetDay = dayNumber ?? _viewingDay;
    _setLoading(true);
    _error = null;
    try {
      await _repository.saveMood(user.uid, targetDay, mood);
      
      // Update local state
      if (targetDay == _currentDay || targetDay == _viewingDay) {
      _currentMood = mood;
      }
      
      // Update entries map
      _dayEntries[targetDay] = {
        ...(_dayEntries[targetDay] ?? {}),
        'mood': mood,
      };
      
      debugPrint('✅ Mood saved: $mood for day $targetDay');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error saving mood: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Save journal entry
  Future<void> saveJournalEntry(String entry, {int? dayNumber}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      return;
    }

    final targetDay = dayNumber ?? _viewingDay;
    _setLoading(true);
    _error = null;
    try {
      await _repository.saveJournalEntry(user.uid, targetDay, entry);
      
      // Update local state
      if (targetDay == _currentDay || targetDay == _viewingDay) {
      _journalEntry = entry;
      }
      
      // Update entries map
      _dayEntries[targetDay] = {
        ...(_dayEntries[targetDay] ?? {}),
        'journalEntry': entry,
      };
      
      debugPrint('✅ Journal entry saved for day $targetDay');
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

