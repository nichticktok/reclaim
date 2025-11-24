/// Input data for AI diet planning
class DietPlanningInput {
  final String goalType; // weight_loss, weight_gain, muscle_gain, maintenance, general_health
  final String dietType; // balanced, vegetarian, vegan, keto, paleo, mediterranean, low_carb, high_protein
  final String activityLevel; // sedentary, lightly_active, moderately_active, very_active
  final int durationWeeks;
  final int? targetCalories; // Optional: specific calorie target
  final int? currentWeight; // Optional: in kg
  final int? targetWeight; // Optional: in kg
  final List<String>? allergies; // Optional: food allergies
  final List<String>? dislikes; // Optional: disliked foods
  final List<String>? preferences; // Optional: preferred foods
  final String? mealFrequency; // Optional: 3_meals, 4_meals, 5_meals, 6_meals
  final String? cookingSkill; // Optional: beginner, intermediate, advanced
  final String? budget; // Optional: low, medium, high
  final String? timeAvailable; // Optional: limited, moderate, plenty
  final bool? mealPrepFriendly; // Optional: prefer meal prep
  final String? dietaryRestrictions; // Optional: additional restrictions
  final List<String>? cookingTimeSlots; // Optional: when user can cook (e.g., ["morning", "evening"], ["weekend"])
  final String? cookingCapacity; // Optional: how much they can cook (e.g., "single_meal", "batch_cooking", "full_day_prep")
  final String? cookingSchedule; // Optional: detailed cooking schedule (e.g., "Cook breakfast daily, meal prep on Sunday")

  DietPlanningInput({
    required this.goalType,
    required this.dietType,
    required this.activityLevel,
    required this.durationWeeks,
    this.targetCalories,
    this.currentWeight,
    this.targetWeight,
    this.allergies,
    this.dislikes,
    this.preferences,
    this.mealFrequency,
    this.cookingSkill,
    this.budget,
    this.timeAvailable,
    this.mealPrepFriendly,
    this.dietaryRestrictions,
    this.cookingTimeSlots,
    this.cookingCapacity,
    this.cookingSchedule,
  });

  Map<String, dynamic> toMap() {
    return {
      'goalType': goalType,
      'dietType': dietType,
      'activityLevel': activityLevel,
      'durationWeeks': durationWeeks,
      'targetCalories': targetCalories,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'allergies': allergies,
      'dislikes': dislikes,
      'preferences': preferences,
      'mealFrequency': mealFrequency,
      'cookingSkill': cookingSkill,
      'budget': budget,
      'timeAvailable': timeAvailable,
      'mealPrepFriendly': mealPrepFriendly,
      'dietaryRestrictions': dietaryRestrictions,
      'cookingTimeSlots': cookingTimeSlots,
      'cookingCapacity': cookingCapacity,
      'cookingSchedule': cookingSchedule,
    };
  }

  factory DietPlanningInput.fromMap(Map<String, dynamic> map) {
    return DietPlanningInput(
      goalType: map['goalType'] ?? '',
      dietType: map['dietType'] ?? '',
      activityLevel: map['activityLevel'] ?? '',
      durationWeeks: map['durationWeeks']?.toInt() ?? 0,
      targetCalories: map['targetCalories']?.toInt(),
      currentWeight: map['currentWeight']?.toInt(),
      targetWeight: map['targetWeight']?.toInt(),
      allergies: map['allergies'] != null 
          ? List<String>.from(map['allergies']) 
          : null,
      dislikes: map['dislikes'] != null 
          ? List<String>.from(map['dislikes']) 
          : null,
      preferences: map['preferences'] != null 
          ? List<String>.from(map['preferences']) 
          : null,
      mealFrequency: map['mealFrequency'],
      cookingSkill: map['cookingSkill'],
      budget: map['budget'],
      timeAvailable: map['timeAvailable'],
      mealPrepFriendly: map['mealPrepFriendly'],
      dietaryRestrictions: map['dietaryRestrictions'],
      cookingTimeSlots: map['cookingTimeSlots'] != null 
          ? List<String>.from(map['cookingTimeSlots']) 
          : null,
      cookingCapacity: map['cookingCapacity'],
      cookingSchedule: map['cookingSchedule'],
    );
  }
}

