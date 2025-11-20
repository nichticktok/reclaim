import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/preset_task_model.dart';

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

  /// Seed preset tasks to Firestore (should be called once)
  Future<void> seedPresetTasks() async {
    final presetTasks = _getDefaultPresetTasks();
    
    final batch = _firestore.batch();
    for (var task in presetTasks) {
      // Check if task already exists
      final existing = await _firestore
          .collection('preset_tasks')
          .where('title', isEqualTo: task.title)
          .limit(1)
          .get();
      
      if (existing.docs.isEmpty) {
        final docRef = _firestore.collection('preset_tasks').doc();
        batch.set(docRef, task.toMap());
      }
    }
    
    await batch.commit();
  }

  /// Get the 25 default preset tasks
  List<PresetTaskModel> _getDefaultPresetTasks() {
    return [
      // Health & Fitness
      PresetTaskModel(
        id: '',
        title: 'Wake up at 7 AM',
        description: 'Start your day early and energized',
        scheduledTime: '7:00 AM',
        category: 'Health',
        requiresProof: false,
      ),
      PresetTaskModel(
        id: '',
        title: 'Drink 2 L water',
        description: 'Stay hydrated throughout the day',
        scheduledTime: '8:00 AM',
        category: 'Health',
        requiresProof: false,
      ),
      PresetTaskModel(
        id: '',
        title: 'Workout for 15 minutes',
        description: 'Physical activity for health and strength',
        scheduledTime: '6:00 PM',
        category: 'Health',
        requiresProof: true,
      ),
      PresetTaskModel(
        id: '',
        title: 'Take a cold shower',
        description: 'Build mental resilience and boost energy',
        scheduledTime: '7:00 AM',
        category: 'Health',
        requiresProof: true,
      ),
      PresetTaskModel(
        id: '',
        title: 'Eat a healthy breakfast',
        description: 'Fuel your body with nutritious food',
        scheduledTime: '8:30 AM',
        category: 'Health',
        requiresProof: false,
      ),
      
      // Mindfulness & Mental Health
      PresetTaskModel(
        id: '',
        title: 'Meditate for 5 minutes',
        description: 'The noble minds are calm, steady',
        scheduledTime: '7:00 AM',
        category: 'Mindfulness',
        requiresProof: false,
      ),
      PresetTaskModel(
        id: '',
        title: 'Practice gratitude',
        description: 'Write down 3 things you\'re grateful for',
        scheduledTime: '9:00 PM',
        category: 'Mindfulness',
        requiresProof: true,
      ),
      PresetTaskModel(
        id: '',
        title: 'Deep breathing exercise',
        description: '5 minutes of focused breathing',
        scheduledTime: '12:00 PM',
        category: 'Mindfulness',
        requiresProof: false,
      ),
      PresetTaskModel(
        id: '',
        title: 'Journal for 10 minutes',
        description: 'Reflect on your day and thoughts',
        scheduledTime: '9:00 PM',
        category: 'Mindfulness',
        requiresProof: true,
      ),
      
      // Productivity & Learning
      PresetTaskModel(
        id: '',
        title: 'Read for 30 minutes',
        description: 'Expand your knowledge and perspective',
        scheduledTime: '9:00 PM',
        category: 'Productivity',
        requiresProof: true,
      ),
      PresetTaskModel(
        id: '',
        title: 'Learn something new',
        description: 'Watch a tutorial or take an online course',
        scheduledTime: '7:00 PM',
        category: 'Productivity',
        requiresProof: true,
      ),
      PresetTaskModel(
        id: '',
        title: 'Plan your day',
        description: 'Set priorities and goals for the day',
        scheduledTime: '7:30 AM',
        category: 'Productivity',
        requiresProof: false,
      ),
      PresetTaskModel(
        id: '',
        title: 'Review your goals',
        description: 'Check progress on your long-term goals',
        scheduledTime: '8:00 PM',
        category: 'Productivity',
        requiresProof: false,
      ),
      PresetTaskModel(
        id: '',
        title: 'Complete one important task',
        description: 'Tackle your most important task of the day',
        scheduledTime: '10:00 AM',
        category: 'Productivity',
        requiresProof: true,
      ),
      
      // Social & Relationships
      PresetTaskModel(
        id: '',
        title: 'Call a friend or family member',
        description: 'Maintain meaningful connections',
        scheduledTime: '6:00 PM',
        category: 'Social',
        requiresProof: false,
      ),
      PresetTaskModel(
        id: '',
        title: 'Help someone',
        description: 'Do a kind act for someone else',
        scheduledTime: '2:00 PM',
        category: 'Social',
        requiresProof: false,
      ),
      
      // Digital Wellness
      PresetTaskModel(
        id: '',
        title: 'Limit social media to 30 minutes',
        description: 'Reduce screen time and distractions',
        scheduledTime: '8:00 PM',
        category: 'Digital Wellness',
        requiresProof: true,
      ),
      PresetTaskModel(
        id: '',
        title: 'No phone for 1 hour before bed',
        description: 'Improve sleep quality',
        scheduledTime: '9:00 PM',
        category: 'Digital Wellness',
        requiresProof: false,
      ),
      PresetTaskModel(
        id: '',
        title: 'Digital detox hour',
        description: 'Spend an hour without any devices',
        scheduledTime: '5:00 PM',
        category: 'Digital Wellness',
        requiresProof: true,
      ),
      
      // Personal Development
      PresetTaskModel(
        id: '',
        title: 'Practice a skill',
        description: 'Work on improving a specific skill',
        scheduledTime: '4:00 PM',
        category: 'Personal Development',
        requiresProof: true,
      ),
      PresetTaskModel(
        id: '',
        title: 'Write in a journal',
        description: 'Document your thoughts and experiences',
        scheduledTime: '9:00 PM',
        category: 'Personal Development',
        requiresProof: true,
      ),
      PresetTaskModel(
        id: '',
        title: 'Set tomorrow\'s intentions',
        description: 'Plan what you want to achieve tomorrow',
        scheduledTime: '9:30 PM',
        category: 'Personal Development',
        requiresProof: false,
      ),
      
      // Self-Care
      PresetTaskModel(
        id: '',
        title: 'Take a walk outside',
        description: 'Get fresh air and light exercise',
        scheduledTime: '6:00 PM',
        category: 'Self-Care',
        requiresProof: false,
      ),
      PresetTaskModel(
        id: '',
        title: 'Do something creative',
        description: 'Express yourself through art or music',
        scheduledTime: '3:00 PM',
        category: 'Self-Care',
        requiresProof: true,
      ),
      PresetTaskModel(
        id: '',
        title: 'Get 8 hours of sleep',
        description: 'Prioritize rest and recovery',
        scheduledTime: '10:00 PM',
        category: 'Self-Care',
        requiresProof: false,
      ),
    ];
  }
}

