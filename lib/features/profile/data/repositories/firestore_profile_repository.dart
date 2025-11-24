import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';

/// Firestore implementation of ProfileRepository
class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    
    if (!doc.exists) {
      throw Exception('User profile not found');
    }

    final data = doc.data()!;
    final user = FirebaseAuth.instance.currentUser;

    return UserModel(
      id: userId,
      name: (data['name'] ?? user?.displayName ?? 'User') as String,
      email: (data['email'] ?? user?.email ?? '') as String,
      goal: (data['goal'] ?? '') as String,
      proofMode: (data['proofMode'] ?? false) as bool,
      level: (data['level'] ?? 1) as int,
      streak: (data['streak'] ?? 0) as int,
      isPremium: (data['isPremium'] ?? false) as bool,
    );
  }

  @override
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    if (updates.isEmpty) return;

    await _firestore.collection('users').doc(userId).update(updates);
  }

  @override
  Future<void> updateProfileField(String userId, String field, dynamic value) async {
    await _firestore.collection('users').doc(userId).update({field: value});
  }
}

