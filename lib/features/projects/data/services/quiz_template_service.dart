import '../../../../core/models/project_model.dart';
import '../../domain/entities/multiple_choice_question.dart';

/// Template-based quiz service for project tasks
class QuizTemplateService {
  /// Get quiz questions based on task category and type
  /// Returns MultipleChoiceQuestion objects - template questions don't have correct answers (all acceptable)
  List<MultipleChoiceQuestion> getQuizQuestions(ProjectTaskModel task, String category) {
    // Determine task type from title/description
    final taskLower = '${task.title} ${task.description}'.toLowerCase();

    // Learning/Study tasks
    if (_isLearningTask(taskLower, category)) {
      return [
        MultipleChoiceQuestion(
          question: 'What is the main idea or concept you learned?',
          options: ['Understood the key concepts', 'Partially understood', 'Need more practice', 'I don\'t know'],
          correctOptionIndex: 0, // First option is considered "correct" for template questions
          questionType: 'multiple_choice',
        ),
        MultipleChoiceQuestion(
          question: 'Explain one key concept in your own words',
          options: ['I can explain clearly', 'I understand but hard to explain', 'Still learning', 'I don\'t know'],
          correctOptionIndex: 0,
          questionType: 'multiple_choice',
        ),
      ];
    }

    // Practice tasks
    if (_isPracticeTask(taskLower, category)) {
      return [
        MultipleChoiceQuestion(
          question: 'What did you practice today?',
          options: ['Completed practice session', 'Practiced partially', 'Just started', 'I don\'t know'],
          correctOptionIndex: 0,
          questionType: 'multiple_choice',
        ),
        MultipleChoiceQuestion(
          question: 'What was the most challenging part?',
          options: ['Identified challenges clearly', 'Some difficulty', 'No major challenges', 'I don\'t know'],
          correctOptionIndex: 0,
          questionType: 'multiple_choice',
        ),
      ];
    }

    // Coding/Development tasks
    if (_isCodingTask(taskLower, category)) {
      return [
        MultipleChoiceQuestion(
          question: 'What feature or functionality did you work on?',
          options: ['Completed the feature', 'Made good progress', 'Just started', 'I don\'t know'],
          correctOptionIndex: 0,
          questionType: 'multiple_choice',
        ),
        MultipleChoiceQuestion(
          question: 'What technical challenge did you face?',
          options: ['Resolved challenges', 'Facing some issues', 'No major challenges', 'I don\'t know'],
          correctOptionIndex: 0,
          questionType: 'multiple_choice',
        ),
      ];
    }

    // Research tasks
    if (_isResearchTask(taskLower, category)) {
      return [
        MultipleChoiceQuestion(
          question: 'What did you discover or learn from your research?',
          options: ['Found useful information', 'Found some information', 'Still researching', 'I don\'t know'],
          correctOptionIndex: 0,
          questionType: 'multiple_choice',
        ),
        MultipleChoiceQuestion(
          question: 'What question remains unanswered?',
          options: ['Have clear next steps', 'Some questions remain', 'All questions answered', 'I don\'t know'],
          correctOptionIndex: 0,
          questionType: 'multiple_choice',
        ),
      ];
    }

    // Creative tasks
    if (_isCreativeTask(taskLower, category)) {
      return [
        MultipleChoiceQuestion(
          question: 'What did you create or design?',
          options: ['Completed the creation', 'Made good progress', 'Just started', 'I don\'t know'],
          correctOptionIndex: 0,
          questionType: 'multiple_choice',
        ),
        MultipleChoiceQuestion(
          question: 'What inspired your approach?',
          options: ['Clear inspiration', 'Some ideas', 'Still exploring', 'I don\'t know'],
          correctOptionIndex: 0,
          questionType: 'multiple_choice',
        ),
      ];
    }

    // Default questions
    return [
      MultipleChoiceQuestion(
        question: 'What did you accomplish in this task?',
        options: ['Completed the task', 'Made progress', 'Just started', 'I don\'t know'],
        correctOptionIndex: 0,
        questionType: 'multiple_choice',
      ),
      MultipleChoiceQuestion(
        question: 'What was challenging or what do you want to improve?',
        options: ['Identified areas to improve', 'Some challenges', 'No major issues', 'I don\'t know'],
        correctOptionIndex: 0,
        questionType: 'multiple_choice',
      ),
    ];
  }

  bool _isLearningTask(String taskText, String category) {
    final learningKeywords = [
      'learn',
      'study',
      'read',
      'understand',
      'course',
      'tutorial',
      'certificate',
      'exam',
      'chapter',
    ];
    return learningKeywords.any((keyword) => taskText.contains(keyword)) ||
        category == 'learning';
  }

  bool _isPracticeTask(String taskText, String category) {
    final practiceKeywords = [
      'practice',
      'rehearse',
      'drill',
      'exercise',
      'piano',
      'guitar',
      'speaking',
      'language',
    ];
    return practiceKeywords.any((keyword) => taskText.contains(keyword)) ||
        category == 'fitness';
  }

  bool _isCodingTask(String taskText, String category) {
    final codingKeywords = [
      'code',
      'program',
      'develop',
      'implement',
      'debug',
      'function',
      'feature',
      'api',
      'github',
      'commit',
    ];
    return codingKeywords.any((keyword) => taskText.contains(keyword)) ||
        category == 'coding' ||
        category == 'development';
  }

  bool _isResearchTask(String taskText, String category) {
    final researchKeywords = [
      'research',
      'investigate',
      'analyze',
      'explore',
      'find',
      'discover',
      'study',
    ];
    return researchKeywords.any((keyword) => taskText.contains(keyword)) ||
        category == 'research';
  }

  bool _isCreativeTask(String taskText, String category) {
    final creativeKeywords = [
      'design',
      'create',
      'draw',
      'sketch',
      'write',
      'compose',
      'art',
      'plan',
    ];
    return creativeKeywords.any((keyword) => taskText.contains(keyword)) ||
        category == 'creative';
  }
}

