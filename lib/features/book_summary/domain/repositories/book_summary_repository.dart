import '../entities/book_summary.dart';

/// Abstract repository for book summary data operations
abstract class BookSummaryRepository {
  Future<String> saveBookSummary(BookSummary summary);
  Future<List<BookSummary>> getUserBookSummaries(String userId);
  Future<BookSummary?> getBookSummaryById(String summaryId);
  Future<void> updateBookSummary(BookSummary summary);
  Future<void> deleteBookSummary(String summaryId);
}

