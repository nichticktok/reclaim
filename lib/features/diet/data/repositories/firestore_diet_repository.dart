import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/diet_repository.dart';
import '../../../../core/models/diet_model.dart';

class FirestoreDietRepository implements DietRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> saveDietPlan(String userId, Map<String, dynamic> planData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('diet_plans')
        .add({
      ...planData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getUserDietPlans(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('diet_plans')
        .orderBy('startDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getActiveDietPlan(String userId) async {
    final plans = await getUserDietPlans(userId);
    try {
      return plans.firstWhere((p) => p['status'] == 'active');
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateDietPlan(String planId, Map<String, dynamic> updates) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('diet_plans')
        .doc(planId)
        .update(updates);
  }

  @override
  Future<void> deleteDietPlan(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Delete meals and days first
    final days = await getDietDays(planId);
    for (var day in days) {
      final meals = await getMeals(day.id);
      for (var meal in meals) {
        final foods = await getFoodItems(meal.id);
        for (var food in foods) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('diet_plans')
              .doc(planId)
              .collection('diet_days')
              .doc(day.id)
              .collection('meals')
              .doc(meal.id)
              .collection('food_items')
              .doc(food.id)
              .delete();
        }
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('diet_plans')
            .doc(planId)
            .collection('diet_days')
            .doc(day.id)
            .collection('meals')
            .doc(meal.id)
            .delete();
      }
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('diet_plans')
          .doc(planId)
          .collection('diet_days')
          .doc(day.id)
          .delete();
    }

    // Delete plan
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('diet_plans')
        .doc(planId)
        .delete();
  }

  /// Save a complete diet plan model with all days and meals
  Future<String> saveDietPlanModel(DietPlanModel plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final planRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('diet_plans')
        .add(plan.toMap());
    
    // Save diet days
    final batch = _firestore.batch();
    for (var day in plan.dietDays) {
      final dayRef = planRef.collection('diet_days').doc();
      final dayWithId = day.copyWith(id: dayRef.id, planId: planRef.id);
      batch.set(dayRef, dayWithId.toMap());
      
      // Save meals for each day
      for (var meal in day.meals) {
        final mealRef = dayRef.collection('meals').doc();
        final mealWithId = meal.copyWith(id: mealRef.id, dietDayId: dayRef.id);
        batch.set(mealRef, mealWithId.toMap());
        
        // Save food items for each meal
        for (var food in meal.foods) {
          final foodRef = mealRef.collection('food_items').doc();
          final foodWithId = food.copyWith(id: foodRef.id, mealId: mealRef.id);
          batch.set(foodRef, foodWithId.toMap());
        }
      }
    }
    
    await batch.commit();
    return planRef.id;
  }

  /// Get a complete diet plan model with all days and meals
  Future<DietPlanModel?> getDietPlanModel(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final planDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('diet_plans')
        .doc(planId)
        .get();

    if (!planDoc.exists) return null;

    final plan = DietPlanModel.fromMap(planDoc.data()!, planDoc.id);
    final days = await getDietDays(planId);
    
    return plan.copyWith(dietDays: days);
  }

  Future<List<DietDayModel>> getDietDays(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final daysSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('diet_plans')
        .doc(planId)
        .collection('diet_days')
        .orderBy('scheduledDate')
        .get();

    final days = <DietDayModel>[];
    for (var doc in daysSnapshot.docs) {
      final day = DietDayModel.fromMap(doc.data(), doc.id);
      final meals = await getMeals(day.id);
      days.add(day.copyWith(meals: meals));
    }

    return days;
  }

  Future<List<MealModel>> getMeals(String dietDayId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the diet day
    final plansSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('diet_plans')
        .get();

    for (var planDoc in plansSnapshot.docs) {
      final mealsSnapshot = await planDoc.reference
          .collection('diet_days')
          .doc(dietDayId)
          .collection('meals')
          .get();

      if (mealsSnapshot.docs.isNotEmpty) {
        final meals = <MealModel>[];
        for (var mealDoc in mealsSnapshot.docs) {
          final meal = MealModel.fromMap(mealDoc.data(), mealDoc.id);
          final foods = await getFoodItems(meal.id);
          meals.add(meal.copyWith(foods: foods));
        }
        return meals;
      }
    }

    return [];
  }

  Future<List<FoodItemModel>> getFoodItems(String mealId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the meal
    final plansSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('diet_plans')
        .get();

    for (var planDoc in plansSnapshot.docs) {
      final daysSnapshot = await planDoc.reference
          .collection('diet_days')
          .get();

      for (var dayDoc in daysSnapshot.docs) {
        final foodsSnapshot = await dayDoc.reference
            .collection('meals')
            .doc(mealId)
            .collection('food_items')
            .get();

        if (foodsSnapshot.docs.isNotEmpty) {
          return foodsSnapshot.docs
              .map((doc) => FoodItemModel.fromMap(doc.data(), doc.id))
              .toList();
        }
      }
    }

    return [];
  }
}

