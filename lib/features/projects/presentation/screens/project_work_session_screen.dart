import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/project_task_proof.dart';
import '../../../../core/constants/project_proof_types.dart';
import '../../data/repositories/firestore_project_proof_repository.dart';
import '../../domain/repositories/project_proof_repository.dart';
import '../../data/services/ai_reflection_service.dart';
import '../../domain/entities/multiple_choice_question.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectWorkSessionScreen extends StatefulWidget {
  final ProjectTaskModel task;
  final String projectId;

  const ProjectWorkSessionScreen({
    super.key,
    required this.task,
    required this.projectId,
  });

  @override
  State<ProjectWorkSessionScreen> createState() => _ProjectWorkSessionScreenState();
}

class _ProjectWorkSessionScreenState extends State<ProjectWorkSessionScreen> {
  final ProjectProofRepository _proofRepository = FirestoreProjectProofRepository();
  final TextEditingController _notesController = TextEditingController();
  final List<String> _progressNotes = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _projectCategory;
  ProjectTaskProof? _savedProof; // Store the saved proof to update with reflection answers
  List<MultipleChoiceQuestion>? _reflectionQuestions; // Pre-generated multiple choice questions
  bool _questionsGenerated = false;

  // Timer state
  Timer? _workTimer;
  int _workTotalSeconds = 0;
  DateTime? _workStartTime;
  bool _isRunning = false;
  bool _sessionCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadProjectCategory();
    _generateReflectionQuestions();
  }

  Future<void> _loadProjectCategory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final projectDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (projectDoc.exists && mounted) {
        final data = projectDoc.data();
        setState(() {
          _projectCategory = data?['category'] as String? ?? 'general';
        });
      }
    } catch (e) {
      debugPrint('Error loading project category: $e');
      if (mounted) {
        setState(() {
          _projectCategory = 'general';
        });
      }
    }
  }

  Future<void> _generateReflectionQuestions() async {
    if (_questionsGenerated) return;
    
    try {
      final category = _projectCategory ?? 'general';
      
      // Generate AI reflection questions when task starts
      final reflectionService = AIReflectionService();
      final questions = await reflectionService.generateReflectionQuestions(
        widget.task,
        category,
      );
      
      if (mounted) {
        setState(() {
          _reflectionQuestions = questions;
          _questionsGenerated = true;
        });
      }
    } catch (e) {
      debugPrint('Error generating reflection questions: $e');
      // Fallback to default questions
      if (mounted) {
        setState(() {
          _reflectionQuestions = [
            MultipleChoiceQuestion(
              question: 'What did you accomplish in this session?',
              options: ['Completed the task', 'Partially completed', 'Just started', 'I don\'t know'],
              correctOptionIndex: 0,
              questionType: 'multiple_choice',
            ),
          ];
          _questionsGenerated = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    _workStartTime = DateTime.now();
    _isRunning = true;

    _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_workStartTime != null) {
        setState(() {
          _workTotalSeconds = DateTime.now().difference(_workStartTime!).inSeconds;
        });
      }
    });
  }

  void _pauseTimer() {
    _workTimer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    if (_workStartTime == null) {
      _startTimer();
      return;
    }

    // Adjust start time to account for paused duration
    final pausedDuration = Duration(seconds: _workTotalSeconds);
    _workStartTime = DateTime.now().subtract(pausedDuration);
    _isRunning = true;

    _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_workStartTime != null) {
        setState(() {
          _workTotalSeconds = DateTime.now().difference(_workStartTime!).inSeconds;
        });
      }
    });
  }

  void _stopTimer() {
    _workTimer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _addProgressNote() {
    final note = _notesController.text.trim();
    if (note.isEmpty) return;

    setState(() {
      _progressNotes.add(note);
      _notesController.clear();
    });
  }

  Future<void> _completeSession() async {
    if (_workStartTime == null || _workTotalSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please start the timer first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _stopTimer();
    final sessionEnd = DateTime.now();
    final timeSpent = Duration(seconds: _workTotalSeconds);

    // Generate proof
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final proof = ProjectTaskProof(
      id: '',
      taskId: widget.task.id,
      userId: user.uid,
      proofType: ProjectProofTypes.timedSession,
      timeSpent: timeSpent,
      progressNotes: _progressNotes,
      sessionStart: _workStartTime!,
      sessionEnd: sessionEnd,
      dateKey: dateKey,
      sessionData: {
        'taskTitle': widget.task.title,
        'taskDescription': widget.task.description,
        if (_reflectionQuestions != null) 'reflectionQuestions': _reflectionQuestions!.map((q) => q.toMap()).toList(),
      },
    );

    try {
      final proofId = await _proofRepository.saveProof(proof);
      
      // Get the saved proof with ID
      final savedProof = await _proofRepository.getProofById(proofId);
      _savedProof = savedProof;
      
      if (mounted) {
        // After saving proof, show reflection questions
        await _showReflectionQuestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving proof: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showReflectionQuestions() async {
    if (_reflectionQuestions == null || _reflectionQuestions!.isEmpty) {
      // Questions not generated yet, generate them now
      await _generateReflectionQuestions();
    }
    
    if (_reflectionQuestions == null || _reflectionQuestions!.isEmpty) {
      // Still no questions, show completion screen
      if (mounted) {
        setState(() {
          _sessionCompleted = true;
        });
      }
      return;
    }
    
    try {
      // Show reflection questions dialog using pre-generated questions
      debugPrint('📋 Showing reflection questions dialog...');
      final selectedIndices = await _showReflectionQuestionsDialog(_reflectionQuestions!);
      debugPrint('📋 Dialog returned, selected indices: ${selectedIndices?.length ?? 0}');
      
      if (selectedIndices == null || selectedIndices.isEmpty || !mounted) {
        debugPrint('⚠️ No answers or not mounted, showing completion screen');
        // User cancelled or no answers, still show completion
        if (mounted) {
          setState(() {
            _sessionCompleted = true;
          });
        }
        return;
      }
      
      debugPrint('✅ Reflection answers collected: ${selectedIndices.length} selected options');
      
      // Save proof and validate in background (don't wait)
      _saveProofAndValidateInBackground(selectedIndices);
      
      // Wait a tiny bit for dialog animation to complete, then navigate
      // This prevents ChangeNotifier disposal issues during route transitions
      if (mounted) {
        debugPrint('🔙 Waiting for dialog animation to complete...');
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (!mounted) {
          debugPrint('❌ Widget disposed during delay');
          return;
        }
        
        debugPrint('🔙 Navigating back to task page...');
        try {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            // Return true to indicate proof was submitted (validation happens in background)
            navigator.pop(true);
            debugPrint('✅ Navigation pop executed');
          } else {
            debugPrint('❌ Cannot pop - trying root navigator...');
            final rootNavigator = Navigator.of(context, rootNavigator: true);
            if (rootNavigator.canPop()) {
              rootNavigator.pop(true);
              debugPrint('✅ Root navigator pop executed');
            } else {
              debugPrint('❌ Root navigator also cannot pop');
            }
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Error navigating: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }
    } catch (e) {
      debugPrint('Error showing reflection questions: $e');
      // If reflection fails, still show completion screen
      if (mounted) {
        setState(() {
          _sessionCompleted = true;
        });
      }
    }
  }

  Future<void> _saveProofAndValidateInBackground(List<int> selectedIndices) async {
    // Wait a bit to ensure navigation completed
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Store selected indices as answers (convert to strings for storage)
    final answersAsStrings = selectedIndices.map((idx) => idx.toString()).toList();
    
    // Update proof with answers
    if (_savedProof != null) {
      try {
        final updatedProof = _savedProof!.copyWith(
          reflectionAnswers: answersAsStrings,
        );
        await _proofRepository.updateProof(updatedProof);
        debugPrint('✅ Proof updated with selected option indices');
      } catch (e) {
        debugPrint('❌ Error updating proof: $e');
      }
    }
    
    // Run validation in background
    _validateAnswersInBackground(selectedIndices);
  }

  Future<void> _validateAnswersInBackground(List<int> selectedIndices) async {
    try {
      debugPrint('🔍 Validating ${selectedIndices.length} selected options in background...');
      
      // Check if any answers are incorrect by comparing selected indices with correct indices
      final hasIncorrectAnswers = selectedIndices.asMap().entries.any(
        (entry) {
          final questionIndex = entry.key;
          final selectedIndex = entry.value;
          final question = _reflectionQuestions![questionIndex];
          return selectedIndex != question.correctOptionIndex;
        },
      );
      
      debugPrint('📊 Has incorrect answers: $hasIncorrectAnswers');
      
      if (hasIncorrectAnswers && _savedProof != null) {
        // Store review data in proof - map question index to correct option index
        final reviewData = <int, String>{};
        selectedIndices.asMap().forEach((questionIndex, selectedIndex) {
          final question = _reflectionQuestions![questionIndex];
          if (selectedIndex != question.correctOptionIndex) {
            // Store the correct option text
            reviewData[questionIndex] = question.options[question.correctOptionIndex];
          }
        });
        
        // Update proof with review flag and data
        final updatedProof = _savedProof!.copyWith(
          needsReview: true,
          reviewData: reviewData,
        );
        await _proofRepository.updateProof(updatedProof);
        debugPrint('📚 Proof updated with review data: ${reviewData.length} corrections');
      } else {
        // All answers correct - mark as reviewed
        if (_savedProof != null) {
          final updatedProof = _savedProof!.copyWith(
            needsReview: false,
          );
          await _proofRepository.updateProof(updatedProof);
          debugPrint('✅ All answers correct, proof marked as reviewed');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error validating answers in background: $e');
      debugPrint('Stack trace: $stackTrace');
      // On error, still mark as needs review to be safe
      if (_savedProof != null) {
        try {
          final updatedProof = _savedProof!.copyWith(
            needsReview: true,
          );
          await _proofRepository.updateProof(updatedProof);
        } catch (updateError) {
          debugPrint('Error updating proof: $updateError');
        }
      }
    }
  }


  Future<List<int>?> _showReflectionQuestionsDialog(List<MultipleChoiceQuestion> questions) async {
    return await showDialog<List<int>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ReflectionQuestionsDialogWidget(
        questions: questions,
        taskTitle: widget.task.title,
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionCompleted) {
      final timeSpent = Duration(seconds: _workTotalSeconds);
      final hours = timeSpent.inHours;
      final minutes = timeSpent.inMinutes % 60;
      final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0F),
        appBar: AppBar(
          title: const Text(
            'Session Complete!',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Great work!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You worked for $timeStr',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              if (_progressNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress Notes:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._progressNotes.map((note) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $note',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true); // Return true to indicate completion
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                icon: const Icon(Icons.done, color: Colors.white),
                label: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: Text(
          widget.task.title,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Description
            if (widget.task.description.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  widget.task.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Timer Display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withValues(alpha: 0.2),
                    const Color(0xFF1A1A1A),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Work Time',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(_workTotalSeconds),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isRunning && _workTotalSeconds == 0)
                        ElevatedButton.icon(
                          onPressed: _startTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          label: const Text(
                            'Start',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      else if (!_isRunning && _workTotalSeconds > 0)
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _resumeTimer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.play_arrow, color: Colors.white),
                              label: const Text(
                                'Resume',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _completeSession,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.stop, color: Colors.white),
                              label: const Text(
                                'Complete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pauseTimer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.pause, color: Colors.white),
                              label: const Text(
                                'Pause',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _completeSession,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.stop, color: Colors.white),
                              label: const Text(
                                'Complete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progress Notes Section
            const Text(
              'Progress Notes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'What are you working on? (e.g., "Studied EC2", "Completed quiz 1")',
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
                    maxLines: 2,
                    onSubmitted: (_) => _addProgressNote(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addProgressNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Note', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),

            if (_progressNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Notes:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._progressNotes.map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  note,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

// Separate StatefulWidget for dialog to properly manage controller lifecycle
class _ReflectionQuestionsDialogWidget extends StatefulWidget {
  final List<MultipleChoiceQuestion> questions;
  final String taskTitle;

  const _ReflectionQuestionsDialogWidget({
    required this.questions,
    required this.taskTitle,
  });

  @override
  State<_ReflectionQuestionsDialogWidget> createState() => _ReflectionQuestionsDialogWidgetState();
}

class _ReflectionQuestionsDialogWidgetState extends State<_ReflectionQuestionsDialogWidget> {
  final List<int?> _selectedIndices = []; // Selected option index for each question

  @override
  void initState() {
    super.initState();
    _selectedIndices.addAll(List.filled(widget.questions.length, null));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_note,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Reflection Questions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.taskTitle,
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
                        question.question,
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
                  onPressed: () {
                    // Validate all answers
                    final allAnswered = _selectedIndices.every((idx) => idx != null);
                    if (!allAnswered) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please answer all questions'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Collect selected indices
                    final collectedIndices = _selectedIndices.map((idx) => idx!).toList();
                    
                    // Close dialog and return selected indices
                    Navigator.of(context, rootNavigator: true).pop(collectedIndices);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
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


