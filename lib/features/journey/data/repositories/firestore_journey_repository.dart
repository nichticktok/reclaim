import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/journey_repository.dart';

/// Firestore implementation of JourneyRepository
/// Firestore operations for journey/reflection
class FirestoreJourneyRepository implements JourneyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>?> getDayEntry(String userId, int dayNumber) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journey')
          .doc('day_$dayNumber')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch day entry: $e');
    }
  }

  @override
  Future<void> saveMood(String userId, int dayNumber, String mood) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journey')
          .doc('day_$dayNumber')
          .set({
        'mood': mood,
        'dayNumber': dayNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save mood: $e');
    }
  }

  @override
  Future<void> saveJournalEntry(String userId, int dayNumber, String entry) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journey')
          .doc('day_$dayNumber')
          .set({
        'journalEntry': entry,
        'dayNumber': dayNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save journal entry: $e');
    }
  }

  @override
  Future<int> getCurrentDay(String userId) async {
    try {
      // Get program start date
      final programDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc('current')
          .get();

      if (!programDoc.exists) {
        return 1; // Default to day 1 if no program
      }

      final data = programDoc.data();
      final startDate = (data?['startDate'] as Timestamp?)?.toDate();
      
      if (startDate == null) {
        return 1;
      }

      final now = DateTime.now();
      final difference = now.difference(startDate).inDays;
      final currentDay = (difference + 1).clamp(1, 66); // Clamp between 1 and 66

      // Update current day in program
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc('current')
          .update({
        'currentDay': currentDay,
      });

      return currentDay;
    } catch (e) {
      throw Exception('Failed to get current day: $e');
    }
  }
}

