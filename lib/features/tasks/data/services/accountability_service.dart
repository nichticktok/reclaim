import 'package:flutter/foundation.dart';
import 'package:recalim/core/models/deletion_request_model.dart';

/// Service for sending accountability messages via SMS or Email
/// This is a placeholder - actual implementation would use:
/// - For SMS: Twilio, AWS SNS, or Firebase Cloud Messaging
/// - For Email: SendGrid, AWS SES, or Firebase Cloud Functions + Email service
abstract class AccountabilityService {
  /// Send deletion request to accountability partner
  Future<bool> sendDeletionRequest({
    required DeletionRequestModel request,
  });

  /// Validate contact (phone or email format)
  bool isValidContact(String contact, String contactType);
}

class AccountabilityServiceImpl implements AccountabilityService {
  @override
  Future<bool> sendDeletionRequest({
    required DeletionRequestModel request,
  }) async {
    try {
      final message = _buildMessage(request);
      
      if (request.contactType == 'phone') {
        return await _sendSMS(request.accountabilityPartnerContact, message, request.id);
      } else {
        return await _sendEmail(request.accountabilityPartnerContact, message, request);
      }
    } catch (e) {
      debugPrint('Error sending accountability message: $e');
      return false;
    }
  }

  String _buildMessage(DeletionRequestModel request) {
    final targetTitle = request.targetTitle;
    final reason = request.reason;
    final requestId = request.id;
    final isPlan = request.requestType == 'plan';
    final itemType = isPlan ? 'plan' : 'task';
    
    if (request.contactType == 'phone') {
      // SMS format (160 chars max recommended)
      return 'Hi! ${request.userId} wants to delete $itemType "$targetTitle". Reason: $reason. Reply Y to approve or N to reject. Request ID: $requestId';
    } else {
      // Email format
      return '''
Hello,

${request.userId} has requested to delete the following ${isPlan ? 'plan' : 'task'}:

${isPlan ? 'Plan' : 'Task'}: $targetTitle
Reason: $reason

Please reply to this message with:
- Y or YES to approve the deletion
- N or NO to reject the deletion

Request ID: $requestId

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

  Future<bool> _sendEmail(String email, String message, DeletionRequestModel request) async {
    // TODO: Implement actual email sending via SendGrid, AWS SES, etc.
    // For now, just log it
    debugPrint('📧 Email would be sent to $email:');
    debugPrint('Subject: Deletion Request Approval - ${request.targetTitle}');
    debugPrint('Body: $message');
    
    // In production, this would call an API like:
    // - SendGrid API
    // - AWS SES
    // - Firebase Cloud Functions that calls email service
    
    return true; // Simulate success
  }

  @override
  bool isValidContact(String contact, String contactType) {
    if (contact.trim().isEmpty) return false;

    if (contactType == 'phone') {
      // Basic phone validation (digits, optional +, spaces, dashes, parentheses)
      final phoneRegex = RegExp(r'^[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$');
      return phoneRegex.hasMatch(contact.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', ''));
    } else if (contactType == 'email') {
      // Basic email validation
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      return emailRegex.hasMatch(contact);
    }

    return false;
  }
}

