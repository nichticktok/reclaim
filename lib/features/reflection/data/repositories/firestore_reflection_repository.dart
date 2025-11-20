import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/reflection_repository.dart';

/// Firestore implementation of ReflectionRepository
class FirestoreReflectionRepository implements ReflectionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> saveReflection({
    required String userId,
    required String gratitude,
    required String lesson,
    required String improvement,
  }) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('reflections')
        .doc(todayStr)
        .set({
      'gratitude': gratitude,
      'lesson': lesson,
      'improvement': improvement,
      'date': today.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<Map<String, dynamic>?> getTodayReflection(String userId) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('reflections')
        .doc(todayStr)
        .get();

    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getReflectionHistory(String userId, {int days = 30}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('reflections')
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}

