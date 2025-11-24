import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/journey_controller.dart';
import '../../../milestone/presentation/controllers/milestone_controller.dart';

/// Daily Journey Screen
/// Shows: Day number, mood selection, tasks, journal entry
class DailyJourneyScreen extends StatefulWidget {
  final int dayNumber;
  
  const DailyJourneyScreen({
    super.key,
    required this.dayNumber,
  });

  @override
  State<DailyJourneyScreen> createState() => _DailyJourneyScreenState();
}

class _DailyJourneyScreenState extends State<DailyJourneyScreen> {
  final TextEditingController _journalController = TextEditingController();
  final List<String> _moods = ['😊', '😄', '😌', '😐', '😔', '😢'];
  String? _selectedMood;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<JourneyController>();
      // Initialize if not already initialized
      controller.initialize().then((_) {
        // Load data for the specific day
        controller.loadDayData(widget.dayNumber).then((_) {
          if (mounted) {
        if (controller.currentMood != null) {
          setState(() {
            _selectedMood = controller.currentMood;
          });
        }
        if (controller.journalEntry != null) {
          _journalController.text = controller.journalEntry!;
        }
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final milestoneController = context.watch<MilestoneController>();
    final totalDays = milestoneController.getTotalDays();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: Text(
          "Day ${widget.dayNumber}/$totalDays",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer<JourneyController>(
        builder: (context, controller, child) {
          if (controller.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          // Check if this day is today (only today can be edited)
          final isToday = widget.dayNumber == controller.currentDay;
          final isPastDay = widget.dayNumber < controller.currentDay;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show read-only message for past/future days
                if (!isToday) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: isPastDay 
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPastDay 
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPastDay ? Icons.history : Icons.lock_outline,
                          color: isPastDay ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isPastDay 
                                ? 'This is a past day. You can view your mood and journal entry, but cannot edit them.'
                                : 'This is a future day. You cannot edit until this day arrives.',
                            style: TextStyle(
                              color: isPastDay ? Colors.blue.shade100 : Colors.grey.shade300,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Mood Selection
                _buildMoodSection(controller, isToday: isToday),
                const SizedBox(height: 32),
                // Journal Entry
                _buildJournalSection(controller, isToday: isToday),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodSection(JourneyController controller, {required bool isToday}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isToday ? 'How are you feeling today?' : 'Mood',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _moods.map((mood) {
            final isSelected = _selectedMood == mood;
            return GestureDetector(
              onTap: isToday ? () {
                setState(() {
                  _selectedMood = mood;
                });
                controller.saveMood(mood, dayNumber: widget.dayNumber);
              } : null,
              child: Opacity(
                opacity: isToday ? 1.0 : 0.6,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      mood,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Show selected mood for past days
        if (!isToday && _selectedMood != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  _selectedMood!,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected mood',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJournalSection(JourneyController controller, {required bool isToday}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Journal Entry',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _journalController,
          maxLines: 8,
          enabled: isToday,
          readOnly: !isToday,
          style: TextStyle(
            // Make text appear dimmed for read-only
            color: isToday ? Colors.white : Colors.white.withValues(alpha: 0.7),
          ),
          decoration: InputDecoration(
            hintText: isToday ? 'Write about your day...' : 'No journal entry for this day',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: isToday 
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.orange,
                width: 2,
              ),
            ),
          ),
          onChanged: isToday ? (value) {
            // Auto-save as user types (debounced in real app)
          } : null,
        ),
        if (isToday) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                controller.saveJournalEntry(_journalController.text, dayNumber: widget.dayNumber);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Journal entry saved!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Entry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

