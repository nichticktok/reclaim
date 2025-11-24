import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:recalim/core/models/proof_submission_model.dart';
import '../../domain/repositories/proof_repository.dart';

/// Firestore implementation of ProofRepository
class FirestoreProofRepository implements ProofRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<ProofSubmission> submitProof(
    String habitId,
    ProofSubmission proof,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    if (!proof.isValid()) {
      throw Exception('Proof submission is not valid for its type');
    }

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('proofs')
        .doc();

    final proofWithId = proof.copyWith(id: docRef.id);
    await docRef.set(proofWithId.toMap());

    return proofWithId;
  }

  @override
  Future<List<ProofSubmission>> getProofsForHabit(String habitId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('proofs')
        .where('habitId', isEqualTo: habitId)
        .orderBy('submittedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProofSubmission.fromMap({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
  }

  @override
  Future<ProofSubmission?> getProofForDate(
    String habitId,
    String dateKey,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('proofs')
        .where('habitId', isEqualTo: habitId)
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return ProofSubmission.fromMap({
      ...snapshot.docs.first.data(),
      'id': snapshot.docs.first.id,
    });
  }

  @override
  Future<void> deleteProof(String proofId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // First, get the proof to check if it has a media file
    final proofDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('proofs')
        .doc(proofId)
        .get();

    if (!proofDoc.exists) return;

    final proof = ProofSubmission.fromMap({
      ...proofDoc.data()!,
      'id': proofDoc.id,
    });

    // Delete media file from Firebase Storage if it exists
    if (proof.mediaUrl != null && proof.mediaUrl!.isNotEmpty) {
      try {
        final ref = _storage.refFromURL(proof.mediaUrl!);
        await ref.delete();
      } catch (e) {
        // Log error but continue with proof deletion
        // Error is silently ignored to allow proof deletion to proceed
      }
    }

    // Delete proof document
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('proofs')
        .doc(proofId)
        .delete();
  }

  @override
  Future<String> uploadMediaFile(
    String filePath,
    String habitId,
    String proofType,
    String? fileName,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    // Determine file extension
    final extension = fileName?.split('.').last ?? filePath.split('.').last;
    
    // Create unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueFileName = fileName ?? 'proof_$timestamp.$extension';

    // Create storage reference
    final storageRef = _storage
        .ref()
        .child('users')
        .child(user.uid)
        .child('proofs')
        .child(habitId)
        .child(uniqueFileName);

    // Upload file
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask;
    
    // Get download URL
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    return downloadUrl;
  }
}

