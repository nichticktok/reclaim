import 'package:flutter/foundation.dart';
import '../../data/models/curated_book_summary.dart';
import '../../data/services/curated_book_summaries_service.dart';

class BookSummaryController extends ChangeNotifier {
  List<CuratedBookSummary> _curatedSummaries = [];
  String? _selectedCategory;
  bool _loading = false;
  String? _error;

  List<CuratedBookSummary> get curatedSummaries => _curatedSummaries;
  String? get selectedCategory => _selectedCategory;
  bool get loading => _loading;
  String? get error => _error;

  List<String> get availableCategories => [
    'all',
    'self_improvement',
    'business',
    'psychology',
    'history',
    'spirituality',
  ];

  Future<void> initialize() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _curatedSummaries = CuratedBookSummariesService.getCuratedSummaries();
      _selectedCategory = 'all';
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading curated book summaries: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    if (category == 'all') {
      _curatedSummaries = CuratedBookSummariesService.getCuratedSummaries();
    } else {
      _curatedSummaries = CuratedBookSummariesService.getSummariesByCategory(category);
    }
    notifyListeners();
  }

  CuratedBookSummary? getSummaryById(String id) {
    return CuratedBookSummariesService.getSummaryById(id);
  }

  String getCategoryDisplayName(String category) {
    switch (category) {
      case 'all':
        return 'All Books';
      case 'self_improvement':
        return 'Self Improvement';
      case 'business':
        return 'Business';
      case 'psychology':
        return 'Psychology';
      case 'history':
        return 'History';
      case 'spirituality':
        return 'Spirituality';
      default:
        return category.replaceAll('_', ' ').toUpperCase();
    }
  }
}

