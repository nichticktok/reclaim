class ProgressModel {
  final String id;
  final String userId;

  DateTime date; // e.g., 2025-10-19
  int totalHabits; // total scheduled for that day
  int completedHabits;
  int verifiedHabits; // with proof verified
  double successRate; // auto-calculated
  int streakCount; // how many days in a row completed
  bool isAllProofVerified; // true if all verified that day

  ProgressModel({
    required this.id,
    required this.userId,
    required this.date,
    this.totalHabits = 0,
    this.completedHabits = 0,
    this.verifiedHabits = 0,
    this.successRate = 0.0,
    this.streakCount = 0,
    this.isAllProofVerified = false,
  });

  // 🧮 Auto calculate success rate
  void calculateSuccessRate() {
    if (totalHabits == 0) {
      successRate = 0.0;
    } else {
      successRate = (completedHabits / totalHabits) * 100;
    }
    isAllProofVerified = (verifiedHabits == completedHabits) && totalHabits > 0;
  }

  // 🔁 Increment progress metrics
  void incrementCompleted({bool verified = false}) {
    completedHabits++;
    if (verified) verifiedHabits++;
    calculateSuccessRate();
  }

  // 🧱 JSON conversion
  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      totalHabits: json['totalHabits'] ?? 0,
      completedHabits: json['completedHabits'] ?? 0,
      verifiedHabits: json['verifiedHabits'] ?? 0,
      successRate: (json['successRate'] ?? 0).toDouble(),
      streakCount: json['streakCount'] ?? 0,
      isAllProofVerified: json['isAllProofVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'totalHabits': totalHabits,
      'completedHabits': completedHabits,
      'verifiedHabits': verifiedHabits,
      'successRate': successRate,
      'streakCount': streakCount,
      'isAllProofVerified': isAllProofVerified,
    };
  }
}
