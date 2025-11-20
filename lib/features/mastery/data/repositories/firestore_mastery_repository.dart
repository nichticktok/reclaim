import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/mastery_repository.dart';

/// Firestore implementation of MasteryRepository
/// Firestore operations for mastery system
class FirestoreMasteryRepository implements MasteryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _ranks = [
    'Bronze V', 'Bronze IV', 'Bronze III', 'Bronze II', 'Bronze I',
    'Silver V', 'Silver IV', 'Silver III', 'Silver II', 'Silver I',
    'Gold V', 'Gold IV', 'Gold III', 'Gold II', 'Gold I',
    'Platinum V', 'Platinum IV', 'Platinum III', 'Platinum II', 'Platinum I',
    'Diamond V', 'Diamond IV', 'Diamond III', 'Diamond II', 'Diamond I',
    'Legend V', 'Legend IV', 'Legend III', 'Legend II', 'Legend I',
  ];

  int _getRequiredXPForRank(int rankIndex) {
    return 1000 + (rankIndex * 500); // Progressive XP requirement
  }

  @override
  Future<Map<String, dynamic>> getMasteryData(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mastery')
          .doc('data')
          .get();

      if (doc.exists) {
        return doc.data()!;
      }

      // Initialize mastery data if it doesn't exist
      final initialData = {
        'rank': 'Bronze V',
        'xp': 0,
        'level': 1,
        'totalXP': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mastery')
          .doc('data')
          .set(initialData);

      return initialData;
    } catch (e) {
      throw Exception('Failed to fetch mastery data: $e');
    }
  }

  @override
  Future<void> addXP(String userId, int amount) async {
    try {
      final masteryRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('mastery')
          .doc('data');

      final doc = await masteryRef.get();
      final currentData = doc.exists ? doc.data()! : {};
      final currentXP = (currentData['xp'] ?? 0) as int;
      final totalXP = (currentData['totalXP'] ?? 0) as int;
      final currentRank = (currentData['rank'] ?? 'Bronze V') as String;
      final rankIndex = _ranks.indexOf(currentRank);

      final newXP = currentXP + amount;
      final newTotalXP = totalXP + amount;
      final requiredXP = _getRequiredXPForRank(rankIndex);

      String newRank = currentRank;
      int newLevel = (currentData['level'] ?? 1) as int;

      // Check for rank up
      if (newXP >= requiredXP && rankIndex < _ranks.length - 1) {
        newRank = _ranks[rankIndex + 1];
        newLevel++;
      }

      await masteryRef.set({
        'rank': newRank,
        'xp': newXP >= requiredXP ? newXP - requiredXP : newXP,
        'level': newLevel,
        'totalXP': newTotalXP,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add XP: $e');
    }
  }

  @override
  Future<String> getCurrentRank(String userId) async {
    try {
      final data = await getMasteryData(userId);
      return (data['rank'] ?? 'Bronze V') as String;
    } catch (e) {
      throw Exception('Failed to get current rank: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mastery')
          .doc('data')
          .collection('achievements')
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch achievements: $e');
    }
  }
}

