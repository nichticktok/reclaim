import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutPlanModel {
  final String id;
  final String userId;
  final String goalType; // fat_loss, strength, stamina, muscle_build, general_health
  final String fitnessLevel; // beginner, intermediate, advanced
  final int durationWeeks;
  final int sessionsPerWeek;
  final int minutesPerSession;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active, completed, paused
  final List<String> equipment; // bodyweight, dumbbells, resistance_bands, gym
  final String? constraints; // Optional: injuries, limitations
  final List<WorkoutDayModel> workoutDays;
  final Map<String, dynamic>? planData;
  final String? deletionStatus; // null, "pending", "deleted"

  WorkoutPlanModel({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.fitnessLevel,
    required this.durationWeeks,
    required this.sessionsPerWeek,
    required this.minutesPerSession,
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    this.equipment = const [],
    this.constraints,
    this.workoutDays = const [],
    this.planData,
    this.deletionStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'goalType': goalType,
      'fitnessLevel': fitnessLevel,
      'durationWeeks': durationWeeks,
      'sessionsPerWeek': sessionsPerWeek,
      'minutesPerSession': minutesPerSession,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'equipment': equipment,
      if (constraints != null) 'constraints': constraints,
      if (planData != null) 'planData': planData,
      if (deletionStatus != null) 'deletionStatus': deletionStatus,
    };
  }

  factory WorkoutPlanModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutPlanModel(
      id: id,
      userId: map['userId'] ?? '',
      goalType: map['goalType'] ?? 'general_health',
      fitnessLevel: map['fitnessLevel'] ?? 'beginner',
      durationWeeks: map['durationWeeks'] ?? 4,
      sessionsPerWeek: map['sessionsPerWeek'] ?? 3,
      minutesPerSession: map['minutesPerSession'] ?? 30,
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
      equipment: map['equipment'] != null 
          ? List<String>.from(map['equipment'])
          : [],
      constraints: map['constraints'],
      planData: map['planData'] != null
          ? Map<String, dynamic>.from(map['planData'])
          : null,
      deletionStatus: map['deletionStatus'] as String?,
    );
  }

  WorkoutPlanModel copyWith({
    String? id,
    String? userId,
    String? goalType,
    String? fitnessLevel,
    int? durationWeeks,
    int? sessionsPerWeek,
    int? minutesPerSession,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    List<String>? equipment,
    String? constraints,
    List<WorkoutDayModel>? workoutDays,
    Map<String, dynamic>? planData,
    String? deletionStatus,
  }) {
    return WorkoutPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      minutesPerSession: minutesPerSession ?? this.minutesPerSession,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      equipment: equipment ?? this.equipment,
      constraints: constraints ?? this.constraints,
      workoutDays: workoutDays ?? this.workoutDays,
      planData: planData ?? this.planData,
      deletionStatus: deletionStatus ?? this.deletionStatus,
    );
  }

  double get progressPercentage {
    if (workoutDays.isEmpty) return 0.0;
    final completed = workoutDays.where((d) => d.isCompleted).length;
    return completed / workoutDays.length;
  }
}

class WorkoutDayModel {
  final String id;
  final String planId;
  final int weekNumber;
  final String dayLabel; // e.g., "Day 1 – Upper Body"
  final DateTime? scheduledDate;
  final String focus; // e.g., "push movements, core"
  final List<WorkoutExerciseModel> exercises;
  final int order;
  final int minutes;
  final bool isCompleted;
  final DateTime? completedAt;

  WorkoutDayModel({
    required this.id,
    required this.planId,
    required this.weekNumber,
    required this.dayLabel,
    this.scheduledDate,
    this.focus = '',
    this.exercises = const [],
    this.order = 0,
    this.minutes = 0,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'weekNumber': weekNumber,
      'dayLabel': dayLabel,
      if (scheduledDate != null) 'scheduledDate': Timestamp.fromDate(scheduledDate!),
      'focus': focus,
      'order': order,
      'minutes': minutes,
      'isCompleted': isCompleted,
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    };
  }

  factory WorkoutDayModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutDayModel(
      id: id,
      planId: map['planId'] ?? '',
      weekNumber: map['weekNumber'] ?? 1,
      dayLabel: map['dayLabel'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp?)?.toDate(),
      focus: map['focus'] ?? '',
      order: map['order'] ?? 0,
      minutes: map['minutes'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  WorkoutDayModel copyWith({
    String? id,
    String? planId,
    int? weekNumber,
    String? dayLabel,
    DateTime? scheduledDate,
    String? focus,
    List<WorkoutExerciseModel>? exercises,
    int? order,
    int? minutes,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return WorkoutDayModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      weekNumber: weekNumber ?? this.weekNumber,
      dayLabel: dayLabel ?? this.dayLabel,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      focus: focus ?? this.focus,
      exercises: exercises ?? this.exercises,
      order: order ?? this.order,
      minutes: minutes ?? this.minutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class WorkoutExerciseModel {
  final String id;
  final String workoutDayId;
  final String name;
  final int sets;
  final String reps; // e.g., "8-12" or "10"
  final int restSeconds;
  final String instructions;
  final String equipment; // bodyweight, dumbbell, etc.
  final String intensityLevel; // easy, medium, hard
  final bool isCompleted;

  WorkoutExerciseModel({
    required this.id,
    required this.workoutDayId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.instructions,
    required this.equipment,
    this.intensityLevel = 'medium',
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'workoutDayId': workoutDayId,
      'name': name,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'instructions': instructions,
      'equipment': equipment,
      'intensityLevel': intensityLevel,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutExerciseModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutExerciseModel(
      id: id,
      workoutDayId: map['workoutDayId'] ?? '',
      name: map['name'] ?? '',
      sets: map['sets'] ?? 3,
      reps: map['reps'] ?? '10',
      restSeconds: map['restSeconds'] ?? 60,
      instructions: map['instructions'] ?? '',
      equipment: map['equipment'] ?? 'bodyweight',
      intensityLevel: map['intensityLevel'] ?? 'medium',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  WorkoutExerciseModel copyWith({
    String? id,
    String? workoutDayId,
    String? name,
    int? sets,
    String? reps,
    int? restSeconds,
    String? instructions,
    String? equipment,
    String? intensityLevel,
    bool? isCompleted,
  }) {
    return WorkoutExerciseModel(
      id: id ?? this.id,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      instructions: instructions ?? this.instructions,
      equipment: equipment ?? this.equipment,
      intensityLevel: intensityLevel ?? this.intensityLevel,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

