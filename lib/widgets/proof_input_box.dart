import 'package:flutter/material.dart';

class ProofInputBox extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool showAttachmentButton;

  const ProofInputBox({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.showAttachmentButton = false,
  });

  @override
  State<ProofInputBox> createState() => _ProofInputBoxState();
}

class _ProofInputBoxState extends State<ProofInputBox> {
  bool _isEmpty = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Proof of Completion 🧾",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            maxLines: 4,
            onChanged: (val) {
              setState(() {
                _isEmpty = val.trim().isEmpty;
              });
            },
            decoration: InputDecoration(
              hintText: "Describe what you accomplished...",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 📎 Bottom Row: optional attachment + submit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.showAttachmentButton)
                IconButton(
                  icon: const Icon(Icons.attach_file_outlined,
                      color: Colors.grey),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("File upload coming soon 📸"),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isEmpty ? null : widget.onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEmpty
                      ? Colors.grey.shade300
                      : Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Submit Proof",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
