import 'package:flutter/foundation.dart';
import '../../../../core/models/project_task_proof.dart';
import '../../domain/entities/proof_approval_request.dart';

/// Service for sending proof approval requests via SMS or Email
/// Separate from accountability service (which is for deletion requests)
abstract class ProofApprovalService {
  /// Send approval request to peer
  Future<bool> sendApprovalRequest({
    required ProofApprovalRequest request,
    required ProjectTaskProof proof,
  });

  /// Validate contact (phone or email format)
  bool isValidContact(String contact, String contactType);
}

class ProofApprovalServiceImpl implements ProofApprovalService {
  @override
  Future<bool> sendApprovalRequest({
    required ProofApprovalRequest request,
    required ProjectTaskProof proof,
  }) async {
    try {
      final message = _buildMessage(request, proof);
      
      if (request.contactType == 'phone') {
        return await _sendSMS(request.approverContact, message, request.id);
      } else {
        return await _sendEmail(request.approverContact, message, request);
      }
    } catch (e) {
      debugPrint('Error sending proof approval message: $e');
      return false;
    }
  }

  String _buildMessage(ProofApprovalRequest request, ProjectTaskProof proof) {
    final proofSummary = proof.generateProofSummary();
    
    if (request.contactType == 'phone') {
      // SMS format (160 chars max recommended)
      return 'Hi! ${request.requesterId} completed a task and needs your approval. Proof: $proofSummary. Reply Y to approve or N to reject. Request ID: ${request.id}';
    } else {
      // Email format
      return '''
Hello,

${request.requesterId} has completed a project task and is requesting your approval for their proof:

Proof Summary: $proofSummary
Task ID: ${request.taskId}
Proof ID: ${request.proofId}

Please reply to this message with:
- Y or YES to approve
- N or NO to reject

Request ID: ${request.id}

This request will expire in 7 days if no response is received.

Thank you for being an accountability partner!
''';
    }
  }

  Future<bool> _sendSMS(String phoneNumber, String message, String requestId) async {
    // TODO: Implement actual SMS sending via Twilio, AWS SNS, etc.
    // For now, just log it
    debugPrint('📱 SMS would be sent to $phoneNumber:');
    debugPrint('Message: $message');
    debugPrint('Request ID: $requestId');
    
    // In production, this would call an API like:
    // - Twilio API
    // - AWS SNS
    // - Firebase Cloud Functions that calls SMS service
    
    return true; // Simulate success
  }

  Future<bool> _sendEmail(String email, String message, ProofApprovalRequest request) async {
    // TODO: Implement actual email sending via SendGrid, AWS SES, etc.
    // For now, just log it
    debugPrint('📧 Email would be sent to $email:');
    debugPrint('Subject: Proof Approval Request - ${request.taskId}');
    debugPrint('Body: $message');
    
    // In production, this would call an API like:
    // - SendGrid API
    // - AWS SES
    // - Firebase Cloud Functions that calls email service
    
    return true; // Simulate success
  }

  @override
  bool isValidContact(String contact, String contactType) {
    if (contactType == 'phone') {
      // Basic phone validation (digits, +, -, spaces, parentheses)
      final phoneRegex = RegExp(r'^[\d\s\+\-\(\)]+$');
      return phoneRegex.hasMatch(contact) && contact.replaceAll(RegExp(r'[\s\+\-\(\)]'), '').length >= 10;
    } else if (contactType == 'email') {
      // Basic email validation
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      return emailRegex.hasMatch(contact);
    }
    return false;
  }
}

