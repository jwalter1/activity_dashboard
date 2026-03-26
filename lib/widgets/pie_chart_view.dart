import 'dart:math';
import 'package:flutter/material.dart';

class PieChartView extends StatelessWidget {
  final Map<String, int> data;
  final Map<String, String> colors;

  const PieChartView({
    super.key,
    required this.data,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    int total = data.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return const Center(child: Text("No activities this week"));

    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _PieChartPainter(data, colors, total),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  final Map<String, String> colors;
  final int total;

  _PieChartPainter(this.data, this.colors, this.total);

  Color _colorFromHex(String hexColor) {
    String formatted = hexColor.replaceAll('#', '').toUpperCase();
    if (formatted.length == 6) {
      formatted = 'FF$formatted';
    }
    return Color(int.parse(formatted, radix: 16));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2; // start at top

    // Sort entries so larger slices are drawn first and are more prominent
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedEntries) {
      if (entry.value == 0) continue;
      
      final sweepAngle = (entry.value / total) * 2 * pi;
      final paint = Paint()
        ..color = _colorFromHex(colors[entry.key] ?? '000000')
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      
      // Draw a subtle border stroke between arcs for clarity
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Simple repaint rule
}
