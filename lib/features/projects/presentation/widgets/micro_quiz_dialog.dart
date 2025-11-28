import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/project_task_proof.dart';
import '../../../../core/constants/project_proof_types.dart';
import '../../data/repositories/firestore_project_proof_repository.dart';
import '../../domain/repositories/project_proof_repository.dart';
import '../../domain/entities/multiple_choice_question.dart';

class MicroQuizDialog extends StatefulWidget {
  final ProjectTaskModel task;
  final String category;
  final List<MultipleChoiceQuestion> questions;

  const MicroQuizDialog({
    super.key,
    required this.task,
    required this.category,
    required this.questions,
  });

  @override
  State<MicroQuizDialog> createState() => _MicroQuizDialogState();
}

class _MicroQuizDialogState extends State<MicroQuizDialog> {
  final ProjectProofRepository _proofRepository = FirestoreProjectProofRepository();
  final List<int?> _selectedIndices = []; // Selected option index for each question
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedIndices.addAll(List.filled(widget.questions.length, null));
  }

  bool _validateAnswers() {
    return _selectedIndices.every((idx) => idx != null);
  }

  Future<void> _submitProof() async {
    if (!_validateAnswers()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions'),
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

    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateTime.now();

    // Store selected indices as strings
    final answers = _selectedIndices.map((idx) => idx.toString()).toList();

    final proof = ProjectTaskProof(
      id: '',
      taskId: widget.task.id,
      userId: user.uid,
      proofType: ProjectProofTypes.reflectionNote, // Micro-quiz uses reflection note type
      reflectionAnswers: answers,
      sessionStart: now,
      sessionEnd: now,
      dateKey: dateKey,
      sessionData: {
        'taskTitle': widget.task.title,
        'questions': widget.questions.map((q) => q.toMap()).toList(),
        'quizType': 'micro_quiz',
      },
    );

    try {
      await _proofRepository.saveProof(proof);
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving proof: $e'),
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
                    Icons.quiz,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Quick Quiz',
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
              ...List.generate(widget.questions.length, (questionIndex) {
                final question = widget.questions[questionIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${questionIndex + 1}. ${question.question}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Show options as radio buttons
                      ...List.generate(question.options.length, (optionIndex) {
                        final option = question.options[optionIndex];
                        final isSelected = _selectedIndices[questionIndex] == optionIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIndices[questionIndex] = optionIndex;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : const Color(0xFF0D0D0F),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.orange
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: isSelected ? Colors.orange : Colors.white.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProof,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
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

