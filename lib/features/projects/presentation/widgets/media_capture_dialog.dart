import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/project_task_proof.dart';
import '../../../../core/constants/project_proof_types.dart';
import '../../data/repositories/firestore_project_proof_repository.dart';
import '../../domain/repositories/project_proof_repository.dart';

class MediaCaptureDialog extends StatefulWidget {
  final ProjectTaskModel task;

  const MediaCaptureDialog({
    super.key,
    required this.task,
  });

  @override
  State<MediaCaptureDialog> createState() => _MediaCaptureDialogState();
}

class _MediaCaptureDialogState extends State<MediaCaptureDialog> {
  final ProjectProofRepository _proofRepository = FirestoreProjectProofRepository();
  File? _selectedFile;
  bool _isUploading = false;
  String? _uploadedUrl;

  Future<void> _pickFile() async {
    // Note: For full implementation, add image_picker or file_picker package
    // For now, this is a placeholder that shows the UI structure
    // In production, use: FilePicker.platform.pickFiles() or ImagePicker.pickVideo()
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File picker integration needed. Use file_picker or image_picker package.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<String> _uploadToStorage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final storage = FirebaseStorage.instance;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.path.split('.').last;
    final fileName = 'project_proof_${widget.task.id}_$timestamp.$extension';

    final ref = storage
        .ref()
        .child('users')
        .child(user.uid)
        .child('project_proofs')
        .child(widget.task.id)
        .child(fileName);

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<void> _submitProof() async {
    if (_selectedFile == null && _uploadedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
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
        _isUploading = false;
      });
      return;
    }

    try {
      String? mediaUrl = _uploadedUrl;
      
      // Upload file if not already uploaded
      if (_selectedFile != null && mediaUrl == null) {
        mediaUrl = await _uploadToStorage(_selectedFile!);
      }

      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final now = DateTime.now();

      // Estimate duration (10-20 seconds for media clips)
      final duration = const Duration(seconds: 15); // Default 15 seconds

      final proof = ProjectTaskProof(
        id: '',
        taskId: widget.task.id,
        userId: user.uid,
        proofType: ProjectProofTypes.smallMediaClip,
        mediaUrl: mediaUrl,
        timeSpent: duration,
        sessionStart: now,
        sessionEnd: now,
        dateKey: dateKey,
        sessionData: {
          'taskTitle': widget.task.title,
          'mediaType': _selectedFile?.path.split('.').last ?? 'unknown',
        },
      );

      await _proofRepository.saveProof(proof);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isUploading = false;
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
                    Icons.videocam,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Record Media Clip',
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Record a short clip (10-20 seconds)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedFile == null && _uploadedUrl == null)
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.videocam, color: Colors.white),
                        label: const Text(
                          'Select File',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFile?.path.split('/').last ?? 'File selected',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                  _uploadedUrl = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: For full implementation, add file_picker or image_picker package for camera/gallery access',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedFile == null && _uploadedUrl == null) || _isUploading
                      ? null
                      : _submitProof,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit',
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

