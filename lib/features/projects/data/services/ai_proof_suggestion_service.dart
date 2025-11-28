import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_gemini/flutter_gemini.dart';
import '../../../../app/env.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/constants/project_proof_types.dart';
import '../../domain/entities/proof_suggestion.dart';

/// AI service for suggesting appropriate proof types for project tasks
class AIProofSuggestionService {
  static String _getApiKey() {
    return AppEnv.geminiApiKey;
  }

  /// Suggest proof type for a project task using AI
  Future<ProofSuggestion> suggestProofForTask(ProjectTaskModel task, String category) async {
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
    return _parseProofSuggestion(response);
  }

  String _buildPrompt(ProjectTaskModel task, String category) {
    return '''
Analyze this project task and suggest the best proof type:

Task: "${task.title}"
Description: "${task.description}"
Category: "$category"
Estimated Hours: ${task.estimatedHours}

Available proof types:
- timedSession: Track work time with a timer (best for: studying, practicing, coding, reading)
- reflectionNote: Answer reflection questions (best for: learning, studying, practice)
- smallMediaClip: Record short audio/video (10-20 seconds) (best for: piano, speaking, drawing, fitness)
- externalOutput: Share link or screenshot (best for: coding, writing, design, documentation)

Consider:
1. What would be the most verifiable proof for this task?
2. What would be easiest for the user to provide?
3. What proof types are most appropriate for this task type?

Respond with ONLY valid JSON (no markdown, no code blocks):
{
  "primaryProofType": "timedSession",
  "alternativeProofTypes": ["reflectionNote"],
  "proofMechanism": "study_session",
  "reasoning": "This is a learning task, time tracking + reflection is most appropriate"
}

Proof mechanism options: study_session, work_session, practice_session, research_session, coding_session, creative_session
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

  ProofSuggestion _parseProofSuggestion(String response) {
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
      
      // Validate proof types
      final primaryType = json['primaryProofType'] as String? ?? ProjectProofTypes.timedSession;
      final altTypes = (json['alternativeProofTypes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .where((type) => ProjectProofTypes.isValid(type))
          .toList() ?? [];
      
      // Ensure primary type is valid
      final validPrimaryType = ProjectProofTypes.isValid(primaryType)
          ? primaryType
          : ProjectProofTypes.timedSession;

      return ProofSuggestion(
        primaryProofType: validPrimaryType,
        alternativeProofTypes: altTypes.take(2).toList(), // Limit to 2 alternatives
        proofMechanism: json['proofMechanism'] as String? ?? 'work_session',
        reasoning: json['reasoning'] as String? ?? 'AI suggested proof type',
      );
    } catch (e) {
      debugPrint('Error parsing proof suggestion: $e');
      debugPrint('Response: $response');
      // Return default suggestion
      return ProofSuggestion(
        primaryProofType: ProjectProofTypes.timedSession,
        alternativeProofTypes: [ProjectProofTypes.reflectionNote],
        proofMechanism: 'work_session',
        reasoning: 'Default suggestion (AI parsing failed)',
      );
    }
  }
}

