import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_gemini/flutter_gemini.dart';
import '../../../../app/env.dart';
import '../../domain/entities/book_summary_input.dart';
import '../../domain/repositories/ai_book_summary_repository.dart';
import '../../domain/entities/book_summary.dart';

/// AI Book Summary Service
/// Uses Flutter Gemini SDK to generate book summaries based on user input
class AIBookSummaryService implements AIBookSummaryRepository {
  static String getApiKey() {
    return AppEnv.geminiApiKey;
  }

  static String _getApiKey() {
    return getApiKey();
  }

  @override
  Future<BookSummary> generateBookSummary(BookSummaryInput input, String userId) async {
    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini API key is not configured.\n\n'
        'Please set it using environment variables:\n'
        'Run with: flutter run --dart-define=GEMINI_API_KEY=your_key_here\n\n'
        'Get your API key from: https://makersuite.google.com/app/apikey\n\n'
        'Make sure Gemini.init() is called in main.dart!'
      );
    }

    try {
      Gemini.instance;
    } catch (e) {
      Gemini.init(apiKey: apiKey, enableDebugging: false);
    }

    final prompt = _buildPrompt(input);
    final response = await _callGeminiAPI(prompt);
    return _parseBookSummary(response, input, userId);
  }

  String _buildPrompt(BookSummaryInput input) {
    final summaryType = input.summaryType ?? 'detailed';
    final maxLength = input.maxLength ?? 500;
    
    return '''
You are an expert book analyst and summary writer. Create a comprehensive book summary based on the following information:

BOOK INFORMATION:
- Title: ${input.bookTitle}
${input.author != null ? '- Author: ${input.author}' : ''}
${input.bookText != null && input.bookText!.isNotEmpty 
    ? '- Book Text/Excerpt Provided: Yes (${input.bookText!.length} characters)' 
    : '- Book Text/Excerpt Provided: No (generate summary based on known information about the book)'}
${input.focusAreas != null ? '- Focus Areas: ${input.focusAreas}' : ''}

SUMMARY REQUIREMENTS:
- Summary Type: $summaryType
- Target Length: Approximately $maxLength words
${input.focusAreas != null ? '- Focus on: ${input.focusAreas}' : ''}

YOUR TASK:
Create a comprehensive book summary that includes:

1. MAIN SUMMARY: A well-structured summary of the book
   - If book text is provided, summarize that content
   - If no text is provided, create a summary based on the book's known themes, concepts, and key ideas
   - Length should be around $maxLength words
   - Write in clear, engaging prose
   - Cover main themes, concepts, and ideas

2. KEY POINTS: Extract 5-10 key insights or takeaways
   - Each point should be concise (1-2 sentences)
   - Focus on the most important concepts
   - Make them actionable when possible

3. ACTIONABLE INSIGHTS: Provide practical takeaways
   - What can readers apply from this book?
   - Real-world applications
   - Action steps or principles to follow

${input.summaryType == 'chapter_wise' ? '''
4. CHAPTER SUMMARIES: If chapter-wise summary is requested
   - Provide a brief summary for each major chapter or section
   - Keep each chapter summary to 2-3 sentences
''' : ''}

IMPORTANT GUIDELINES:
- Be accurate and faithful to the book's content
- If book text is provided, base the summary primarily on that text
- If no text is provided, use your knowledge of the book but note that it's a general summary
- Make it engaging and easy to understand
- Focus on practical value and insights
${input.focusAreas != null ? '- Emphasize: ${input.focusAreas}' : ''}
- Write in a clear, professional tone
- Avoid spoilers if it's a narrative work (unless specifically requested)

Return your response as JSON with the following structure:
{
  "summary": "Main summary text here (approximately $maxLength words)",
  "keyPoints": [
    "Key point 1",
    "Key point 2",
    "Key point 3",
    ...
  ],
  "actionableInsights": [
    "Actionable insight 1",
    "Actionable insight 2",
    ...
  ],
  ${input.summaryType == 'chapter_wise' ? '''
  "chapters": [
    "Chapter 1: Summary...",
    "Chapter 2: Summary...",
    ...
  ],
  ''' : ''}
  "summaryType": "$summaryType"
}
''';
  }

  Future<String> _callGeminiAPI(String prompt) async {
    try {
      debugPrint('🤖 Calling Gemini API for book summary generation...');
      
      final response = await Gemini.instance.prompt(
        parts: [Part.text(prompt)],
      );

      if (response?.output == null || response!.output!.isEmpty) {
        throw Exception('Gemini API returned empty response');
      }

      debugPrint('✅ Received response from Gemini API (${response.output!.length} characters)');
      return response.output!;
    } catch (e) {
      debugPrint('❌ Gemini API error: $e');
      
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('401') || errorStr.contains('unauthorized') || errorStr.contains('unauthenticated')) {
        throw Exception(
          'Gemini API authentication failed.\n\n'
          'Please check:\n'
          '1. Your API key is correct\n'
          '2. The API key is set in ai_book_summary_service.dart\n'
          '3. Gemini.init() is called in main.dart\n\n'
          'Get your API key from: https://makersuite.google.com/app/apikey\n\n'
          'Original error: $e'
        );
      }
      
      if (errorStr.contains('quota') || errorStr.contains('429')) {
        throw Exception(
          'API quota exceeded. Please check your usage limits.\n\n'
          '1. Check your quota in Google Cloud Console\n'
          '2. Wait a bit and try again\n'
          '3. Consider upgrading your plan if needed\n\n'
          'Original error: $e'
        );
      }
      
      throw Exception('Failed to call Gemini API: $e');
    }
  }

  BookSummary _parseBookSummary(String responseText, BookSummaryInput input, String userId) {
    try {
      String jsonText = _extractJsonFromResponse(responseText);
      final json = jsonDecode(jsonText) as Map<String, dynamic>;
      
      final summary = json['summary'] as String? ?? 'Summary not available';
      final keyPoints = json['keyPoints'] != null 
          ? List<String>.from(json['keyPoints'] as List)
          : null;
      final actionableInsights = json['actionableInsights'] != null 
          ? List<String>.from(json['actionableInsights'] as List)
          : null;
      final chapters = json['chapters'] != null 
          ? List<String>.from(json['chapters'] as List)
          : null;
      final summaryType = json['summaryType'] as String? ?? input.summaryType ?? 'detailed';

      return BookSummary(
        id: '',
        userId: userId,
        bookTitle: input.bookTitle,
        author: input.author,
        summary: summary,
        keyPoints: keyPoints,
        chapters: chapters,
        actionableInsights: actionableInsights,
        summaryType: summaryType,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to parse AI response: $e. Response was: $responseText');
    }
  }
  
  String _extractJsonFromResponse(String responseText) {
    String jsonText = responseText.trim();
    
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.substring(7);
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.substring(3);
    }
    
    if (jsonText.endsWith('```')) {
      jsonText = jsonText.substring(0, jsonText.length - 3);
    }
    
    final startIndex = jsonText.indexOf('{');
    final lastIndex = jsonText.lastIndexOf('}');
    
    if (startIndex != -1 && lastIndex != -1 && lastIndex > startIndex) {
      jsonText = jsonText.substring(startIndex, lastIndex + 1);
    }
    
    return jsonText.trim();
  }
}

