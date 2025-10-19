import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // between 0.0 and 1.0
  final double size;
  final String label;
  final Color color;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.label = "Progress",
    this.color = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 10,
              valueColor: AlwaysStoppedAnimation(Colors.grey.shade300),
            ),
          ),

          // Foreground animated progress ring
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(seconds: 1),
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation(color),
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),

          // Center label text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
