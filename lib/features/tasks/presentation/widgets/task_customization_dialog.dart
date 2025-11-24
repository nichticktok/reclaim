import 'package:flutter/material.dart';
import 'package:recalim/core/models/preset_task_model.dart';

class TaskCustomizationScreen extends StatefulWidget {
  final PresetTaskModel presetTask;

  const TaskCustomizationScreen({
    super.key,
    required this.presetTask,
  });

  @override
  State<TaskCustomizationScreen> createState() => _TaskCustomizationScreenState();
}

class _TaskCustomizationScreenState extends State<TaskCustomizationScreen> {
  // Common fields
  String _frequency = 'Everyday';
  String _scheduledTime = '';
  
  // Task-specific fields
  String? _amount; // For water
  String? _duration; // For exercise, reading, meditation
  String? _wakeTime; // For wake up tasks
  
  final List<String> _frequencies = ['Everyday', 'Weekdays', 'Weekends', '3 times a week', '2 times a week', 'Once a week'];
  final List<String> _times = [
    '6:00 AM', '6:30 AM', '7:00 AM', '7:30 AM', '8:00 AM', '8:30 AM',
    '9:00 AM', '9:30 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM',
    '7:00 PM', '8:00 PM', '9:00 PM', '10:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    _scheduledTime = _times[0]; // Default to first time option
    _initializeTaskSpecificFields();
  }

  void _initializeTaskSpecificFields() {
    final title = widget.presetTask.title.toLowerCase();
    final description = widget.presetTask.description.toLowerCase();
    
    // Extract existing values from title/description if present
    if (title.contains('water') || title.contains('drink')) {
      // Extract amount from title (e.g., "Drink 2L of water" -> "2L")
      final match = RegExp(r'(\d+\.?\d*\s*[LlMmKkGg]+)').firstMatch(title);
      _amount = match?.group(1) ?? '2L';
    } else if (title.contains('read') || description.contains('read')) {
      // Extract duration from title (e.g., "Read for 30 minutes" -> "30 minutes")
      final match = RegExp(r'(\d+)\s*(minute|min|hour|hr)').firstMatch(title);
      _duration = match != null ? '${match.group(1)} ${match.group(2)}' : '30 minutes';
    } else if (title.contains('exercise') || title.contains('workout') || description.contains('exercise')) {
      final match = RegExp(r'(\d+)\s*(minute|min|hour|hr)').firstMatch(title);
      _duration = match != null ? '${match.group(1)} ${match.group(2)}' : '30 minutes';
    } else if (title.contains('meditate') || description.contains('meditate')) {
      final match = RegExp(r'(\d+)\s*(minute|min|hour|hr)').firstMatch(title);
      _duration = match != null ? '${match.group(1)} ${match.group(2)}' : '15 minutes';
    } else if (title.contains('wake up') || title.contains('wake')) {
      final match = RegExp(r'(\d+:\d+\s*[AaPp][Mm])').firstMatch(title);
      _wakeTime = match?.group(1) ?? '7:00 AM';
    }
  }

  void _handleSave() {
    final customizedTask = {
      'title': _getCustomizedTitle(),
      'description': _getCustomizedDescription(),
      'scheduledTime': _scheduledTime,
      'frequency': _frequency,
      'amount': _amount,
      'duration': _duration,
      'wakeTime': _wakeTime,
    };
    Navigator.pop(context, customizedTask);
  }

  bool _isWaterTask() {
    final title = widget.presetTask.title.toLowerCase();
    return title.contains('water') || title.contains('drink');
  }

  bool _isDurationTask() {
    final title = widget.presetTask.title.toLowerCase();
    return title.contains('read') || 
           title.contains('exercise') || 
           title.contains('workout') || 
           title.contains('meditate') ||
           title.contains('journal') ||
           title.contains('practice');
  }

  bool _isWakeUpTask() {
    final title = widget.presetTask.title.toLowerCase();
    return title.contains('wake up') || title.contains('wake');
  }

  String _getCustomizedTitle() {
    final baseTitle = widget.presetTask.title;
    
    if (_isWaterTask() && _amount != null) {
      return 'Drink $_amount of water';
    } else if (_isDurationTask() && _duration != null) {
      // Replace duration in title
      final title = baseTitle.toLowerCase();
      if (title.contains('read')) {
        return 'Read for $_duration';
      } else if (title.contains('exercise') || title.contains('workout')) {
        return 'Exercise for $_duration';
      } else if (title.contains('meditate')) {
        return 'Meditate for $_duration';
      } else if (title.contains('journal')) {
        return 'Journal for $_duration';
      } else if (title.contains('practice')) {
        return 'Practice for $_duration';
      }
    } else if (_isWakeUpTask() && _wakeTime != null) {
      return 'Wake up at $_wakeTime';
    }
    
    return baseTitle;
  }

  String _getCustomizedDescription() {
    if (_isWaterTask() && _amount != null) {
      return 'Stay hydrated by drinking $_amount of water daily';
    } else if (_isDurationTask() && _duration != null) {
      final baseDesc = widget.presetTask.description;
      return baseDesc.replaceAll(RegExp(r'\d+\s*(minute|min|hour|hr)'), _duration!);
    }
    return widget.presetTask.description;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          'Customize Task',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task title preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.presetTask.title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getCustomizedTitle(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
                
                // Water amount (for water tasks)
                if (_isWaterTask()) ...[
                  _buildSectionTitle('How much water?'),
                  const SizedBox(height: 12),
                  _buildWaterAmountSelector(),
                  const SizedBox(height: 24),
                ],
                
                // Duration (for duration-based tasks)
                if (_isDurationTask()) ...[
                  _buildSectionTitle('How long?'),
                  const SizedBox(height: 12),
                  _buildDurationSelector(),
                  const SizedBox(height: 24),
                ],
                
                // Wake time (for wake up tasks)
                if (_isWakeUpTask()) ...[
                  _buildSectionTitle('What time?'),
                  const SizedBox(height: 12),
                  _buildWakeTimeSelector(),
                  const SizedBox(height: 24),
                ],
                
                // Frequency
                _buildSectionTitle('How often?'),
                const SizedBox(height: 12),
                _buildFrequencySelector(),
                const SizedBox(height: 24),
                
                // Scheduled time
                _buildSectionTitle('Preferred time?'),
                const SizedBox(height: 12),
                _buildTimeSelector(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0F),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Task',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildWaterAmountSelector() {
    final amounts = ['1L', '1.5L', '2L', '2.5L', '3L', '3.5L', '4L'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amounts.map((amount) {
        final isSelected = _amount == amount;
        return GestureDetector(
          onTap: () => setState(() => _amount = amount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              amount,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDurationSelector() {
    final durations = [
      '5 minutes', '10 minutes', '15 minutes', '20 minutes',
      '30 minutes', '45 minutes', '1 hour', '1.5 hours', '2 hours'
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: durations.map((duration) {
        final isSelected = _duration == duration;
        return GestureDetector(
          onTap: () => setState(() => _duration = duration),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              duration,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWakeTimeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButton<String>(
        value: _wakeTime ?? '7:00 AM',
        isExpanded: true,
        dropdownColor: const Color(0xFF2A2A2A),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        underline: const SizedBox(),
        items: _times.map((time) {
          return DropdownMenuItem(
            value: time,
            child: Text(time),
          );
        }).toList(),
        onChanged: (value) => setState(() => _wakeTime = value),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _frequencies.map((frequency) {
        final isSelected = _frequency == frequency;
        return GestureDetector(
          onTap: () => setState(() => _frequency = frequency),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              frequency,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButton<String>(
        value: _scheduledTime.isNotEmpty ? _scheduledTime : _times[0],
        isExpanded: true,
        dropdownColor: const Color(0xFF2A2A2A),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        underline: const SizedBox(),
        items: _times.map((time) {
          return DropdownMenuItem(
            value: time,
            child: Text(time),
          );
        }).toList(),
        onChanged: (value) => setState(() => _scheduledTime = value ?? _times[0]),
      ),
    );
  }
}

