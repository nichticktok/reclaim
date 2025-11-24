import 'package:cloud_firestore/cloud_firestore.dart';

/// Plan Model for Firestore plans collection
/// Stores AI-generated daily project plans
class PlanModel {
  final String id;
  final String userId;
  final String projectTitle;
  final String description;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final double hoursPerDay;
  final List<DailyPlan> dailyPlans;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? deletionStatus; // null, "pending", "deleted"

  PlanModel({
    required this.id,
    required this.userId,
    required this.projectTitle,
    required this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.hoursPerDay,
    required this.dailyPlans,
    required this.createdAt,
    this.updatedAt,
    this.deletionStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'projectTitle': projectTitle,
      'description': description,
      'category': category,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'hoursPerDay': hoursPerDay,
      'dailyPlans': dailyPlans.map((plan) => plan.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (deletionStatus != null) 'deletionStatus': deletionStatus,
    };
  }

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      projectTitle: map['projectTitle'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hoursPerDay: (map['hoursPerDay'] ?? 1.0).toDouble(),
      dailyPlans: (map['dailyPlans'] as List<dynamic>?)
              ?.map((e) => DailyPlan.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      deletionStatus: map['deletionStatus'] as String?,
    );
  }

  PlanModel copyWith({
    String? id,
    String? userId,
    String? projectTitle,
    String? description,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? hoursPerDay,
    List<DailyPlan>? dailyPlans,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deletionStatus,
  }) {
    return PlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectTitle: projectTitle ?? this.projectTitle,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      dailyPlans: dailyPlans ?? this.dailyPlans,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletionStatus: deletionStatus ?? this.deletionStatus,
    );
  }
}

/// Daily plan entry - what to do on a specific date
class DailyPlan {
  final DateTime date;
  final List<DailyTask> tasks;
  final double totalHours;
  final String? notes;

  DailyPlan({
    required this.date,
    required this.tasks,
    required this.totalHours,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'totalHours': totalHours,
      if (notes != null) 'notes': notes,
    };
  }

  factory DailyPlan.fromMap(Map<String, dynamic> map) {
    return DailyPlan(
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tasks: (map['tasks'] as List<dynamic>?)
              ?.map((e) => DailyTask.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalHours: (map['totalHours'] ?? 0.0).toDouble(),
      notes: map['notes'] as String?,
    );
  }
}

/// Task to be completed on a specific day
class DailyTask {
  final String title;
  final String description;
  final double estimatedHours;
  final int order;
  final String? phase;

  DailyTask({
    required this.title,
    required this.description,
    required this.estimatedHours,
    required this.order,
    this.phase,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'estimatedHours': estimatedHours,
      'order': order,
      if (phase != null) 'phase': phase,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      estimatedHours: (map['estimatedHours'] ?? 0.0).toDouble(),
      order: map['order'] ?? 0,
      phase: map['phase'] as String?,
    );
  }
}

