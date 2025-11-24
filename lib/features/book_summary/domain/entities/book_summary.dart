/// AI-generated book summary structure
class BookSummary {
  final String id;
  final String userId;
  final String bookTitle;
  final String? author;
  final String summary; // Main summary text
  final List<String>? keyPoints; // Optional: bullet points of key insights
  final List<String>? chapters; // Optional: chapter summaries if chapter_wise
  final List<String>? actionableInsights; // Optional: practical takeaways
  final String? summaryType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BookSummary({
    required this.id,
    required this.userId,
    required this.bookTitle,
    this.author,
    required this.summary,
    this.keyPoints,
    this.chapters,
    this.actionableInsights,
    this.summaryType,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookTitle': bookTitle,
      'author': author,
      'summary': summary,
      'keyPoints': keyPoints,
      'chapters': chapters,
      'actionableInsights': actionableInsights,
      'summaryType': summaryType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory BookSummary.fromMap(Map<String, dynamic> map, String id) {
    return BookSummary(
      id: id,
      userId: map['userId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      author: map['author'],
      summary: map['summary'] ?? '',
      keyPoints: map['keyPoints'] != null 
          ? List<String>.from(map['keyPoints']) 
          : null,
      chapters: map['chapters'] != null 
          ? List<String>.from(map['chapters']) 
          : null,
      actionableInsights: map['actionableInsights'] != null 
          ? List<String>.from(map['actionableInsights']) 
          : null,
      summaryType: map['summaryType'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
    );
  }
}

