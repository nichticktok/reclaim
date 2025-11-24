import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recalim/core/models/diet_model.dart';
import '../../domain/entities/diet_planning_input.dart';
import '../../domain/entities/diet_plan.dart';
import '../../domain/repositories/diet_repository.dart';
import '../../data/repositories/firestore_diet_repository.dart';
import '../../data/services/ai_diet_planning_service.dart';

class DietController extends ChangeNotifier {
  final DietRepository _repository = FirestoreDietRepository();
  final AIDietPlanningService _aiService = AIDietPlanningService();

  List<DietPlanModel> _dietPlans = [];
  DietPlanModel? _activePlan;
  DietPlan? _generatedPlan;
  DietPlanModel? _generatedDailyPlan;
  bool _loading = false;
  String? _error;

  List<DietPlanModel> get dietPlans => _dietPlans;
  DietPlanModel? get activePlan => _activePlan;
  DietPlan? get generatedPlan => _generatedPlan;
  DietPlanModel? get generatedDailyPlan => _generatedDailyPlan;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    if (_dietPlans.isNotEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final plansData = await _repository.getUserDietPlans(user.uid);
      _dietPlans = plansData.map((data) {
        // Convert map to DietPlanModel - simplified for now
        return DietPlanModel(
          id: data['id'] ?? '',
          userId: data['userId'] ?? user.uid,
          goalType: data['goalType'] ?? 'general_health',
          dietType: data['dietType'] ?? 'balanced',
          activityLevel: data['activityLevel'] ?? 'moderately_active',
          durationWeeks: data['durationWeeks'] ?? 4,
          targetCalories: data['targetCalories']?.toInt(),
          currentWeight: data['currentWeight']?.toInt(),
          targetWeight: data['targetWeight']?.toInt(),
          startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? 'active',
        );
      }).toList();
      
      try {
        final activeData = await _repository.getActiveDietPlan(user.uid);
        if (activeData != null) {
          _activePlan = DietPlanModel(
            id: activeData['id'] ?? '',
            userId: activeData['userId'] ?? user.uid,
            goalType: activeData['goalType'] ?? 'general_health',
            dietType: activeData['dietType'] ?? 'balanced',
            activityLevel: activeData['activityLevel'] ?? 'moderately_active',
            durationWeeks: activeData['durationWeeks'] ?? 4,
            targetCalories: activeData['targetCalories']?.toInt(),
            currentWeight: activeData['currentWeight']?.toInt(),
            targetWeight: activeData['targetWeight']?.toInt(),
            startDate: (activeData['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            endDate: (activeData['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: activeData['status'] ?? 'active',
          );
        }
      } catch (e) {
        _activePlan = null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading diet plans: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Generate a diet plan using AI and save to diet_plans collection
  Future<DietPlan> generatePlan(DietPlanningInput input) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      _generatedPlan = await _aiService.generateDietPlan(input);
      
      final dailyDietPlan = await _aiService.generateDailyDietPlan(input, user.uid);
      final repository = FirestoreDietRepository();
      final savedPlanId = await repository.saveDietPlanModel(dailyDietPlan);
      
      _generatedDailyPlan = dailyDietPlan.copyWith(id: savedPlanId);

      debugPrint('✅ AI diet plan generated and saved: $savedPlanId');
      
      return _generatedPlan!;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error generating diet plan: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _dietPlans = [];
    await initialize();
  }
}

