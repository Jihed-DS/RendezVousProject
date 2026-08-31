import 'dart:math';
import 'package:flutter/material.dart';

class PieSlice {
  final String label;
  final double value;
  final Color color;
  PieSlice({required this.label, required this.value, required this.color});
}

class SimplePieChart extends StatelessWidget {
  final List<PieSlice> slices;
  final double size;

  const SimplePieChart({super.key, required this.slices, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PiePainter(slices)),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<PieSlice> slices;
  _PiePainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    var startAngle = -pi / 2;

    for (final slice in slices) {
      final sweep = (slice.value / total) * 2 * pi;
      final paint = Paint()..color = slice.color..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    // Trou central pour un effet "donut"
    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.32, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) => oldDelegate.slices != slices;
}