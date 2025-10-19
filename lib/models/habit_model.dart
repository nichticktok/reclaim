class HabitModel {
  final String id;
  final String title;
  final String description;
  final String scheduledTime;
  bool completed;
  bool requiresProof;
  DateTime createdAt;
  DateTime? lastCompletedAt;

  HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    this.completed = false,
    this.requiresProof = false,
    DateTime? createdAt,
    this.lastCompletedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime,
      'completed': completed,
      'requiresProof': requiresProof,
      'createdAt': createdAt.toIso8601String(),
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledTime: map['scheduledTime'] ?? '',
      completed: map['completed'] ?? false,
      requiresProof: map['requiresProof'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      lastCompletedAt: map['lastCompletedAt'] != null
          ? DateTime.tryParse(map['lastCompletedAt'])
          : null,
    );
  }
}
