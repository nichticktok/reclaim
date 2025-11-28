import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import '../../../../app/env.dart';
import '../../../../core/models/project_model.dart';

/// AI service for validating reflection question answers
class AIAnswerValidationService {
  static String _getApiKey() {
    return AppEnv.geminiApiKey;
  }

  /// Validate answers against questions and task context
  /// Returns a map of question index to validation result
  Future<Map<int, AnswerValidationResult>> validateAnswers(
    ProjectTaskModel task,
    String category,
    List<String> questions,
    List<String> answers,
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

    final prompt = _buildValidationPrompt(task, category, questions, answers);
    final response = await _callGeminiAPI(prompt);
    return _parseValidationResults(response, questions.length);
  }

  String _buildValidationPrompt(
    ProjectTaskModel task,
    String category,
    List<String> questions,
    List<String> answers,
  ) {
    final questionsText = questions.asMap().entries.map((e) => 
      '${e.key + 1}. ${e.value}'
    ).join('\n');
    
    final answersText = answers.asMap().entries.map((e) => 
      '${e.key + 1}. ${e.value}'
    ).join('\n');

    return '''
You are an educational assistant validating answers to reflection questions.

Task: "${task.title}"
Description: "${task.description}"
Category: "$category"

Questions:
$questionsText

User Answers:
$answersText

For each question-answer pair, determine:
1. Does this question have a specific correct answer? (e.g., "What are the guitar string names?" = yes, "What did you learn?" = no)
2. If yes, is the user's answer correct?
3. If incorrect, what is the correct answer?

Respond with ONLY valid JSON (no markdown, no code blocks):
{
  "validations": [
    {
      "questionIndex": 0,
      "hasSpecificAnswer": true,
      "isCorrect": false,
      "correctAnswer": "E, A, D, G, B, E (from low to high)",
      "explanation": "The standard guitar tuning is E-A-D-G-B-E..."
    },
    {
      "questionIndex": 1,
      "hasSpecificAnswer": false,
      "isCorrect": true,
      "correctAnswer": null,
      "explanation": null
    }
  ]
}

If a question doesn't have a specific answer (like "What did you learn?"), set hasSpecificAnswer to false and isCorrect to true.
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

  Map<int, AnswerValidationResult> _parseValidationResults(
    String response,
    int questionCount,
  ) {
    try {
      // Extract JSON from response
      String jsonStr = response.trim();
      
      // Remove markdown code blocks if present
      if (jsonStr.startsWith('```')) {
        final lines = jsonStr.split('\n');
        jsonStr = lines.skip(1).take(lines.length - 2).join('\n');
      }
      
      jsonStr = jsonStr.trim();
      
      // Find JSON object
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
      }

      final Map<String, dynamic> json = jsonDecode(jsonStr);
      final List<dynamic> validations = json['validations'] as List<dynamic>? ?? [];
      
      final Map<int, AnswerValidationResult> results = {};
      
      for (var validation in validations) {
        final map = validation as Map<String, dynamic>;
        final index = map['questionIndex'] as int? ?? 0;
        final hasSpecificAnswer = map['hasSpecificAnswer'] as bool? ?? false;
        final isCorrect = map['isCorrect'] as bool? ?? true;
        final correctAnswer = map['correctAnswer'] as String?;
        final explanation = map['explanation'] as String?;
        
        results[index] = AnswerValidationResult(
          hasSpecificAnswer: hasSpecificAnswer,
          isCorrect: isCorrect,
          correctAnswer: correctAnswer,
          explanation: explanation,
        );
      }
      
      // Fill in missing indices with default (no specific answer)
      for (int i = 0; i < questionCount; i++) {
        if (!results.containsKey(i)) {
          results[i] = AnswerValidationResult(
            hasSpecificAnswer: false,
            isCorrect: true,
          );
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error parsing validation results: $e');
      debugPrint('Response: $response');
      // Return all correct if parsing fails
      final Map<int, AnswerValidationResult> results = {};
      for (int i = 0; i < questionCount; i++) {
        results[i] = AnswerValidationResult(
          hasSpecificAnswer: false,
          isCorrect: true,
        );
      }
      return results;
    }
  }
}

/// Result of answer validation
class AnswerValidationResult {
  final bool hasSpecificAnswer;
  final bool isCorrect;
  final String? correctAnswer;
  final String? explanation;

  AnswerValidationResult({
    required this.hasSpecificAnswer,
    required this.isCorrect,
    this.correctAnswer,
    this.explanation,
  });
}

