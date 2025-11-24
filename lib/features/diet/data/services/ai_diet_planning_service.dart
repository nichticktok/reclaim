import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_gemini/flutter_gemini.dart';
import '../../../../app/env.dart';
import '../../domain/entities/diet_planning_input.dart';
import '../../domain/repositories/ai_diet_planning_repository.dart';
import '../../domain/entities/diet_plan.dart';
import '../../../../core/models/diet_model.dart' as diet_model;

/// AI Diet Planning Service
/// Uses Flutter Gemini SDK to generate personalized diet plans based on user input
class AIDietPlanningService implements AIDietPlanningRepository {
  static String getApiKey() {
    return AppEnv.geminiApiKey;
  }

  static String _getApiKey() {
    return getApiKey();
  }

  @override
  Future<DietPlan> generateDietPlan(DietPlanningInput input) async {
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
    return _parseDietPlan(response);
  }

  /// Generate a DietPlanModel with daily meal plans using AI
  Future<diet_model.DietPlanModel> generateDailyDietPlan(
    DietPlanningInput input,
    String userId,
  ) async {
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
    final dailyMeals = _parseDailyMealsFromResponse(response, input);
    
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: input.durationWeeks * 7));

    return diet_model.DietPlanModel(
      id: '',
      userId: userId,
      goalType: input.goalType,
      dietType: input.dietType,
      activityLevel: input.activityLevel,
      durationWeeks: input.durationWeeks,
      targetCalories: input.targetCalories,
      currentWeight: input.currentWeight,
      targetWeight: input.targetWeight,
      startDate: startDate,
      endDate: endDate,
      status: 'active',
      dietDays: dailyMeals,
    );
  }

  String _buildPrompt(DietPlanningInput input) {
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: input.durationWeeks * 7));
    final startDateStr = startDate.toString().split(' ')[0];
    final endDateStr = endDate.toString().split(' ')[0];
    final totalDays = input.durationWeeks * 7;

    final allergiesStr = input.allergies != null && input.allergies!.isNotEmpty
        ? input.allergies!.join(', ')
        : 'none';
    
    final dislikesStr = input.dislikes != null && input.dislikes!.isNotEmpty
        ? input.dislikes!.join(', ')
        : 'none';

    final preferencesStr = input.preferences != null && input.preferences!.isNotEmpty
        ? input.preferences!.join(', ')
        : 'no specific preferences';

    return '''
You are an expert nutritionist and meal planning assistant. Create a comprehensive, personalized diet plan with day-by-day meal breakdown based on the following user preferences:

USER INFORMATION:
- Goal: ${input.goalType}
- Diet Type: ${input.dietType}
- Activity Level: ${input.activityLevel}
- Duration: ${input.durationWeeks} weeks ($totalDays days)
${input.targetCalories != null ? '- Target Calories: ${input.targetCalories} per day' : ''}
${input.currentWeight != null ? '- Current Weight: ${input.currentWeight} kg' : ''}
${input.targetWeight != null ? '- Target Weight: ${input.targetWeight} kg' : ''}
- Allergies: $allergiesStr
- Dislikes: $dislikesStr
- Preferences: $preferencesStr
${input.mealFrequency != null ? '- Meal Frequency: ${input.mealFrequency}' : ''}
${input.cookingSkill != null ? '- Cooking Skill: ${input.cookingSkill}' : ''}
${input.budget != null ? '- Budget: ${input.budget}' : ''}
${input.timeAvailable != null ? '- Time Available: ${input.timeAvailable}' : ''}
${input.mealPrepFriendly != null ? '- Meal Prep Friendly: ${input.mealPrepFriendly}' : ''}
${input.dietaryRestrictions != null ? '- Additional Restrictions: ${input.dietaryRestrictions}' : ''}
${input.cookingTimeSlots != null && input.cookingTimeSlots!.isNotEmpty ? '- Cooking Time Slots: ${input.cookingTimeSlots!.join(', ')}' : ''}
${input.cookingCapacity != null ? '- Cooking Capacity: ${input.cookingCapacity}' : ''}
${input.cookingSchedule != null ? '- Cooking Schedule: ${input.cookingSchedule}' : ''}

YOUR TASK:
Create a complete diet plan that includes:

1. WEEK-BY-WEEK STRUCTURE: Organize meals into weeks
   - ${input.durationWeeks} weeks total
   - Each week should have progressive adjustments if needed
   - Each day should have: date, total calories, and meals

2. DAY-BY-DAY SCHEDULE: Create a detailed daily meal schedule
   - Start from $startDateStr and create meals for each day until $endDateStr
   - Each day should have:
     * Date (YYYY-MM-DD format)
     * Total calories for the day (should align with goal and target if provided)
     * List of meals (breakfast, lunch, dinner, and snacks as appropriate)
     * Each meal should have:
       - Meal type (breakfast, lunch, dinner, snack)
       - Meal name/title
       - Calories for the meal
       - List of food items with:
         * Food name
         * Amount (e.g., "200g", "1 cup", "2 pieces", "1 serving")
         * Calories
         * Protein (grams, optional)
         * Carbs (grams, optional)
         * Fats (grams, optional)
       - Preparation instructions (optional)
       - Prep time in minutes (optional)
       - Cooking schedule note: When to cook this meal (e.g., "Cook in morning", "Prep on Sunday", "Quick evening meal")
     * Optional daily notes or tips
     * Cooking schedule for the day: When to cook each meal based on user's available time slots
   - Ensure variety across days to prevent boredom
   - Match meals to diet type: ${input.dietType}
   - Consider activity level: ${input.activityLevel}
   - Progress nutrition goals over time if applicable

IMPORTANT GUIDELINES:
- Make it realistic and achievable
- Total days should be exactly $totalDays
- Meals should be appropriate for the diet type (${input.dietType})
- Consider the goal (${input.goalType}) when structuring meals
- Each day should be complete and actionable
- Ensure nutritional balance (proteins, carbs, fats)
- Avoid allergens: $allergiesStr
- Avoid disliked foods: $dislikesStr
- Incorporate preferred foods when possible: $preferencesStr
${input.targetCalories != null ? '- Daily calories should be around ${input.targetCalories} calories' : '- Calculate appropriate daily calories based on goal and activity level'}
${input.cookingSkill != null ? '- Match recipe complexity to cooking skill: ${input.cookingSkill}' : ''}
${input.budget != null ? '- Consider budget constraints: ${input.budget}' : ''}
${input.timeAvailable != null ? '- Match prep time to available time: ${input.timeAvailable}' : ''}
${input.mealPrepFriendly != null && input.mealPrepFriendly! ? '- Prioritize meal prep friendly recipes' : ''}
${input.cookingTimeSlots != null && input.cookingTimeSlots!.isNotEmpty ? '- CRITICAL: Only schedule cooking during these times: ${input.cookingTimeSlots!.join(', ')}. Do NOT suggest cooking at other times.' : ''}
${input.cookingCapacity != null ? '- CRITICAL: Match cooking capacity to: ${input.cookingCapacity}. If single_meal, suggest cooking each meal fresh. If batch_cooking, suggest preparing multiple servings. If full_day_prep, suggest preparing all meals for the day at once. If weekly_prep, suggest meal prep sessions.' : ''}
${input.cookingSchedule != null ? '- CRITICAL: Follow this cooking schedule exactly: ${input.cookingSchedule}' : ''}

Return your plan as JSON. Include both:
- "weeks": Array of weeks with days
- "dailyMeals": Array of daily meal plans, one for each day from $startDateStr to $endDateStr

Example structure:
{
  "weeks": [
    {
      "weekNumber": 1,
      "days": [
        {
          "date": "YYYY-MM-DD",
          "totalCalories": 2000,
          "meals": [
            {
              "mealType": "breakfast",
              "name": "Oatmeal with Berries",
              "calories": 350,
              "foods": [
                {
                  "name": "Rolled Oats",
                  "amount": "1 cup",
                  "calories": 300,
                  "protein": 10,
                  "carbs": 54,
                  "fats": 6
                },
                {
                  "name": "Blueberries",
                  "amount": "100g",
                  "calories": 50,
                  "protein": 0.7,
                  "carbs": 12,
                  "fats": 0.3
                }
              ],
              "instructions": "Cook oats with water, top with berries",
              "prepTime": 10,
              "cookingSchedule": "Cook fresh in the morning"
            }
          ],
          "notes": "Start your day with a nutritious breakfast",
          "cookingSchedule": "Morning: Cook breakfast fresh. Evening: Prepare dinner."
        }
      ]
    }
  ],
  "dailyMeals": [
    {
      "date": "YYYY-MM-DD",
      "totalCalories": 2000,
      "meals": [...]
    }
  ]
}
''';
  }

  Future<String> _callGeminiAPI(String prompt) async {
    try {
      debugPrint('🤖 Calling Gemini API for diet plan generation...');
      
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
          '2. The API key is set in ai_diet_planning_service.dart\n'
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

  DietPlan _parseDietPlan(String responseText) {
    try {
      String jsonText = _extractJsonFromResponse(responseText);
      final json = jsonDecode(jsonText) as Map<String, dynamic>;
      
      List<dynamic> weeksJson;
      
      if (json.containsKey('weeks')) {
        weeksJson = json['weeks'] as List<dynamic>;
      } else if (json.containsKey('diet_plan') && json['diet_plan'] is Map) {
        final dietPlan = json['diet_plan'] as Map<String, dynamic>;
        weeksJson = dietPlan['weeks'] as List<dynamic>? ?? [];
      } else if (json.containsKey('plan') && json['plan'] is Map) {
        final plan = json['plan'] as Map<String, dynamic>;
        weeksJson = plan['weeks'] as List<dynamic>? ?? [];
      } else {
        throw Exception('Could not find weeks in AI response structure');
      }
      
      final weeks = weeksJson.map((weekJson) {
        final week = weekJson is Map<String, dynamic> 
            ? weekJson 
            : Map<String, dynamic>.from(weekJson as Map);
        
        final daysJson = week['days'] as List<dynamic>? ?? [];
        final days = daysJson.map((dayJson) {
          final day = dayJson is Map<String, dynamic>
              ? dayJson
              : Map<String, dynamic>.from(dayJson as Map);
          
          final mealsJson = day['meals'] as List<dynamic>? ?? [];
          final meals = mealsJson.map((mealJson) {
            final meal = mealJson is Map<String, dynamic>
                ? mealJson
                : Map<String, dynamic>.from(mealJson as Map);
            
            final foodsJson = meal['foods'] as List<dynamic>? ?? [];
            final foods = foodsJson.map((foodJson) {
              final food = foodJson is Map<String, dynamic>
                  ? foodJson
                  : Map<String, dynamic>.from(foodJson as Map);
              
              return FoodItem(
                name: food['name'] as String? ?? 'Unknown Food',
                amount: food['amount'] as String? ?? '1 serving',
                calories: (food['calories'] as num?)?.toInt() ?? 0,
                protein: (food['protein'] as num?)?.toDouble(),
                carbs: (food['carbs'] as num?)?.toDouble(),
                fats: (food['fats'] as num?)?.toDouble(),
              );
            }).toList();
            
            return Meal(
              mealType: meal['mealType'] as String? ?? 'breakfast',
              name: meal['name'] as String? ?? 'Meal',
              calories: (meal['calories'] as num?)?.toInt() ?? 0,
              foods: foods,
              instructions: meal['instructions'] as String?,
              prepTime: (meal['prepTime'] as num?)?.toInt(),
              cookingSchedule: meal['cookingSchedule'] as String?,
            );
          }).toList();
          
          return DietDay(
            date: day['date'] as String? ?? '',
            totalCalories: (day['totalCalories'] as num?)?.toInt() ?? 2000,
            meals: meals,
            notes: day['notes'] as String?,
            cookingSchedule: day['cookingSchedule'] as String?,
          );
        }).toList();
        
        return DietWeek(
          weekNumber: (week['weekNumber'] as num?)?.toInt() ?? 1,
          days: days,
        );
      }).toList();
      
      return DietPlan(weeks: weeks);
    } catch (e) {
      throw Exception('Failed to parse AI response: $e. Response was: $responseText');
    }
  }

  List<diet_model.DietDayModel> _parseDailyMealsFromResponse(
    String responseText,
    DietPlanningInput input,
  ) {
    try {
      String jsonText = _extractJsonFromResponse(responseText);
      final json = jsonDecode(jsonText) as Map<String, dynamic>;
      
      List<dynamic>? dailyMealsJson;
      
      if (json.containsKey('dailyMeals')) {
        dailyMealsJson = json['dailyMeals'] as List<dynamic>?;
      } else if (json.containsKey('schedule')) {
        dailyMealsJson = json['schedule'] as List<dynamic>?;
      } else if (json.containsKey('days')) {
        dailyMealsJson = json['days'] as List<dynamic>?;
      } else if (json.containsKey('dietDays')) {
        dailyMealsJson = json['dietDays'] as List<dynamic>?;
      }
      
      if (dailyMealsJson != null && dailyMealsJson.isNotEmpty) {
        return _parseDailyMealsArray(dailyMealsJson, input);
      }
      
      return _generateDailyMealsFromWeeks(json, input);
    } catch (e) {
      debugPrint('⚠️ Warning: Could not parse daily meals from response: $e');
      return [];
    }
  }
  
  List<diet_model.DietDayModel> _parseDailyMealsArray(
    List<dynamic> dailyMealsJson,
    DietPlanningInput input,
  ) {
    final startDate = DateTime.now();
    
    return dailyMealsJson.asMap().entries.map((entry) {
      final dayJson = entry.value is Map<String, dynamic> 
          ? entry.value as Map<String, dynamic>
          : Map<String, dynamic>.from(entry.value as Map);
      
      String dateStr = dayJson['date'] as String? ?? '';
      DateTime scheduledDate;
      
      if (dateStr.contains('-')) {
        final dateParts = dateStr.split('-');
        scheduledDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
      } else {
        scheduledDate = startDate.add(Duration(days: entry.key));
      }
      
      final mealsJson = dayJson['meals'] as List<dynamic>? ?? [];
      final meals = mealsJson.asMap().entries.map((mealEntry) {
        final mealJson = mealEntry.value is Map<String, dynamic>
            ? mealEntry.value as Map<String, dynamic>
            : Map<String, dynamic>.from(mealEntry.value as Map);
        
        final foodsJson = mealJson['foods'] as List<dynamic>? ?? [];
        final foods = foodsJson.asMap().entries.map((foodEntry) {
          final foodJson = foodEntry.value is Map<String, dynamic>
              ? foodEntry.value as Map<String, dynamic>
              : Map<String, dynamic>.from(foodEntry.value as Map);
          
          return diet_model.FoodItemModel(
            id: '',
            mealId: '',
            name: foodJson['name'] as String? ?? 'Unknown Food',
            amount: foodJson['amount'] as String? ?? '1 serving',
            calories: (foodJson['calories'] as num?)?.toInt() ?? 0,
            protein: (foodJson['protein'] as num?)?.toDouble(),
            carbs: (foodJson['carbs'] as num?)?.toDouble(),
            fats: (foodJson['fats'] as num?)?.toDouble(),
          );
        }).toList();

        return diet_model.MealModel(
          id: '',
          dietDayId: '',
          mealType: mealJson['mealType'] as String? ?? 'breakfast',
          name: mealJson['name'] as String? ?? 'Meal',
          calories: (mealJson['calories'] as num?)?.toInt() ?? 0,
          foods: foods,
          instructions: mealJson['instructions'] as String?,
          prepTime: (mealJson['prepTime'] as num?)?.toInt(),
        );
        // Note: cookingSchedule is stored in the Meal entity but not in MealModel
        // It will be displayed from the DietDay cookingSchedule or meal instructions
      }).toList();
      
      final weekNumber = ((scheduledDate.difference(startDate).inDays / 7).floor() + 1)
          .clamp(1, input.durationWeeks);
      
      return diet_model.DietDayModel(
        id: '',
        planId: '',
        weekNumber: weekNumber,
        scheduledDate: scheduledDate,
        totalCalories: (dayJson['totalCalories'] as num?)?.toInt() ?? 2000,
        meals: meals,
        notes: dayJson['notes'] as String?,
        order: entry.key + 1,
      );
      // Note: cookingSchedule from dayJson will be included in notes or displayed separately
    }).toList();
  }

  List<diet_model.DietDayModel> _generateDailyMealsFromWeeks(
    Map<String, dynamic> json,
    DietPlanningInput input,
  ) {
    final startDate = DateTime.now();
    final weeksJson = json['weeks'] as List<dynamic>? ?? [];
    final days = <diet_model.DietDayModel>[];
    int dayCounter = 0;
    
    for (var weekJson in weeksJson) {
      final week = weekJson is Map<String, dynamic> 
          ? weekJson 
          : Map<String, dynamic>.from(weekJson as Map);
      
      final weekNumber = (week['weekNumber'] as num?)?.toInt() ?? 1;
      final daysJson = week['days'] as List<dynamic>? ?? [];
      
      for (var dayJson in daysJson) {
        final day = dayJson is Map<String, dynamic>
            ? dayJson
            : Map<String, dynamic>.from(dayJson as Map);
        
        final scheduledDate = startDate.add(Duration(days: dayCounter));
        
        final mealsJson = day['meals'] as List<dynamic>? ?? [];
        final meals = mealsJson.asMap().entries.map((mealEntry) {
          final meal = mealEntry.value is Map<String, dynamic>
              ? mealEntry.value as Map<String, dynamic>
              : Map<String, dynamic>.from(mealEntry.value as Map);
          
          final foodsJson = meal['foods'] as List<dynamic>? ?? [];
          final foods = foodsJson.asMap().entries.map((foodEntry) {
            final food = foodEntry.value is Map<String, dynamic>
                ? foodEntry.value as Map<String, dynamic>
                : Map<String, dynamic>.from(foodEntry.value as Map);
            
            return diet_model.FoodItemModel(
              id: '',
              mealId: '',
              name: food['name'] as String? ?? 'Unknown Food',
              amount: food['amount'] as String? ?? '1 serving',
              calories: (food['calories'] as num?)?.toInt() ?? 0,
              protein: (food['protein'] as num?)?.toDouble(),
              carbs: (food['carbs'] as num?)?.toDouble(),
              fats: (food['fats'] as num?)?.toDouble(),
            );
          }).toList();

          return diet_model.MealModel(
            id: '',
            dietDayId: '',
            mealType: meal['mealType'] as String? ?? 'breakfast',
            name: meal['name'] as String? ?? 'Meal',
            calories: (meal['calories'] as num?)?.toInt() ?? 0,
            foods: foods,
            instructions: meal['instructions'] as String?,
            prepTime: (meal['prepTime'] as num?)?.toInt(),
          );
        }).toList();
        
        days.add(diet_model.DietDayModel(
          id: '',
          planId: '',
          weekNumber: weekNumber,
          scheduledDate: scheduledDate,
          totalCalories: (day['totalCalories'] as num?)?.toInt() ?? 2000,
          meals: meals,
          notes: day['notes'] as String?,
          order: dayCounter + 1,
        ));
        
        dayCounter++;
      }
    }
    
    return days;
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

