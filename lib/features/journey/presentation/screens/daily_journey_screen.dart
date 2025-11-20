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
      controller.initialize().then((_) {
        if (controller.currentMood != null) {
          setState(() {
            _selectedMood = controller.currentMood;
          });
        }
        if (controller.journalEntry != null) {
          _journalController.text = controller.journalEntry!;
        }
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood Selection
                _buildMoodSection(controller),
                const SizedBox(height: 32),
                // Journal Entry
                _buildJournalSection(controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodSection(JourneyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling today?',
          style: TextStyle(
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
              onTap: () {
                setState(() {
                  _selectedMood = mood;
                });
                controller.saveMood(mood);
              },
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
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildJournalSection(JourneyController controller) {
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
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Write about your day...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.orange,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            // Auto-save as user types (debounced in real app)
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              controller.saveJournalEntry(_journalController.text);
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
    );
  }
}

