import 'dart:math';
import 'package:flutter/material.dart';

class PieProgressIndicator extends StatelessWidget {
  final double value;
  final double size;
  final Color backgroundColor;
  final Color color;

  const PieProgressIndicator({
    super.key,
    required this.value,
    this.size = 24.0,
    required this.backgroundColor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PieProgressPainter(
          value: value,
          backgroundColor: backgroundColor,
          color: color,
        ),
      ),
    );
  }
}

class _PieProgressPainter extends CustomPainter {
  final double value;
  final Color backgroundColor;
  final Color color;

  _PieProgressPainter({
    required this.value,
    required this.backgroundColor,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    // Draw background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress pie slice
    if (value > 0.0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
        
      final sweepAngle = 2 * pi * value;
      // -pi/2 starts the pie slice at the top (12 o'clock)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        true, // useCenter = true creates a pie slice
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PieProgressPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.color != color;
  }
}
