/// Input data for AI workout planning
class WorkoutPlanningInput {
  final String goalType; // fat_loss, strength, stamina, muscle_build, general_health
  final String fitnessLevel; // beginner, intermediate, advanced
  final List<String> equipment; // bodyweight, dumbbells, resistance_bands, gym
  final int sessionsPerWeek;
  final int minutesPerSession;
  final int durationWeeks;
  final String? constraints; // Optional: injuries, limitations
  final String? preference; // Optional: home/gym, low_impact/high_intensity
  final List<String>? bodyFocusAreas; // Optional: upper_body, lower_body, core, full_body
  final String? workoutTime; // Optional: morning, afternoon, evening
  final String? intensityPreference; // Optional: low, moderate, high
  final bool? hasPreviousExperience; // Optional: experience with workouts
  final String? currentActivityLevel; // Optional: sedentary, lightly_active, moderately_active, very_active

  WorkoutPlanningInput({
    required this.goalType,
    required this.fitnessLevel,
    required this.equipment,
    required this.sessionsPerWeek,
    required this.minutesPerSession,
    required this.durationWeeks,
    this.constraints,
    this.preference,
    this.bodyFocusAreas,
    this.workoutTime,
    this.intensityPreference,
    this.hasPreviousExperience,
    this.currentActivityLevel,
  });
  Map<String, dynamic> toMap() {
    return {
      'goalType': goalType,
      'fitnessLevel': fitnessLevel,
      'equipment': equipment,
      'sessionsPerWeek': sessionsPerWeek,
      'minutesPerSession': minutesPerSession,
      'durationWeeks': durationWeeks,
      'constraints': constraints,
      'preference': preference,
      'bodyFocusAreas': bodyFocusAreas,
      'workoutTime': workoutTime,
      'intensityPreference': intensityPreference,
      'hasPreviousExperience': hasPreviousExperience,
      'currentActivityLevel': currentActivityLevel,
    };
  }

  factory WorkoutPlanningInput.fromMap(Map<String, dynamic> map) {
    return WorkoutPlanningInput(
      goalType: map['goalType'] ?? '',
      fitnessLevel: map['fitnessLevel'] ?? '',
      equipment: List<String>.from(map['equipment'] ?? []),
      sessionsPerWeek: map['sessionsPerWeek']?.toInt() ?? 0,
      minutesPerSession: map['minutesPerSession']?.toInt() ?? 0,
      durationWeeks: map['durationWeeks']?.toInt() ?? 0,
      constraints: map['constraints'],
      preference: map['preference'],
      bodyFocusAreas: map['bodyFocusAreas'] != null 
          ? List<String>.from(map['bodyFocusAreas']) 
          : null,
      workoutTime: map['workoutTime'],
      intensityPreference: map['intensityPreference'],
      hasPreviousExperience: map['hasPreviousExperience'],
      currentActivityLevel: map['currentActivityLevel'],
    );
  }
}

