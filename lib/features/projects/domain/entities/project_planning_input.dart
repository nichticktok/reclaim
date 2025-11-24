/// Input data for AI project planning
class ProjectPlanningInput {
  final String title;
  final String description;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final double hoursPerDay;
  final double? hoursPerWeek;

  ProjectPlanningInput({
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.hoursPerDay,
    this.hoursPerWeek,
  });

  int get totalDays => endDate.difference(startDate).inDays;
  double get totalAvailableHours => totalDays * hoursPerDay;
}

