import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Weekly Progress Screen
/// Shows: Week number, date range, radar chart (Focus, Wisdom, Strength, Discipline, Confidence)
class WeeklyProgressScreen extends StatelessWidget {
  final int weekNumber;
  
  const WeeklyProgressScreen({
    super.key,
    required this.weekNumber,
  });

  @override
  Widget build(BuildContext context) {
    // Sample data for radar chart
    final metrics = {
      'Focus': 0.7,
      'Wisdom': 0.6,
      'Strength': 0.8,
      'Discipline': 0.75,
      'Confidence': 0.65,
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: Text(
          "Week $weekNumber",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week $weekNumber Progress',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your improvements across key areas',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Radar Chart
            _buildRadarChart(metrics),
            const SizedBox(height: 32),
            // Metrics List
            _buildMetricsList(metrics),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarChart(Map<String, double> metrics) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: RadarChartPainter(metrics),
        child: Container(),
      ),
    );
  }

  Widget _buildMetricsList(Map<String, double> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metrics Breakdown',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...metrics.entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(entry.value * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final Map<String, double> metrics;
  final List<String> labels;
  final List<double> values;

  RadarChartPainter(this.metrics)
      : labels = metrics.keys.toList(),
        values = metrics.values.toList();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    final angleStep = (2 * math.pi) / labels.length;

    final paint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw grid circles
    for (int i = 1; i <= 5; i++) {
      final gridRadius = radius * (i / 5);
      canvas.drawCircle(center, gridRadius, Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }

    // Draw axes
    for (int i = 0; i < labels.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 1);
    }

    // Draw data polygon
    final path = Path();
    for (int i = 0; i < labels.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = values[i];
      final x = center.dx + radius * value * math.cos(angle);
      final y = center.dy + radius * value * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Draw labels
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < labels.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final labelRadius = radius + 20;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);
      
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

