/// AI-generated diet plan structure
class DietPlan {
  final List<DietWeek> weeks;

  DietPlan({required this.weeks});

  Map<String, dynamic> toMap() {
    return {
      'weeks': weeks.map((week) => week.toMap()).toList(),
    };
  }
}

class DietWeek {
  final int weekNumber;
  final List<DietDay> days;

  DietWeek({
    required this.weekNumber,
    required this.days,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'days': days.map((day) => day.toMap()).toList(),
    };
  }
}

class DietDay {
  final String date; // YYYY-MM-DD format
  final int totalCalories;
  final List<Meal> meals;
  final String? notes; // Optional: daily notes or tips
  final String? cookingSchedule; // Optional: cooking schedule for the day

  DietDay({
    required this.date,
    required this.totalCalories,
    required this.meals,
    this.notes,
    this.cookingSchedule,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalCalories': totalCalories,
      'meals': meals.map((meal) => meal.toMap()).toList(),
      'notes': notes,
      'cookingSchedule': cookingSchedule,
    };
  }
}

class Meal {
  final String mealType; // breakfast, lunch, dinner, snack
  final String name; // Meal name/title
  final int calories;
  final List<FoodItem> foods;
  final String? instructions; // Optional: cooking instructions or tips
  final int? prepTime; // Optional: preparation time in minutes
  final String? cookingSchedule; // Optional: when to cook this meal (e.g., "Cook in morning", "Prep on Sunday")

  Meal({
    required this.mealType,
    required this.name,
    required this.calories,
    required this.foods,
    this.instructions,
    this.prepTime,
    this.cookingSchedule,
  });

  Map<String, dynamic> toMap() {
    return {
      'mealType': mealType,
      'name': name,
      'calories': calories,
      'foods': foods.map((food) => food.toMap()).toList(),
      'instructions': instructions,
      'prepTime': prepTime,
      'cookingSchedule': cookingSchedule,
    };
  }
}

class FoodItem {
  final String name;
  final String amount; // e.g., "200g", "1 cup", "2 pieces"
  final int calories;
  final double? protein; // Optional: grams
  final double? carbs; // Optional: grams
  final double? fats; // Optional: grams

  FoodItem({
    required this.name,
    required this.amount,
    required this.calories,
    this.protein,
    this.carbs,
    this.fats,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }
}

