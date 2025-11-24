import '../entities/book_summary_input.dart';
import '../entities/book_summary.dart';

/// Abstract repository for AI book summary operations
abstract class AIBookSummaryRepository {
  /// Generate a book summary based on user input
  Future<BookSummary> generateBookSummary(BookSummaryInput input, String userId);
}

