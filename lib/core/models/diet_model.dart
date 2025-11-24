import 'package:cloud_firestore/cloud_firestore.dart';

class DietPlanModel {
  final String id;
  final String userId;
  final String goalType; // weight_loss, weight_gain, muscle_gain, maintenance, general_health
  final String dietType; // balanced, vegetarian, vegan, keto, paleo, mediterranean, low_carb, high_protein
  final String activityLevel; // sedentary, lightly_active, moderately_active, very_active
  final int durationWeeks;
  final int? targetCalories;
  final int? currentWeight;
  final int? targetWeight;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active, completed, paused
  final List<DietDayModel> dietDays;
  final Map<String, dynamic>? planData;
  final String? deletionStatus; // null, "pending", "deleted"

  DietPlanModel({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.dietType,
    required this.activityLevel,
    required this.durationWeeks,
    this.targetCalories,
    this.currentWeight,
    this.targetWeight,
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    this.dietDays = const [],
    this.planData,
    this.deletionStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'goalType': goalType,
      'dietType': dietType,
      'activityLevel': activityLevel,
      'durationWeeks': durationWeeks,
      if (targetCalories != null) 'targetCalories': targetCalories,
      if (currentWeight != null) 'currentWeight': currentWeight,
      if (targetWeight != null) 'targetWeight': targetWeight,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      if (planData != null) 'planData': planData,
      if (deletionStatus != null) 'deletionStatus': deletionStatus,
    };
  }

  factory DietPlanModel.fromMap(Map<String, dynamic> map, String id) {
    return DietPlanModel(
      id: id,
      userId: map['userId'] ?? '',
      goalType: map['goalType'] ?? 'general_health',
      dietType: map['dietType'] ?? 'balanced',
      activityLevel: map['activityLevel'] ?? 'moderately_active',
      durationWeeks: map['durationWeeks'] ?? 4,
      targetCalories: map['targetCalories']?.toInt(),
      currentWeight: map['currentWeight']?.toInt(),
      targetWeight: map['targetWeight']?.toInt(),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
      planData: map['planData'] != null
          ? Map<String, dynamic>.from(map['planData'])
          : null,
      deletionStatus: map['deletionStatus'] as String?,
    );
  }

  DietPlanModel copyWith({
    String? id,
    String? userId,
    String? goalType,
    String? dietType,
    String? activityLevel,
    int? durationWeeks,
    int? targetCalories,
    int? currentWeight,
    int? targetWeight,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    List<DietDayModel>? dietDays,
    Map<String, dynamic>? planData,
    String? deletionStatus,
  }) {
    return DietPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      dietType: dietType ?? this.dietType,
      activityLevel: activityLevel ?? this.activityLevel,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      targetCalories: targetCalories ?? this.targetCalories,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      dietDays: dietDays ?? this.dietDays,
      planData: planData ?? this.planData,
      deletionStatus: deletionStatus ?? this.deletionStatus,
    );
  }
}

class DietDayModel {
  final String id;
  final String planId;
  final int weekNumber;
  final DateTime scheduledDate;
  final int totalCalories;
  final List<MealModel> meals;
  final String? notes;
  final int order;

  DietDayModel({
    required this.id,
    required this.planId,
    required this.weekNumber,
    required this.scheduledDate,
    required this.totalCalories,
    required this.meals,
    this.notes,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'weekNumber': weekNumber,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'totalCalories': totalCalories,
      'meals': meals.map((meal) => meal.toMap()).toList(),
      if (notes != null) 'notes': notes,
      'order': order,
    };
  }

  factory DietDayModel.fromMap(Map<String, dynamic> map, String id) {
    return DietDayModel(
      id: id,
      planId: map['planId'] ?? '',
      weekNumber: map['weekNumber'] ?? 1,
      scheduledDate: (map['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalCalories: map['totalCalories'] ?? 2000,
      meals: (map['meals'] as List<dynamic>?)
          ?.map((m) => MealModel.fromMap(m as Map<String, dynamic>, ''))
          .toList() ?? [],
      notes: map['notes'],
      order: map['order'] ?? 0,
    );
  }

  DietDayModel copyWith({
    String? id,
    String? planId,
    int? weekNumber,
    DateTime? scheduledDate,
    int? totalCalories,
    List<MealModel>? meals,
    String? notes,
    int? order,
  }) {
    return DietDayModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      weekNumber: weekNumber ?? this.weekNumber,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      totalCalories: totalCalories ?? this.totalCalories,
      meals: meals ?? this.meals,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }
}

class MealModel {
  final String id;
  final String dietDayId;
  final String mealType; // breakfast, lunch, dinner, snack
  final String name;
  final int calories;
  final List<FoodItemModel> foods;
  final String? instructions;
  final int? prepTime;

  MealModel({
    required this.id,
    required this.dietDayId,
    required this.mealType,
    required this.name,
    required this.calories,
    required this.foods,
    this.instructions,
    this.prepTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'dietDayId': dietDayId,
      'mealType': mealType,
      'name': name,
      'calories': calories,
      'foods': foods.map((food) => food.toMap()).toList(),
      if (instructions != null) 'instructions': instructions,
      if (prepTime != null) 'prepTime': prepTime,
    };
  }

  factory MealModel.fromMap(Map<String, dynamic> map, String id) {
    return MealModel(
      id: id,
      dietDayId: map['dietDayId'] ?? '',
      mealType: map['mealType'] ?? 'breakfast',
      name: map['name'] ?? '',
      calories: map['calories'] ?? 0,
      foods: (map['foods'] as List<dynamic>?)
          ?.map((f) => FoodItemModel.fromMap(f as Map<String, dynamic>, ''))
          .toList() ?? [],
      instructions: map['instructions'],
      prepTime: map['prepTime']?.toInt(),
    );
  }

  MealModel copyWith({
    String? id,
    String? dietDayId,
    String? mealType,
    String? name,
    int? calories,
    List<FoodItemModel>? foods,
    String? instructions,
    int? prepTime,
  }) {
    return MealModel(
      id: id ?? this.id,
      dietDayId: dietDayId ?? this.dietDayId,
      mealType: mealType ?? this.mealType,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      foods: foods ?? this.foods,
      instructions: instructions ?? this.instructions,
      prepTime: prepTime ?? this.prepTime,
    );
  }
}

class FoodItemModel {
  final String id;
  final String mealId;
  final String name;
  final String amount;
  final int calories;
  final double? protein;
  final double? carbs;
  final double? fats;

  FoodItemModel({
    required this.id,
    required this.mealId,
    required this.name,
    required this.amount,
    required this.calories,
    this.protein,
    this.carbs,
    this.fats,
  });

  Map<String, dynamic> toMap() {
    return {
      'mealId': mealId,
      'name': name,
      'amount': amount,
      'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fats != null) 'fats': fats,
    };
  }

  factory FoodItemModel.fromMap(Map<String, dynamic> map, String id) {
    return FoodItemModel(
      id: id,
      mealId: map['mealId'] ?? '',
      name: map['name'] ?? '',
      amount: map['amount'] ?? '',
      calories: map['calories'] ?? 0,
      protein: map['protein']?.toDouble(),
      carbs: map['carbs']?.toDouble(),
      fats: map['fats']?.toDouble(),
    );
  }

  FoodItemModel copyWith({
    String? id,
    String? mealId,
    String? name,
    String? amount,
    int? calories,
    double? protein,
    double? carbs,
    double? fats,
  }) {
    return FoodItemModel(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
    );
  }
}

