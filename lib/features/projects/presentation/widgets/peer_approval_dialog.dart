import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/project_task_proof.dart';
import '../../data/services/proof_approval_service.dart';
import '../../data/repositories/firestore_proof_approval_repository.dart';
import '../../domain/repositories/proof_approval_repository.dart';
import '../../domain/entities/proof_approval_request.dart';

class PeerApprovalDialog extends StatefulWidget {
  final ProjectTaskModel task;
  final ProjectTaskProof proof;

  const PeerApprovalDialog({
    super.key,
    required this.task,
    required this.proof,
  });

  @override
  State<PeerApprovalDialog> createState() => _PeerApprovalDialogState();
}

class _PeerApprovalDialogState extends State<PeerApprovalDialog> {
  final ProofApprovalService _approvalService = ProofApprovalServiceImpl();
  final ProofApprovalRepository _approvalRepository = FirestoreProofApprovalRepository();
  final TextEditingController _contactController = TextEditingController();
  String _contactType = 'email';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  bool _validateContact() {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) return false;
    return _approvalService.isValidContact(contact, _contactType);
  }

  Future<void> _requestApproval() async {
    if (!_validateContact()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _contactType == 'email'
                ? 'Please enter a valid email address'
                : 'Please enter a valid phone number',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    try {
      final request = ProofApprovalRequest(
        id: '',
        proofId: widget.proof.id,
        taskId: widget.task.id,
        requesterId: user.uid,
        approverContact: _contactController.text.trim(),
        contactType: _contactType,
      );

      final requestId = await _approvalRepository.createApprovalRequest(request);
      final requestWithId = request.copyWith(id: requestId);

      final sent = await _approvalService.sendApprovalRequest(
        request: requestWithId,
        proof: widget.proof,
      );

      if (mounted) {
        if (sent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Approval request sent to ${_contactController.text.trim()}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send approval request'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Request Peer Approval',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.task.title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Send approval request to a peer who can verify your work',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              
              // Contact Type Selection
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Email'),
                      selected: _contactType == 'email',
                      onSelected: (selected) {
                        setState(() {
                          _contactType = 'email';
                        });
                      },
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: _contactType == 'email' ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Phone'),
                      selected: _contactType == 'phone',
                      onSelected: (selected) {
                        setState(() {
                          _contactType = 'phone';
                        });
                      },
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: _contactType == 'phone' ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contact Input
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: _contactType == 'email' ? 'Email Address' : 'Phone Number',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: _contactType == 'email'
                      ? 'friend@example.com'
                      : '+1234567890',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: const Color(0xFF0D0D0F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: _contactType == 'email'
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _requestApproval,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Send Request',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

