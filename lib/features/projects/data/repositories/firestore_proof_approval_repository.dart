import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/proof_approval_repository.dart';
import '../../domain/entities/proof_approval_request.dart';

class FirestoreProofApprovalRepository implements ProofApprovalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> createApprovalRequest(ProofApprovalRequest request) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('proof_approval_requests')
        .add(request.toMap());

    return docRef.id;
  }

  @override
  Future<ProofApprovalRequest?> getApprovalRequestById(String requestId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('proof_approval_requests')
        .doc(requestId)
        .get();

    if (!doc.exists) return null;

    return ProofApprovalRequest.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<ProofApprovalRequest?> getPendingApprovalForProof(String proofId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('proof_approval_requests')
        .where('proofId', isEqualTo: proofId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return ProofApprovalRequest.fromMap(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  @override
  Future<void> updateApprovalRequest(ProofApprovalRequest request) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('proof_approval_requests')
        .doc(request.id)
        .update(request.toMap());
  }

  @override
  Future<void> processApprovalResponse(String requestId, String response) async {
    final request = await getApprovalRequestById(requestId);
    if (request == null) {
      throw Exception('Approval request not found');
    }

    final isApproved = isApprovalResponse(response);
    final updatedRequest = request.copyWith(
      status: isApproved ? 'approved' : 'rejected',
      respondedAt: DateTime.now(),
      response: response,
    );

    await updateApprovalRequest(updatedRequest);
  }

  @override
  bool isApprovalResponse(String response) {
    final normalized = response.trim().toUpperCase();
    return normalized == 'Y' ||
        normalized == 'YES' ||
        normalized == 'APPROVE' ||
        normalized == 'APPROVED';
  }
}

