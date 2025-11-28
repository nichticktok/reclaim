import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_gemini/flutter_gemini.dart';
import '../../../../app/env.dart';
import '../../../../core/models/project_model.dart';
import '../../domain/entities/multiple_choice_question.dart';

/// AI service for generating reflection questions for project tasks
class AIReflectionService {
  static String _getApiKey() {
    return AppEnv.geminiApiKey;
  }

  /// Generate multiple choice reflection questions for a project task using AI
  Future<List<MultipleChoiceQuestion>> generateReflectionQuestions(
    ProjectTaskModel task,
    String category,
  ) async {
    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured');
    }

    // Gemini should be initialized in main.dart, but verify
    try {
      Gemini.instance;
    } catch (e) {
      Gemini.init(apiKey: apiKey, enableDebugging: false);
    }

    final prompt = _buildPrompt(task, category);
    final response = await _callGeminiAPI(prompt);
    return _parseQuestions(response);
  }

  String _buildPrompt(ProjectTaskModel task, String category) {
    return '''
Generate 1-2 multiple choice reflection questions for this project task:

Task: "${task.title}"
Description: "${task.description}"
Category: "$category"

For each question:
1. If the question can be answered with True/False, create a TRUE/FALSE question with 2 options: "True" and "False"
2. Otherwise, create a multiple choice question with 4 options:
   - 1 correct answer
   - 2 wrong/plausible but incorrect answers
   - 1 "I don't know" option

The questions should:
- Be specific to this task type
- Test understanding of key concepts from the task
- Be concise and clear
- Have one clearly correct answer

Examples:
- True/False: "The standard guitar tuning is E-A-D-G-B-E" → ["True", "False"]
- Multiple Choice: "What are the guitar string names?" → ["E, A, D, G, B, E", "A, B, C, D, E, F", "G, C, F, A, D, G", "I don't know"]

Respond with ONLY valid JSON (no markdown, no code blocks):
{
  "questions": [
    {
      "question": "Question text here",
      "questionType": "true_false" or "multiple_choice",
      "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
      "correctOptionIndex": 0
    }
  ]
}

For true/false questions, options should be ["True", "False"] and correctOptionIndex should be 0 for True or 1 for False.
For multiple choice, provide 4 options with correctOptionIndex 0-3.
''';
  }

  Future<String> _callGeminiAPI(String prompt) async {
    try {
      final response = await Gemini.instance.prompt(
        parts: [Part.text(prompt)],
      );
      return response?.output ?? '';
    } catch (e) {
      debugPrint('Error calling Gemini API: $e');
      rethrow;
    }
  }

  List<MultipleChoiceQuestion> _parseQuestions(String response) {
    try {
      // Extract JSON from response (handle markdown code blocks if present)
      String jsonStr = response.trim();
      
      // Remove markdown code blocks if present
      if (jsonStr.startsWith('```')) {
        final lines = jsonStr.split('\n');
        jsonStr = lines.skip(1).take(lines.length - 2).join('\n');
      }
      
      // Remove any leading/trailing whitespace or newlines
      jsonStr = jsonStr.trim();
      
      // Find JSON object
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
      }

      final Map<String, dynamic> json = jsonDecode(jsonStr);
      final List<dynamic> questionsJson = json['questions'] as List<dynamic>? ?? [];
      
      return questionsJson
          .map((q) {
            final map = q as Map<String, dynamic>;
            return MultipleChoiceQuestion(
              question: map['question'] as String,
              options: List<String>.from(map['options'] as List),
              correctOptionIndex: map['correctOptionIndex'] as int,
              questionType: map['questionType'] as String?,
            );
          })
          .take(2) // Limit to 2 questions
          .toList();
    } catch (e) {
      debugPrint('Error parsing reflection questions: $e');
      debugPrint('Response: $response');
      // Return default questions
      return [
        MultipleChoiceQuestion(
          question: 'What did you accomplish in this session?',
          options: ['Completed the task', 'Partially completed', 'Just started', 'I don\'t know'],
          correctOptionIndex: 0,
          questionType: 'multiple_choice',
        ),
      ];
    }
  }
}

