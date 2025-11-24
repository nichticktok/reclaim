/// Input data for AI book summary generation
class BookSummaryInput {
  final String bookTitle;
  final String? author; // Optional: author name
  final String? bookText; // Optional: full text or excerpt from the book
  final String? summaryType; // Optional: quick, detailed, chapter_wise, key_insights
  final String? focusAreas; // Optional: what to focus on (e.g., "main ideas", "practical applications", "character analysis")
  final int? maxLength; // Optional: desired summary length in words

  BookSummaryInput({
    required this.bookTitle,
    this.author,
    this.bookText,
    this.summaryType,
    this.focusAreas,
    this.maxLength,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookTitle': bookTitle,
      'author': author,
      'bookText': bookText,
      'summaryType': summaryType,
      'focusAreas': focusAreas,
      'maxLength': maxLength,
    };
  }

  factory BookSummaryInput.fromMap(Map<String, dynamic> map) {
    return BookSummaryInput(
      bookTitle: map['bookTitle'] ?? '',
      author: map['author'],
      bookText: map['bookText'],
      summaryType: map['summaryType'],
      focusAreas: map['focusAreas'],
      maxLength: map['maxLength']?.toInt(),
    );
  }
}

