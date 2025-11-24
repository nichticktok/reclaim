import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/project_model.dart';
import '../../domain/repositories/project_repository.dart';

class FirestoreProjectRepository implements ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<ProjectModel> createProject(ProjectModel project) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .add(project.toMap());

    return project.copyWith(id: docRef.id);
  }

  @override
  Future<List<ProjectModel>> getUserProjects(String userId) async {
    final projectsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .orderBy('createdAt', descending: true)
        .get();

    final projects = <ProjectModel>[];
    for (var doc in projectsSnapshot.docs) {
      final project = ProjectModel.fromMap(doc.data(), doc.id);
      // Load milestones and tasks
      final milestones = await getMilestones(project.id);
      final projectWithMilestones = project.copyWith(milestones: milestones);
      projects.add(projectWithMilestones);
    }

    return projects;
  }

  @override
  Future<ProjectModel?> getProjectById(String projectId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId)
        .get();

    if (!doc.exists) return null;

    final project = ProjectModel.fromMap(doc.data()!, doc.id);
    final milestones = await getMilestones(project.id);
    return project.copyWith(milestones: milestones);
  }

  @override
  Future<void> updateProject(ProjectModel project) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(project.id)
        .update(project.toMap());
  }

  @override
  Future<void> deleteProject(String projectId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Delete milestones and tasks first
    final milestones = await getMilestones(projectId);
    for (var milestone in milestones) {
      final tasks = await getTasks(milestone.id);
      for (var task in tasks) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('projects')
            .doc(projectId)
            .collection('milestones')
            .doc(milestone.id)
            .collection('tasks')
            .doc(task.id)
            .delete();
      }
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestone.id)
          .delete();
    }

    // Delete project
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId)
        .delete();
  }

  @override
  Future<void> createMilestones(String projectId, List<MilestoneModel> milestones) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final batch = _firestore.batch();
    for (var milestone in milestones) {
      final milestoneRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc();
      
      batch.set(milestoneRef, milestone.copyWith(id: milestoneRef.id).toMap());

      // Create tasks for this milestone
      for (var task in milestone.tasks) {
        final taskRef = milestoneRef.collection('tasks').doc();
        final taskWithId = ProjectTaskModel(
          id: taskRef.id,
          milestoneId: milestoneRef.id,
          title: task.title,
          description: task.description,
          estimatedHours: task.estimatedHours,
          dueDate: task.dueDate,
          status: task.status,
          completedAt: task.completedAt,
        );
        batch.set(taskRef, taskWithId.toMap());
      }
    }

    await batch.commit();
  }

  @override
  Future<List<MilestoneModel>> getMilestones(String projectId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final milestonesSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId)
        .collection('milestones')
        .orderBy('order')
        .get();

    final milestones = <MilestoneModel>[];
    for (var doc in milestonesSnapshot.docs) {
      final milestone = MilestoneModel.fromMap(doc.data(), doc.id);
      final tasks = await getTasks(milestone.id);
      milestones.add(milestone.copyWith(tasks: tasks));
    }

    return milestones;
  }


  @override
  Future<void> createTasks(String milestoneId, List<ProjectTaskModel> tasks) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the project and milestone to get the correct path
    final projectsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();

    for (var projectDoc in projectsSnapshot.docs) {
      final milestoneDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(projectDoc.id)
          .collection('milestones')
          .doc(milestoneId)
          .get();

      if (milestoneDoc.exists) {
        final batch = _firestore.batch();
        for (var task in tasks) {
          final taskRef = milestoneDoc.reference.collection('tasks').doc();
          batch.set(taskRef, task.copyWith(id: taskRef.id).toMap());
        }
        await batch.commit();
        return;
      }
    }
  }

  @override
  Future<List<ProjectTaskModel>> getTasks(String milestoneId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the milestone
    final projectsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();

    for (var projectDoc in projectsSnapshot.docs) {
      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(projectDoc.id)
          .collection('milestones')
          .doc(milestoneId)
          .collection('tasks')
          .get();

      if (tasksSnapshot.docs.isNotEmpty) {
        return tasksSnapshot.docs
            .map((doc) => ProjectTaskModel.fromMap(doc.data(), doc.id))
            .toList();
      }
    }

    return [];
  }

  @override
  Future<void> updateTask(ProjectTaskModel task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the task
    final projectsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();

    for (var projectDoc in projectsSnapshot.docs) {
      final milestonesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(projectDoc.id)
          .collection('milestones')
          .get();

      for (var milestoneDoc in milestonesSnapshot.docs) {
        final taskDoc = await milestoneDoc.reference
            .collection('tasks')
            .doc(task.id)
            .get();

        if (taskDoc.exists) {
          await taskDoc.reference.update(task.toMap());
          return;
        }
      }
    }
  }

  @override
  Future<List<ProjectTaskModel>> getTodaysTasks(String userId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final projects = await getUserProjects(userId);
    final allTasks = <ProjectTaskModel>[];

    for (var project in projects) {
      if (project.status != 'active') continue;

      for (var milestone in project.milestones) {
        for (var task in milestone.tasks) {
          if (task.dueDate != null &&
              task.dueDate!.isAfter(todayStart) &&
              task.dueDate!.isBefore(todayEnd) &&
              task.status != 'done') {
            allTasks.add(task);
          }
        }
      }
    }

    return allTasks;
  }
}

