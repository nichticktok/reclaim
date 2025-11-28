import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category; // learning, fitness, room_remodel, finance, creative, etc.
  final DateTime startDate;
  final DateTime endDate;
  final double hoursPerDay;
  final double? hoursPerWeek; // Optional, for weekend-only projects
  final DateTime createdAt;
  final String status; // active, completed, paused
  final List<MilestoneModel> milestones;

  ProjectModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.hoursPerDay,
    this.hoursPerWeek,
    DateTime? createdAt,
    this.status = 'active',
    this.milestones = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'hoursPerDay': hoursPerDay,
      if (hoursPerWeek != null) 'hoursPerWeek': hoursPerWeek,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'general',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hoursPerDay: (map['hoursPerDay'] ?? 1.0).toDouble(),
      hoursPerWeek: map['hoursPerWeek']?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
    );
  }

  ProjectModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? hoursPerDay,
    double? hoursPerWeek,
    DateTime? createdAt,
    String? status,
    List<MilestoneModel>? milestones,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      milestones: milestones ?? this.milestones,
    );
  }

  int get totalDays => endDate.difference(startDate).inDays;
  double get totalAvailableHours => totalDays * hoursPerDay;
  double get progressPercentage {
    if (milestones.isEmpty) return 0.0;
    final completedTasks = milestones
        .expand((m) => m.tasks)
        .where((t) => t.status == 'done')
        .length;
    final totalTasks = milestones.expand((m) => m.tasks).length;
    return totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  }
}

class MilestoneModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final int order;
  final DateTime startDate;
  final DateTime endDate;
  final List<ProjectTaskModel> tasks;

  MilestoneModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.order,
    required this.startDate,
    required this.endDate,
    this.tasks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'order': order,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    };
  }

  factory MilestoneModel.fromMap(Map<String, dynamic> map, String id) {
    return MilestoneModel(
      id: id,
      projectId: map['projectId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      order: map['order'] ?? 0,
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MilestoneModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    int? order,
    DateTime? startDate,
    DateTime? endDate,
    List<ProjectTaskModel>? tasks,
  }) {
    return MilestoneModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tasks: tasks ?? this.tasks,
    );
  }

  double get progressPercentage {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.status == 'done').length;
    return completed / tasks.length;
  }
}

class ProjectTaskModel {
  final String id;
  final String milestoneId;
  final String title;
  final String description;
  final double estimatedHours;
  final DateTime? dueDate;
  final String status; // pending, in_progress, done
  final DateTime? completedAt;
  final String? suggestedProofType; // AI-suggested primary proof type
  final List<String> alternativeProofTypes; // AI-suggested alternatives
  final String? proofMechanism; // Mechanism type (study_session, work_session, practice, etc.)
  final Map<String, String> proofs; // Proof submissions per date (YYYY-MM-DD format)
  final bool requiresProof; // Whether proof is required for this task
  final bool requiresPeerApproval; // Whether peer approval is needed (for high-stakes tasks)

  ProjectTaskModel({
    required this.id,
    required this.milestoneId,
    required this.title,
    required this.description,
    required this.estimatedHours,
    this.dueDate,
    this.status = 'pending',
    this.completedAt,
    this.suggestedProofType,
    this.alternativeProofTypes = const [],
    this.proofMechanism,
    Map<String, String>? proofs,
    this.requiresProof = true,
    this.requiresPeerApproval = false,
  }) : proofs = proofs ?? {};

  Map<String, dynamic> toMap() {
    return {
      'milestoneId': milestoneId,
      'title': title,
      'description': description,
      'estimatedHours': estimatedHours,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      'status': status,
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (suggestedProofType != null) 'suggestedProofType': suggestedProofType,
      'alternativeProofTypes': alternativeProofTypes,
      if (proofMechanism != null) 'proofMechanism': proofMechanism,
      'proofs': proofs,
      'requiresProof': requiresProof,
      'requiresPeerApproval': requiresPeerApproval,
    };
  }

  factory ProjectTaskModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectTaskModel(
      id: id,
      milestoneId: map['milestoneId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      estimatedHours: (map['estimatedHours'] ?? 0.0).toDouble(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'pending',
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      suggestedProofType: map['suggestedProofType'] as String?,
      alternativeProofTypes: map['alternativeProofTypes'] != null
          ? List<String>.from(map['alternativeProofTypes'])
          : [],
      proofMechanism: map['proofMechanism'] as String?,
      proofs: map['proofs'] != null
          ? Map<String, String>.from(map['proofs'])
          : {},
      requiresProof: map['requiresProof'] ?? true,
      requiresPeerApproval: map['requiresPeerApproval'] ?? false,
    );
  }

  ProjectTaskModel copyWith({
    String? id,
    String? milestoneId,
    String? title,
    String? description,
    double? estimatedHours,
    DateTime? dueDate,
    String? status,
    DateTime? completedAt,
    String? suggestedProofType,
    List<String>? alternativeProofTypes,
    String? proofMechanism,
    Map<String, String>? proofs,
    bool? requiresProof,
    bool? requiresPeerApproval,
  }) {
    return ProjectTaskModel(
      id: id ?? this.id,
      milestoneId: milestoneId ?? this.milestoneId,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      suggestedProofType: suggestedProofType ?? this.suggestedProofType,
      alternativeProofTypes: alternativeProofTypes ?? this.alternativeProofTypes,
      proofMechanism: proofMechanism ?? this.proofMechanism,
      proofs: proofs ?? this.proofs,
      requiresProof: requiresProof ?? this.requiresProof,
      requiresPeerApproval: requiresPeerApproval ?? this.requiresPeerApproval,
    );
  }

  bool get isOverdue {
    if (dueDate == null || status == 'done') return false;
    return DateTime.now().isAfter(dueDate!);
  }
}

