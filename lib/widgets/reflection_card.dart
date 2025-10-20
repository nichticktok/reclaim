import 'package:flutter/material.dart';

class ReflectionCard extends StatefulWidget {
  final String question;
  final String? hint;
  final TextEditingController controller;
  final VoidCallback? onSave;

  const ReflectionCard({
    super.key,
    required this.question,
    this.hint,
    required this.controller,
    this.onSave,
  });

  @override
  State<ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends State<ReflectionCard> {
  late bool _isEmpty;

  @override
  void initState() {
    super.initState();
    _isEmpty = widget.controller.text.trim().isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            maxLines: 3,
            onChanged: (val) {
              setState(() {
                _isEmpty = val.trim().isEmpty;
              });
            },
            decoration: InputDecoration(
              hintText: widget.hint ?? 'Write a short reflection...',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.onSave != null)
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: _isEmpty ? null : widget.onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isEmpty ? Colors.grey.shade300 : Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
