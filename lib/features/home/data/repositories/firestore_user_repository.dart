import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';

/// Firestore implementation of UserRepository
class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<UserModel> getUser(String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Ensure document exists
    await ensureUserDocument(userId, {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'goal': '',
      'proofMode': false,
      'level': 1,
      'streak': 0,
      'isPremium': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    });

    // Load user data
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data() ?? {};

    return UserModel(
      id: user.uid,
      name: (data['name'] ?? user.displayName ?? 'User') as String,
      email: (data['email'] ?? user.email ?? '') as String,
      goal: (data['goal'] ?? '') as String,
      proofMode: (data['proofMode'] ?? false) as bool,
      level: (data['level'] ?? 1) as int,
      streak: (data['streak'] ?? 0) as int,
      isPremium: (data['isPremium'] ?? false) as bool,
    );
  }

  @override
  Future<void> ensureUserDocument(String userId, Map<String, dynamic> userData) async {
    final userRef = _firestore.collection('users').doc(userId);
    final snap = await userRef.get();
    
    if (!snap.exists) {
      await userRef.set({
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // Update existing document
      final updateData = <String, dynamic>{
        'lastSeen': FieldValue.serverTimestamp(),
      };
      updateData.addAll(userData);
      await userRef.update(updateData);
    }
  }

  @override
  Future<void> updateLastSeen(String userId) async {
    await _firestore.collection('users').doc(userId).set({
      'lastSeen': FieldValue.serverTimestamp()
    }, SetOptions(merge: true));
  }
}

