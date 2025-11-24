/// AI-generated project plan structure
class ProjectPlan {
  final List<Phase> phases;

  ProjectPlan({required this.phases});
}

class Phase {
  final String title;
  final String description;
  final int order;
  final List<PhaseTask> tasks;

  Phase({
    required this.title,
    required this.description,
    required this.order,
    required this.tasks,
  });
}

class PhaseTask {
  final String title;
  final String description;
  final double estimatedHours;

  PhaseTask({
    required this.title,
    required this.description,
    required this.estimatedHours,
  });
}

