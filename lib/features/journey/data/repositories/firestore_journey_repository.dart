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
      // Get milestone start date (preferred) or fallback to program
      final milestoneDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('milestones')
          .doc('current')
          .get();

      DateTime? startDate;
      int? totalDays;

      if (milestoneDoc.exists) {
        final milestoneData = milestoneDoc.data();
        startDate = (milestoneData?['startDate'] as Timestamp?)?.toDate();
        totalDays = milestoneData?['totalDays'] as int?;
      } else {
        // Fallback to program start date
        final programDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('programs')
            .doc('current')
            .get();

        if (programDoc.exists) {
          final data = programDoc.data();
          startDate = (data?['startDate'] as Timestamp?)?.toDate();
          totalDays = data?['totalDays'] as int?;
        }
      }

      if (startDate == null) {
        return 1; // Default to day 1
      }

      final now = DateTime.now();
      final difference = now.difference(startDate).inDays;
      final maxDays = totalDays ?? 30; // Default to 30 days if not specified
      final currentDay = (difference + 1).clamp(1, maxDays);

      return currentDay;
    } catch (e) {
      throw Exception('Failed to get current day: $e');
    }
  }

  @override
  Future<Map<int, Map<String, dynamic>>> getDayEntries(String userId, List<int> dayNumbers) async {
    try {
      final entries = <int, Map<String, dynamic>>{};
      
      // Batch fetch all day entries
      final batch = <Future<void>>[];
      for (final dayNumber in dayNumbers) {
        batch.add(
          getDayEntry(userId, dayNumber).then((entry) {
            if (entry != null) {
              entries[dayNumber] = entry;
            }
          }),
        );
      }
      
      await Future.wait(batch);
      return entries;
    } catch (e) {
      throw Exception('Failed to fetch day entries: $e');
    }
  }

  @override
  Future<DateTime?> getJourneyStartDate(String userId) async {
    try {
      // Get milestone start date (preferred) or fallback to program
      final milestoneDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('milestones')
          .doc('current')
          .get();

      if (milestoneDoc.exists) {
        final milestoneData = milestoneDoc.data();
        return (milestoneData?['startDate'] as Timestamp?)?.toDate();
      } else {
        // Fallback to program start date
        final programDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('programs')
            .doc('current')
            .get();

        if (programDoc.exists) {
          final data = programDoc.data();
          return (data?['startDate'] as Timestamp?)?.toDate();
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get journey start date: $e');
    }
  }
}

