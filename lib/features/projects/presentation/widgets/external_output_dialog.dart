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

class ExternalOutputDialog extends StatefulWidget {
  final ProjectTaskModel task;

  const ExternalOutputDialog({
    super.key,
    required this.task,
  });

  @override
  State<ExternalOutputDialog> createState() => _ExternalOutputDialogState();
}

class _ExternalOutputDialogState extends State<ExternalOutputDialog> {
  final ProjectProofRepository _proofRepository = FirestoreProjectProofRepository();
  final TextEditingController _linkController = TextEditingController();
  File? _screenshotFile;
  bool _isUploading = false;
  String? _uploadedScreenshotUrl;
  String _outputType = 'link'; // 'link' or 'screenshot'

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<void> _pickScreenshot() async {
    // Note: For full implementation, add image_picker package
    // For now, this is a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screenshot picker integration needed. Use image_picker package.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<String> _uploadScreenshotToStorage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final storage = FirebaseStorage.instance;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.path.split('.').last;
    final fileName = 'project_screenshot_${widget.task.id}_$timestamp.$extension';

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
    if (_outputType == 'link') {
      final link = _linkController.text.trim();
      if (link.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a link'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!_isValidUrl(link)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid URL (starting with http:// or https://)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_screenshotFile == null && _uploadedScreenshotUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a screenshot'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
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
      String? screenshotUrl = _uploadedScreenshotUrl;
      
      // Upload screenshot if not already uploaded
      if (_screenshotFile != null && screenshotUrl == null) {
        screenshotUrl = await _uploadScreenshotToStorage(_screenshotFile!);
      }

      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final now = DateTime.now();

      final proof = ProjectTaskProof(
        id: '',
        taskId: widget.task.id,
        userId: user.uid,
        proofType: ProjectProofTypes.externalOutput,
        externalLink: _outputType == 'link' ? _linkController.text.trim() : null,
        screenshotUrl: screenshotUrl,
        sessionStart: now,
        sessionEnd: now,
        dateKey: dateKey,
        sessionData: {
          'taskTitle': widget.task.title,
          'outputType': _outputType,
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
            content: Text('Error submitting proof: $e'),
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
                    Icons.link,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'External Output',
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
              
              // Output Type Selection
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Link'),
                      selected: _outputType == 'link',
                      onSelected: (selected) {
                        setState(() {
                          _outputType = 'link';
                        });
                      },
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: _outputType == 'link' ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Screenshot'),
                      selected: _outputType == 'screenshot',
                      onSelected: (selected) {
                        setState(() {
                          _outputType = 'screenshot';
                        });
                      },
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: _outputType == 'screenshot' ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Link Input
              if (_outputType == 'link') ...[
                TextField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    labelText: 'Link (GitHub, docs, etc.)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'https://github.com/user/repo/commit/...',
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
                  keyboardType: TextInputType.url,
                ),
              ],

              // Screenshot Upload
              if (_outputType == 'screenshot') ...[
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
                        'Upload a screenshot',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_screenshotFile == null && _uploadedScreenshotUrl == null)
                        ElevatedButton.icon(
                          onPressed: _pickScreenshot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.image, color: Colors.white),
                          label: const Text(
                            'Select Screenshot',
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
                                  _screenshotFile?.path.split('/').last ?? 'Screenshot selected',
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
                                    _screenshotFile = null;
                                    _uploadedScreenshotUrl = null;
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
                  'Note: For full implementation, add image_picker package for camera/gallery access',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitProof,
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

