/// Model for a multiple choice question with options
class MultipleChoiceQuestion {
  final String question;
  final List<String> options; // 4 options: 1 correct, 2 wrong, 1 "I don't know"
  final int correctOptionIndex; // Index of the correct answer (0-3)
  final String? questionType; // "true_false" or "multiple_choice"

  MultipleChoiceQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.questionType,
  });

  /// Check if this is a true/false question
  bool get isTrueFalse => questionType == 'true_false';

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'questionType': questionType,
    };
  }

  factory MultipleChoiceQuestion.fromMap(Map<String, dynamic> map) {
    return MultipleChoiceQuestion(
      question: map['question'] as String,
      options: List<String>.from(map['options'] as List),
      correctOptionIndex: map['correctOptionIndex'] as int,
      questionType: map['questionType'] as String?,
    );
  }
}

