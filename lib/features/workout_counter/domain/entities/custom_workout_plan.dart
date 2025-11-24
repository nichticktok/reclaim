/// Custom workout plan created by user
class CustomWorkoutPlan {
  final String id;
  final String userId;
  final String planName;
  final String? description;
  final List<CustomExercise> exercises;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int totalWorkouts; // Number of times this plan was completed
  final Duration? bestTime; // Best completion time

  CustomWorkoutPlan({
    required this.id,
    required this.userId,
    required this.planName,
    this.description,
    required this.exercises,
    required this.createdAt,
    this.updatedAt,
    this.totalWorkouts = 0,
    this.bestTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planName': planName,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'totalWorkouts': totalWorkouts,
      'bestTime': bestTime?.inSeconds,
    };
  }

  factory CustomWorkoutPlan.fromMap(Map<String, dynamic> map, String id) {
    return CustomWorkoutPlan(
      id: id,
      userId: map['userId'] ?? '',
      planName: map['planName'] ?? '',
      description: map['description'],
      exercises: (map['exercises'] as List<dynamic>?)
          ?.map((e) => CustomExercise.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      totalWorkouts: map['totalWorkouts'] ?? 0,
      bestTime: map['bestTime'] != null 
          ? Duration(seconds: map['bestTime'] as int)
          : null,
    );
  }

  CustomWorkoutPlan copyWith({
    String? id,
    String? userId,
    String? planName,
    String? description,
    List<CustomExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalWorkouts,
    Duration? bestTime,
  }) {
    return CustomWorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planName: planName ?? this.planName,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      bestTime: bestTime ?? this.bestTime,
    );
  }
}

class CustomExercise {
  final String name;
  final int sets;
  final String reps; // e.g., "10", "10-12", "30s"
  final int restSeconds; // Rest between sets
  final int restBetweenExercises; // Rest after completing all sets, before next exercise
  final String? instructions; // Optional: form tips or notes

  CustomExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.restBetweenExercises = 90,
    this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'restBetweenExercises': restBetweenExercises,
      'instructions': instructions,
    };
  }

  factory CustomExercise.fromMap(Map<String, dynamic> map) {
    return CustomExercise(
      name: map['name'] ?? '',
      sets: map['sets'] ?? 3,
      reps: map['reps'] ?? '10',
      restSeconds: map['restSeconds'] ?? 60,
      restBetweenExercises: map['restBetweenExercises'] ?? 90,
      instructions: map['instructions'],
    );
  }

  CustomExercise copyWith({
    String? name,
    int? sets,
    String? reps,
    int? restSeconds,
    int? restBetweenExercises,
    String? instructions,
  }) {
    return CustomExercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      restBetweenExercises: restBetweenExercises ?? this.restBetweenExercises,
      instructions: instructions ?? this.instructions,
    );
  }
}

