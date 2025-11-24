import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:recalim/core/models/deletion_request_model.dart';
import '../../domain/repositories/deletion_request_repository.dart';

class FirestoreDeletionRequestRepository implements DeletionRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<DeletionRequestModel> createDeletionRequest({
    required String userId,
    required String habitId,
    required String habitTitle,
    required String reason,
    required String accountabilityPartnerContact,
    required String contactType,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('deletion_requests')
        .doc();

    final request = DeletionRequestModel(
      id: docRef.id,
      userId: userId,
      habitId: habitId,
      habitTitle: habitTitle,
      requestType: 'habit',
      reason: reason,
      accountabilityPartnerContact: accountabilityPartnerContact,
      contactType: contactType,
      status: DeletionRequestStatus.pending,
      expiresAt: DateTime.now().add(const Duration(days: 7)), // 7 days to respond
    );

    await docRef.set(request.toMap());
    return request;
  }

  @override
  Future<DeletionRequestModel> createPlanDeletionRequest({
    required String userId,
    required String planId,
    required String planTitle,
    required String reason,
    required String accountabilityPartnerContact,
    required String contactType,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('deletion_requests')
        .doc();

    final request = DeletionRequestModel(
      id: docRef.id,
      userId: userId,
      planId: planId,
      planTitle: planTitle,
      requestType: 'plan',
      reason: reason,
      accountabilityPartnerContact: accountabilityPartnerContact,
      contactType: contactType,
      status: DeletionRequestStatus.pending,
      expiresAt: DateTime.now().add(const Duration(days: 7)), // 7 days to respond
    );

    await docRef.set(request.toMap());
    return request;
  }

  @override
  Future<DeletionRequestModel?> getDeletionRequestById(String requestId) async {
    try {
      // Search across all users' deletion requests
      // Note: This assumes requestId is unique or we need userId
      // For better performance, we could add userId as a parameter
      final querySnapshot = await _firestore
          .collectionGroup('deletion_requests')
          .where('id', isEqualTo: requestId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return DeletionRequestModel.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      debugPrint('Error getting deletion request: $e');
      return null;
    }
  }

  @override
  Future<DeletionRequestModel?> getPendingDeletionRequestForHabit(
    String userId,
    String habitId,
  ) async {
    try {
      // Query without orderBy to avoid needing composite index
      // We'll sort in memory if needed
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deletion_requests')
          .where('habitId', isEqualTo: habitId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (snapshot.docs.isEmpty) return null;

      // Sort by createdAt descending in memory and get the most recent
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['createdAt'] as Timestamp?;
          final bDate = b.data()['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // Descending order
        });

      return DeletionRequestModel.fromMap(sortedDocs.first.data());
    } catch (e) {
      debugPrint('Error getting pending deletion request: $e');
      return null;
    }
  }

  @override
  Future<DeletionRequestModel?> getPendingDeletionRequestForPlan(
    String userId,
    String planId,
  ) async {
    try {
      // Query without orderBy to avoid needing composite index
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deletion_requests')
          .where('planId', isEqualTo: planId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (snapshot.docs.isEmpty) return null;

      // Sort by createdAt descending in memory and get the most recent
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['createdAt'] as Timestamp?;
          final bDate = b.data()['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // Descending order
        });

      return DeletionRequestModel.fromMap(sortedDocs.first.data());
    } catch (e) {
      debugPrint('Error getting pending deletion request for plan: $e');
      return null;
    }
  }

  @override
  Future<List<DeletionRequestModel>> getPendingDeletionRequests(String userId) async {
    try {
      // Query without orderBy to avoid needing composite index
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deletion_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      // Sort by createdAt descending in memory
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['createdAt'] as Timestamp?;
          final bDate = b.data()['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // Descending order
        });

      return sortedDocs
          .map((doc) => DeletionRequestModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending deletion requests: $e');
      return [];
    }
  }

  @override
  Future<void> updateDeletionRequestStatus(
    String requestId,
    DeletionRequestStatus status,
    String response,
  ) async {
    try {
      // Find the request by searching all users
      final querySnapshot = await _firestore
          .collectionGroup('deletion_requests')
          .where('id', isEqualTo: requestId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Deletion request not found');
      }

      final docRef = querySnapshot.docs.first.reference;
      await docRef.update({
        'status': status.value,
        'response': response,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating deletion request status: $e');
      rethrow;
    }
  }

  @override
  bool isApprovalResponse(String response) {
    final normalized = response.trim().toUpperCase();
    return normalized == 'Y' || normalized == 'YES';
  }

  @override
  Future<void> processResponse(String requestId, String response) async {
    final normalizedResponse = response.trim().toUpperCase();
    
    // Check if response is valid
    if (normalizedResponse != 'Y' &&
        normalizedResponse != 'YES' &&
        normalizedResponse != 'N' &&
        normalizedResponse != 'NO') {
      throw Exception('Invalid response. Please reply with Y/YES to approve or N/NO to reject.');
    }

    final isApproved = isApprovalResponse(response);
    final status = isApproved
        ? DeletionRequestStatus.approved
        : DeletionRequestStatus.rejected;

    await updateDeletionRequestStatus(requestId, status, normalizedResponse);

    // If approved, trigger the actual deletion
    if (isApproved) {
      final request = await getDeletionRequestById(requestId);
      if (request != null) {
        // The deletion will be handled by checking for approved requests
        // This could trigger a Cloud Function or be handled in the app
        debugPrint('✅ Deletion request approved for habit: ${request.habitId}');
      }
    }
  }

  /// Get deletion request by contact (for SMS/Email response handling)
  Future<DeletionRequestModel?> getDeletionRequestByContact(
    String contact,
    String contactType,
  ) async {
    try {
      // Query without orderBy to avoid needing composite index
      final snapshot = await _firestore
          .collectionGroup('deletion_requests')
          .where('accountabilityPartnerContact', isEqualTo: contact)
          .where('contactType', isEqualTo: contactType)
          .where('status', isEqualTo: 'pending')
          .get();

      if (snapshot.docs.isEmpty) return null;

      // Sort by createdAt descending in memory and get the most recent
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['createdAt'] as Timestamp?;
          final bDate = b.data()['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // Descending order
        });

      return DeletionRequestModel.fromMap(sortedDocs.first.data());
    } catch (e) {
      debugPrint('Error getting deletion request by contact: $e');
      return null;
    }
  }

  @override
  Future<List<DeletionRequestModel>> getAllDeletionRequests(String userId) async {
    try {
      // Query without orderBy to avoid needing index, sort in memory instead
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('deletion_requests')
          .get();

      // Sort by createdAt descending in memory
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['createdAt'] as Timestamp?;
          final bDate = b.data()['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // Descending order
        });

      return sortedDocs
          .map((doc) => DeletionRequestModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting all deletion requests: $e');
      return [];
    }
  }
}

