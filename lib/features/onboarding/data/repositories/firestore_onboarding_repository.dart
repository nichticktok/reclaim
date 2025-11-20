import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// Firestore implementation of OnboardingRepository
class FirestoreOnboardingRepository implements OnboardingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>?> getOnboardingProgress(String userId) async {
    // Try to get from subcollection first (new structure)
    final onboardingDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('onboarding')
        .doc('data')
        .get();
    
    // Get user document for flags
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      // Create initial user document
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'onboardingStep': 0,
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return {'onboardingStep': 0, 'onboardingCompleted': false};
    }

    final userData = userDoc.data() ?? {};
    
    // If onboarding data exists in subcollection, use it
    if (onboardingDoc.exists) {
      final onboardingData = onboardingDoc.data() ?? {};
      return {
        'onboardingStep': userData['onboardingStep'] ?? onboardingData['onboardingStep'] ?? 0,
        'onboardingCompleted': userData['onboardingCompleted'] ?? false,
        'onboardingData': onboardingData,
      };
    }
    
    // Fallback: Check old structure (backward compatibility)
    final oldOnboardingData = userData['onboardingData'] as Map<String, dynamic>?;
    if (oldOnboardingData != null) {
      // Migrate old data to new structure
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('onboarding')
          .doc('data')
          .set({
        ...oldOnboardingData,
        'migratedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return {
        'onboardingStep': userData['onboardingStep'] ?? 0,
        'onboardingCompleted': userData['onboardingCompleted'] ?? false,
        'onboardingData': oldOnboardingData,
      };
    }
    
    return {
      'onboardingStep': userData['onboardingStep'] ?? 0,
      'onboardingCompleted': userData['onboardingCompleted'] ?? false,
      'onboardingData': {},
    };
  }

  @override
  Future<void> saveOnboardingProgress(String userId, int step, Map<String, dynamic> data) async {
    // Save onboarding data to subcollection (better structure)
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('onboarding')
        .doc('data')
        .set({
      ...data,
      'onboardingStep': step,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // Update main user document with flags only (lightweight)
    await _firestore.collection('users').doc(userId).set({
      'onboardingStep': step,
      'onboardingCompleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> markOnboardingCompleted(String userId) async {
    // Update onboarding data with completion timestamp
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('onboarding')
        .doc('data')
        .set({
      'completedAt': FieldValue.serverTimestamp(),
      'onboardingCompleted': true,
    }, SetOptions(merge: true));
    
    // Update main user document flag (lightweight)
    await _firestore.collection('users').doc(userId).set({
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> isOnboardingCompleted(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;
    
    final data = doc.data() ?? {};
    return data['onboardingCompleted'] ?? false;
  }
}

