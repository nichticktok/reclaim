/// AI-generated workout plan structure
class WorkoutPlan {
  final List<WorkoutWeek> weeks;

  WorkoutPlan({required this.weeks});

  Map<String, dynamic> toMap() {
    return {
      'weeks': weeks.map((week) => week.toMap()).toList(),
    };
  }
}

class WorkoutWeek {
  final int weekNumber;
  final List<WorkoutSession> sessions;

  WorkoutWeek({
    required this.weekNumber,
    required this.sessions,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'sessions': sessions.map((session) => session.toMap()).toList(),
    };
  }
}

class WorkoutSession {
  final String title;
  final String focus;
  final List<WorkoutExercise> exercises;

  WorkoutSession({
    required this.title,
    required this.focus,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'focus': focus,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
    };
  }
}

class WorkoutExercise {
  final String name;
  final int sets;
  final String reps; // e.g., "8-12" or "10"
  final int restSeconds;
  final String instructions;

  WorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'instructions': instructions,
    };
  }
}

