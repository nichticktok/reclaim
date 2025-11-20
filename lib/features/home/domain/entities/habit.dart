/// Habit entity - Business model
/// This represents the domain concept of a habit
class Habit {
  final String id;
  final String title;
  final String description;
  final String scheduledTime;
  bool completed;
  bool requiresProof;
  final DateTime createdAt;
  DateTime? lastCompletedAt;

  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    this.completed = false,
    this.requiresProof = false,
    DateTime? createdAt,
    this.lastCompletedAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

