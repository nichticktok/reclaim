import 'package:recalim/core/models/project_model.dart';

abstract class ProjectRepository {
  /// Create a new project
  Future<ProjectModel> createProject(ProjectModel project);

  /// Get all projects for a user
  Future<List<ProjectModel>> getUserProjects(String userId);

  /// Get a project by ID
  Future<ProjectModel?> getProjectById(String projectId);

  /// Update a project
  Future<void> updateProject(ProjectModel project);

  /// Delete a project
  Future<void> deleteProject(String projectId);

  /// Create milestones for a project
  Future<void> createMilestones(String projectId, List<MilestoneModel> milestones);

  /// Get milestones for a project
  Future<List<MilestoneModel>> getMilestones(String projectId);

  /// Create tasks for a milestone
  Future<void> createTasks(String milestoneId, List<ProjectTaskModel> tasks);

  /// Get tasks for a milestone
  Future<List<ProjectTaskModel>> getTasks(String milestoneId);

  /// Update a task
  Future<void> updateTask(ProjectTaskModel task);

  /// Get today's tasks from all active projects
  Future<List<ProjectTaskModel>> getTodaysTasks(String userId);
}

