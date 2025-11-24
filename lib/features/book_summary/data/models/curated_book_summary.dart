/// Curated book summary model for pre-populated summaries
class CuratedBookSummary {
  final String id;
  final String bookTitle;
  final String author;
  final String summary;
  final List<String> keyPoints;
  final List<String> actionableInsights;
  final String category; // e.g., "self_improvement", "business", "psychology"
  final String coverImageUrl; // Optional: URL for book cover
  final int year; // Publication year

  CuratedBookSummary({
    required this.id,
    required this.bookTitle,
    required this.author,
    required this.summary,
    required this.keyPoints,
    required this.actionableInsights,
    required this.category,
    this.coverImageUrl = '',
    required this.year,
  });
}

