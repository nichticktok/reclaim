class PresetTaskModel {
  final String id;
  final String title;
  final String description;
  final String scheduledTime;
  final String category; // e.g., "Health", "Productivity", "Mindfulness", etc.
  final bool requiresProof;

  PresetTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    required this.category,
    this.requiresProof = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime,
      'category': category,
      'requiresProof': requiresProof,
    };
  }

  factory PresetTaskModel.fromMap(Map<String, dynamic> map) {
    return PresetTaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledTime: map['scheduledTime'] ?? '',
      category: map['category'] ?? 'General',
      requiresProof: map['requiresProof'] ?? false,
    );
  }
}

