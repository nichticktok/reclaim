import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/project_planning_input.dart';
import '../controllers/projects_controller.dart';
import 'review_plan_screen.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'learning';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _durationDays;
  bool _useDuration = false;
  double _hoursPerDay = 1.0;

  final List<String> _categories = [
    'learning',
    'fitness',
    'room_remodel',
    'finance',
    'creative',
    'career',
    'health',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _calculateEndDate() {
    if (_durationDays != null && _durationDays! > 0) {
      setState(() {
        _endDate = _startDate.add(Duration(days: _durationDays!));
      });
    }
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set an end date or duration')),
      );
      return;
    }

    final controller = context.read<ProjectsController>();
    final input = ProjectPlanningInput(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      startDate: _startDate,
      endDate: _endDate!,
      hoursPerDay: _hoursPerDay,
    );

    try {
      await controller.generatePlan(input);
      if (!mounted) return;

      // Navigate to review plan screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReviewPlanScreen(input: input)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text(
          'Create Project',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Project Title',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'e.g., Get AWS Certification',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a project title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Add more context about your project...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category
                DropdownButtonFormField<String>(
                  key: ValueKey('category-$_category'),
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: 20),

                // Start Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Start Date',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.calendar_today,
                      color: Colors.orange,
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                          if (_durationDays != null) _calculateEndDate();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // End Date or Duration Toggle
                Wrap(
                  spacing: 12,
                  children: [
                    ChoiceChip(
                      label: const Text('End Date'),
                      selected: !_useDuration,
                      onSelected: (_) => setState(() => _useDuration = false),
                    ),
                    ChoiceChip(
                      label: const Text('Duration'),
                      selected: _useDuration,
                      onSelected: (_) => setState(() => _useDuration = true),
                    ),
                  ],
                ),

                if (!_useDuration) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'End Date',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    subtitle: Text(
                      _endDate != null
                          ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                          : 'Select end date',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.orange,
                      ),
                      onPressed: _selectDate,
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Duration (days)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _durationDays = int.tryParse(value);
                        _calculateEndDate();
                      });
                    },
                  ),
                ],
                const SizedBox(height: 20),

                // Hours per day
                Text(
                  'Hours per day: ${_hoursPerDay.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: _hoursPerDay,
                  min: 0.5,
                  max: 8.0,
                  divisions: 15,
                  label: '${_hoursPerDay.toStringAsFixed(1)} hours',
                  activeColor: Colors.orange,
                  onChanged: (value) => setState(() => _hoursPerDay = value),
                ),
                const SizedBox(height: 40),

                // Generate Plan Button
                Consumer<ProjectsController>(
                  builder: (context, controller, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.loading ? null : _generatePlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Generate Plan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
