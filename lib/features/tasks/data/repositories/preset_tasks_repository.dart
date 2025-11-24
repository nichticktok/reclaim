import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:recalim/core/models/preset_task_model.dart';
import 'package:recalim/core/constants/proof_types.dart';

/// Repository for managing preset tasks
class PresetTasksRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all preset tasks
  Future<List<PresetTaskModel>> getPresetTasks() async {
    final snapshot = await _firestore
        .collection('preset_tasks')
        .get();

    // Sort in memory instead of requiring a Firestore index
    final tasks = snapshot.docs
        .map((doc) => PresetTaskModel.fromMap({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
    
    // Sort by category, then by title
    tasks.sort((a, b) {
      final categoryCompare = a.category.compareTo(b.category);
      if (categoryCompare != 0) return categoryCompare;
      return a.title.compareTo(b.title);
    });
    
    return tasks;
  }

  /// Get preset tasks by category
  Future<List<PresetTaskModel>> getPresetTasksByCategory(String category) async {
    final snapshot = await _firestore
        .collection('preset_tasks')
        .where('category', isEqualTo: category)
        .get();

    final tasks = snapshot.docs
        .map((doc) => PresetTaskModel.fromMap({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
    
    // Sort by title in memory
    tasks.sort((a, b) => a.title.compareTo(b.title));
    
    return tasks;
  }

  /// Get preset tasks by proof type (for testing)
  Future<List<PresetTaskModel>> getPresetTasksByProofType(String proofType) async {
    final snapshot = await _firestore
        .collection('preset_tasks')
        .where('proofType', isEqualTo: proofType)
        .get();

    final tasks = snapshot.docs
        .map((doc) => PresetTaskModel.fromMap({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
    
    // Sort by category, then by title
    tasks.sort((a, b) {
      final categoryCompare = a.category.compareTo(b.category);
      if (categoryCompare != 0) return categoryCompare;
      return a.title.compareTo(b.title);
    });
    
    return tasks;
  }

  /// Get all categories (for testing and filtering)
  Future<List<String>> getCategories() async {
    final snapshot = await _firestore
        .collection('preset_tasks')
        .get();

    final categories = snapshot.docs
        .map((doc) => doc.data()['category'] as String? ?? 'General')
        .toSet()
        .toList();
    
    categories.sort();
    return categories;
  }

  /// Get preset task by ID
  Future<PresetTaskModel?> getPresetTaskById(String taskId) async {
    final doc = await _firestore
        .collection('preset_tasks')
        .doc(taskId)
        .get();

    if (!doc.exists) return null;

    return PresetTaskModel.fromMap({
      ...doc.data()!,
      'id': doc.id,
    });
  }

  /// Update a preset task (useful for testing)
  Future<void> updatePresetTask(PresetTaskModel task) async {
    final taskId = task.id.isNotEmpty ? task.id : _generateTaskId(task.title);
    await _firestore
        .collection('preset_tasks')
        .doc(taskId)
        .set(task.copyWith(id: taskId).toMap());
  }

  /// Delete a preset task (for testing/cleanup)
  Future<void> deletePresetTask(String taskId) async {
    await _firestore
        .collection('preset_tasks')
        .doc(taskId)
        .delete();
  }

  /// Clear all preset tasks (for testing only!)
  Future<void> clearAllPresetTasks() async {
    final snapshot = await _firestore
        .collection('preset_tasks')
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    debugPrint('⚠️ Cleared all preset tasks');
  }

  /// Seed preset tasks to Firestore (should be called once)
  /// This will create new tasks and update existing ones if they're missing proofType
  Future<void> seedPresetTasks() async {
    final presetTasks = _getDefaultPresetTasks();
    
    final batch = _firestore.batch();
    int updatesCount = 0;
    int createsCount = 0;
    
    for (var task in presetTasks) {
      // Use a deterministic ID based on title for easier updates
      final taskId = _generateTaskId(task.title);
      final docRef = _firestore.collection('preset_tasks').doc(taskId);
      
      // Check if task already exists
      final existingDoc = await docRef.get();
      
      if (existingDoc.exists) {
        // Update existing task if it's missing proofType or other fields
        final existingData = existingDoc.data()!;
        final hasProofType = existingData.containsKey('proofType') && existingData['proofType'] != null;
        final needsUpdate = !hasProofType || existingData['requiresProof'] != task.requiresProof;
        
        if (needsUpdate) {
          // Merge new data with existing, preserving the ID
          final updatedData = {
            ...existingData,
            ...task.toMap(),
            'id': taskId, // Ensure ID is set
          };
          batch.set(docRef, updatedData, SetOptions(merge: true));
          updatesCount++;
        }
      } else {
        // Create new task
        final taskWithId = task.copyWith(id: taskId);
        batch.set(docRef, taskWithId.toMap());
        createsCount++;
      }
    }
    
    await batch.commit();
    
    if (updatesCount > 0 || createsCount > 0) {
      debugPrint('✅ Seeded preset tasks: $createsCount created, $updatesCount updated');
    }
  }
  
  /// Generate a deterministic ID from task title
  /// Converts "Practice a new skill" -> "practice_a_new_skill"
  String _generateTaskId(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscore
        .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with single
        .replaceAll(RegExp(r'^_|_$'), ''); // Remove leading/trailing underscores
  }

  /// Get the 25 default preset tasks
  List<PresetTaskModel> _getDefaultPresetTasks() {
    return [
      // Health & Fitness
      PresetTaskModel(
        id: '',
        title: 'Wake up at 7 AM',
        description: 'Start your day early and energized',
        category: 'Health',
        requiresProof: false,
        attribute: 'Discipline',
      ),
      PresetTaskModel(
        id: '',
        title: 'Drink 2 L water',
        description: 'Stay hydrated throughout the day',
        category: 'Health',
        requiresProof: false,
        attribute: 'Discipline',
      ),
      PresetTaskModel(
        id: '',
        title: 'Take a cold shower',
        description: 'Build mental resilience and boost energy',
        category: 'Health',
        requiresProof: true,
        proofType: 'photo',
        attribute: 'Strength',
      ),
      PresetTaskModel(
        id: '',
        title: 'Stretch for 10 minutes',
        description: 'Improve flexibility and reduce tension',
        category: 'Health',
        requiresProof: false,
        attribute: 'Discipline',
      ),
      PresetTaskModel(
        id: '',
        title: 'Eat a healthy breakfast',
        description: 'Fuel your body with nutritious food',
        category: 'Health',
        requiresProof: false,
        attribute: 'Discipline',
      ),
      
      // Mindfulness & Mental Health
      PresetTaskModel(
        id: '',
        title: 'Meditate for 5 minutes',
        description: 'The noble minds are calm, steady',
        category: 'Mindfulness',
        requiresProof: false,
        attribute: 'Focus',
      ),
      PresetTaskModel(
        id: '',
        title: 'Practice gratitude',
        description: 'Write down 3 things you\'re grateful for',
        category: 'Mindfulness',
        requiresProof: true,
        proofType: ProofTypes.text,
        attribute: 'Wisdom',
      ),
      PresetTaskModel(
        id: '',
        title: 'Deep breathing exercise',
        description: '5 minutes of focused breathing',
        category: 'Mindfulness',
        requiresProof: false,
        attribute: 'Focus',
      ),
      PresetTaskModel(
        id: '',
        title: 'Journal for 10 minutes',
        description: 'Reflect on your day and thoughts',
        category: 'Mindfulness',
        requiresProof: true,
        proofType: ProofTypes.text,
        attribute: 'Wisdom',
      ),
      
      // Productivity & Learning
      PresetTaskModel(
        id: '',
        title: 'Read for 30 minutes',
        description: 'Expand your knowledge and perspective',
        category: 'Productivity',
        requiresProof: true,
        proofType: ProofTypes.text,
        attribute: 'Wisdom',
      ),
      PresetTaskModel(
        id: '',
        title: 'Learn something new',
        description: 'Watch a tutorial or take an online course',
        category: 'Productivity',
        requiresProof: true,
        proofType: ProofTypes.video,
        attribute: 'Wisdom',
      ),
      PresetTaskModel(
        id: '',
        title: 'Plan your day',
        description: 'Set priorities and goals for the day',
        category: 'Productivity',
        requiresProof: false,
        attribute: 'Focus',
      ),
      PresetTaskModel(
        id: '',
        title: 'Review your goals',
        description: 'Check progress on your long-term goals',
        category: 'Productivity',
        requiresProof: false,
        attribute: 'Focus',
      ),
      PresetTaskModel(
        id: '',
        title: 'Complete one important task',
        description: 'Tackle your most important task of the day',
        category: 'Productivity',
        requiresProof: true,
        proofType: ProofTypes.file,
        attribute: 'Focus',
      ),
      
      // Social & Relationships
      PresetTaskModel(
        id: '',
        title: 'Call a friend or family member',
        description: 'Maintain meaningful connections',
        category: 'Social',
        requiresProof: false,
        attribute: 'Confidence',
      ),
      PresetTaskModel(
        id: '',
        title: 'Help someone',
        description: 'Do a kind act for someone else',
        category: 'Social',
        requiresProof: false,
        attribute: 'Confidence',
      ),
      
      // Digital Wellness
      PresetTaskModel(
        id: '',
        title: 'Limit social media to 30 minutes',
        description: 'Reduce screen time and distractions',
        category: 'Digital Wellness',
        requiresProof: true,
        proofType: ProofTypes.photo,
        attribute: 'Discipline',
      ),
      PresetTaskModel(
        id: '',
        title: 'No phone for 1 hour before bed',
        description: 'Improve sleep quality',
        category: 'Digital Wellness',
        requiresProof: false,
        attribute: 'Discipline',
      ),
      PresetTaskModel(
        id: '',
        title: 'Digital detox hour',
        description: 'Spend an hour without any devices',
        category: 'Digital Wellness',
        requiresProof: true,
        proofType: ProofTypes.text,
        attribute: 'Discipline',
      ),
      
      // Personal Development
      PresetTaskModel(
        id: '',
        title: 'Journal for 15 minutes',
        description: 'Document your thoughts, experiences, and reflections',
        category: 'Personal Development',
        requiresProof: true,
        proofType: ProofTypes.text,
        attribute: 'Wisdom',
      ),
      PresetTaskModel(
        id: '',
        title: 'Set intentions for the day',
        description: 'Plan what you want to achieve and focus on today',
        category: 'Personal Development',
        requiresProof: false,
        attribute: 'Focus',
      ),
      PresetTaskModel(
        id: '',
        title: 'Watch a skill development video',
        description: 'Learn from a tutorial, course, or educational video',
        category: 'Personal Development',
        requiresProof: true,
        proofType: ProofTypes.video,
        attribute: 'Wisdom',
      ),
      PresetTaskModel(
        id: '',
        title: 'Complete a small course lesson',
        description: 'Work through one lesson from an online course',
        category: 'Personal Development',
        requiresProof: true,
        proofType: ProofTypes.file,
        attribute: 'Wisdom',
      ),
      PresetTaskModel(
        id: '',
        title: 'Practice a new skill',
        description: 'Dedicate time to actively practice and improve a skill',
        category: 'Personal Development',
        requiresProof: true,
        proofType: ProofTypes.video,
        attribute: 'Wisdom',
      ),
      PresetTaskModel(
        id: '',
        title: 'Read an article or blog post',
        description: 'Learn something new from an educational article',
        category: 'Personal Development',
        requiresProof: true,
        proofType: ProofTypes.text,
        attribute: 'Wisdom',
      ),
      
      // Self-Care
      PresetTaskModel(
        id: '',
        title: 'Take a walk outside',
        description: 'Get fresh air and enjoy nature',
        category: 'Self-Care',
        requiresProof: true,
        proofType: ProofTypes.location,
        attribute: 'Discipline',
      ),
      PresetTaskModel(
        id: '',
        title: 'Do something creative',
        description: 'Express yourself through art or music',
        category: 'Self-Care',
        requiresProof: true,
        proofType: ProofTypes.photo,
        attribute: 'Confidence',
      ),
      PresetTaskModel(
        id: '',
        title: 'Get 8 hours of sleep',
        description: 'Prioritize rest and recovery',
        category: 'Self-Care',
        requiresProof: false,
        attribute: 'Discipline',
      ),
    ];
  }
}

