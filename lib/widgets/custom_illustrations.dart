import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'character_base64.dart';

/// Empty state illustration for "All" tab: Person looking at smartphone
class PersonWithPhoneIllustration extends StatelessWidget {
  final double size;
  const PersonWithPhoneIllustration({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(kCharacterImageBase64);
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size),
            painter: _PersonWithPhonePainter(),
          );
        },
      );
    } catch (_) {
      return Image.asset(
        'assets/images/empty_tasks_character.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size),
            painter: _PersonWithPhonePainter(),
          );
        },
      );
    }
  }
}

class _PersonWithPhonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark base shadow
    final baseShadowPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final shadowPath = Path()
      ..moveTo(w * 0.25, h * 0.78)
      ..cubicTo(w * 0.35, h * 0.92, w * 0.65, h * 0.92, w * 0.75, h * 0.78)
      ..cubicTo(w * 0.6, h * 0.72, w * 0.35, h * 0.72, w * 0.25, h * 0.78)
      ..close();
    canvas.drawPath(shadowPath, baseShadowPaint);

    // Body / Shirt (Light blue with pattern)
    final shirtPaint = Paint()
      ..color = const Color(0xFFBFDBFE)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bodyPath = Path()
      ..moveTo(w * 0.35, h * 0.78)
      ..cubicTo(w * 0.32, h * 0.65, w * 0.38, h * 0.58, w * 0.48, h * 0.55)
      ..lineTo(w * 0.60, h * 0.55)
      ..cubicTo(w * 0.68, h * 0.58, w * 0.72, h * 0.66, w * 0.68, h * 0.78)
      ..close();
    canvas.drawPath(bodyPath, shirtPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // Arm holding phone
    final skinPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    final armPath = Path()
      ..moveTo(w * 0.38, h * 0.70)
      ..cubicTo(w * 0.45, h * 0.78, w * 0.58, h * 0.72, w * 0.62, h * 0.58)
      ..cubicTo(w * 0.58, h * 0.58, w * 0.52, h * 0.64, w * 0.44, h * 0.66)
      ..close();
    canvas.drawPath(armPath, skinPaint);
    canvas.drawPath(armPath, strokePaint);

    // Smartphone
    final phonePaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.fill;
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.66, h * 0.54), width: w * 0.12, height: h * 0.20),
      const Radius.circular(5),
    );
    canvas.drawRRect(phoneRect, phonePaint);
    canvas.drawRRect(phoneRect, strokePaint);

    // Head / Neck
    final neckPath = Path()
      ..moveTo(w * 0.50, h * 0.55)
      ..lineTo(w * 0.50, h * 0.48)
      ..lineTo(w * 0.55, h * 0.48)
      ..lineTo(w * 0.55, h * 0.55);
    canvas.drawPath(neckPath, strokePaint);

    final headOval = Rect.fromCenter(center: Offset(w * 0.53, h * 0.45), width: w * 0.16, height: h * 0.18);
    canvas.drawOval(headOval, skinPaint);
    canvas.drawOval(headOval, strokePaint);

    // Hair (Dark blue / black wavy hair)
    final hairPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final hairPath = Path()
      ..moveTo(w * 0.46, h * 0.46)
      ..cubicTo(w * 0.42, h * 0.38, w * 0.50, h * 0.32, w * 0.58, h * 0.36)
      ..cubicTo(w * 0.62, h * 0.38, w * 0.60, h * 0.44, w * 0.55, h * 0.44)
      ..cubicTo(w * 0.50, h * 0.40, w * 0.46, h * 0.42, w * 0.46, h * 0.46)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Facial features (Stylized dot eye & smile)
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.56, h * 0.44), 2.0, eyePaint);

    final smilePath = Path()
      ..moveTo(w * 0.56, h * 0.48)
      ..quadraticBezierTo(w * 0.58, h * 0.50, w * 0.60, h * 0.48);
    canvas.drawPath(smilePath, strokePaint..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Empty state illustration for "Work / Categories" tab: Girl with Laptop
class GirlWithLaptopIllustration extends StatelessWidget {
  final double size;
  const GirlWithLaptopIllustration({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(kGirlWithLaptopImageBase64);
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size),
            painter: _GirlWithLaptopPainter(),
          );
        },
      );
    } catch (_) {
      return Image.asset(
        'assets/images/girl_laptop_character.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size),
            painter: _GirlWithLaptopPainter(),
          );
        },
      );
    }
  }
}

class _GirlWithLaptopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark base shadow
    final baseShadowPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final shadowPath = Path()
      ..moveTo(w * 0.22, h * 0.78)
      ..cubicTo(w * 0.35, h * 0.88, w * 0.68, h * 0.88, w * 0.78, h * 0.78)
      ..cubicTo(w * 0.65, h * 0.70, w * 0.35, h * 0.70, w * 0.22, h * 0.78)
      ..close();
    canvas.drawPath(shadowPath, baseShadowPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final skinPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    // Flowing dark hair (Back)
    final hairPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final hairPath = Path()
      ..moveTo(w * 0.45, h * 0.45)
      ..cubicTo(w * 0.42, h * 0.30, w * 0.60, h * 0.28, w * 0.70, h * 0.42)
      ..cubicTo(w * 0.76, h * 0.52, w * 0.72, h * 0.65, w * 0.65, h * 0.68)
      ..cubicTo(w * 0.55, h * 0.62, w * 0.58, h * 0.48, w * 0.45, h * 0.45)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Body / White top with line patterns
    final bodyPath = Path()
      ..moveTo(w * 0.36, h * 0.76)
      ..cubicTo(w * 0.35, h * 0.60, w * 0.44, h * 0.52, w * 0.55, h * 0.52)
      ..cubicTo(w * 0.65, h * 0.54, w * 0.68, h * 0.64, w * 0.66, h * 0.76)
      ..close();
    canvas.drawPath(bodyPath, skinPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // Arm leaning on laptop
    final armPath = Path()
      ..moveTo(w * 0.42, h * 0.66)
      ..cubicTo(w * 0.48, h * 0.74, w * 0.58, h * 0.70, w * 0.62, h * 0.62);
    canvas.drawPath(armPath, strokePaint);

    // Laptop (Blue with white circle logo)
    final laptopPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.fill;
    final laptopPath = Path()
      ..moveTo(w * 0.25, h * 0.66)
      ..lineTo(w * 0.44, h * 0.65)
      ..lineTo(w * 0.48, h * 0.78)
      ..lineTo(w * 0.28, h * 0.79)
      ..close();
    canvas.drawPath(laptopPath, laptopPaint);
    canvas.drawPath(laptopPath, strokePaint);

    // Laptop logo
    canvas.drawCircle(Offset(w * 0.36, h * 0.71), 4, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.36, h * 0.71), 4, strokePaint..strokeWidth = 1.5);

    // Head
    final headRect = Rect.fromCenter(center: Offset(w * 0.50, h * 0.44), width: w * 0.16, height: h * 0.18);
    canvas.drawOval(headRect, skinPaint);
    canvas.drawOval(headRect, strokePaint);

    // Eye & Smile
    canvas.drawCircle(Offset(w * 0.47, h * 0.44), 2.0, Paint()..color = const Color(0xFF0F172A));
    final smilePath = Path()
      ..moveTo(w * 0.46, h * 0.48)
      ..quadraticBezierTo(w * 0.48, h * 0.50, w * 0.50, h * 0.48);
    canvas.drawPath(smilePath, strokePaint..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Decorative 3D Calendar and Water Glass stickers for Calendar View
class CalendarStickerIllustration extends StatelessWidget {
  final double size;
  const CalendarStickerIllustration({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.8),
      painter: _CalendarStickerPainter(),
    );
  }
}

class _CalendarStickerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Calendar Stand (Desk Calendar)
    final calendarPaint = Paint()..color = const Color(0xFFF8FAFC);
    final gridBorder = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final calPath = Path()
      ..moveTo(w * 0.35, h * 0.25)
      ..lineTo(w * 0.90, h * 0.20)
      ..lineTo(w * 0.96, h * 0.85)
      ..lineTo(w * 0.40, h * 0.90)
      ..close();
    canvas.drawPath(calPath, calendarPaint);
    canvas.drawPath(calPath, gridBorder);

    // Lavender header
    final headerPaint = Paint()..color = const Color(0xFFF3E8FF);
    final headPath = Path()
      ..moveTo(w * 0.35, h * 0.25)
      ..lineTo(w * 0.90, h * 0.20)
      ..lineTo(w * 0.91, h * 0.35)
      ..lineTo(w * 0.36, h * 0.40)
      ..close();
    canvas.drawPath(headPath, headerPaint);

    // Calendar spiral rings
    final ringPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (int i = 0; i < 5; i++) {
      final rx = w * (0.42 + i * 0.10);
      final ry = h * (0.24 - i * 0.01);
      canvas.drawArc(Rect.fromCenter(center: Offset(rx, ry), width: 8, height: 12), -math.pi * 0.8, math.pi * 1.6, false, ringPaint);
    }

    // Days grid text simulated (27, 28, 29)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final style = const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.bold);

    textPainter.text = TextSpan(text: '27', style: style);
    textPainter.layout();
    textPainter.paint(canvas, Offset(w * 0.44, h * 0.48));

    textPainter.text = TextSpan(text: '28', style: style);
    textPainter.layout();
    textPainter.paint(canvas, Offset(w * 0.62, h * 0.46));

    textPainter.text = TextSpan(text: '29', style: style);
    textPainter.layout();
    textPainter.paint(canvas, Offset(w * 0.80, h * 0.44));

    // Water Glass Sticker on left (with "1")
    final glassPaint = Paint()..color = const Color(0xFFBFDBFE);
    final glassPath = Path()
      ..moveTo(w * 0.08, h * 0.58)
      ..lineTo(w * 0.28, h * 0.58)
      ..lineTo(w * 0.24, h * 0.88)
      ..lineTo(w * 0.12, h * 0.88)
      ..close();
    canvas.drawPath(glassPath, glassPaint);

    final glassWater = Paint()..color = const Color(0xFF93C5FD);
    final waterPath = Path()
      ..moveTo(w * 0.10, h * 0.68)
      ..lineTo(w * 0.26, h * 0.68)
      ..lineTo(w * 0.23, h * 0.86)
      ..lineTo(w * 0.13, h * 0.86)
      ..close();
    canvas.drawPath(waterPath, glassWater);

    textPainter.text = const TextSpan(text: '1', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.bold));
    textPainter.layout();
    textPainter.paint(canvas, Offset(w * 0.16, h * 0.70));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft Globe Background for Welcome Screen
class GlobeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final globePaint = Paint()
      ..color = const Color(0xFFE0F2FE).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Draw bottom spherical arch
    final globeCenter = Offset(w * 0.5, h * 1.3);
    final radius = w * 0.85;
    canvas.drawCircle(globeCenter, radius, globePaint);

    final continentPaint = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Simulated subtle continents
    final cPath = Path()
      ..moveTo(w * 0.15, h * 0.78)
      ..quadraticBezierTo(w * 0.30, h * 0.72, w * 0.45, h * 0.76)
      ..quadraticBezierTo(w * 0.40, h * 0.86, w * 0.20, h * 0.88)
      ..close();
    canvas.drawPath(cPath, continentPaint);

    final cPath2 = Path()
      ..moveTo(w * 0.55, h * 0.75)
      ..quadraticBezierTo(w * 0.75, h * 0.70, w * 0.90, h * 0.80)
      ..quadraticBezierTo(w * 0.80, h * 0.90, w * 0.60, h * 0.85)
      ..close();
    canvas.drawPath(cPath2, continentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Celebration Illustration for "First Task Completed" (Screenshot 23)
class CelebrationIllustration extends StatelessWidget {
  final double size;
  const CelebrationIllustration({super.key, this.size = 220});

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(kCelebrationImageBase64);
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size * 0.9),
            painter: _CelebrationPainter(),
          );
        },
      );
    } catch (_) {
      return Image.asset(
        'assets/images/celebration_first_task.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size * 0.9),
            painter: _CelebrationPainter(),
          );
        },
      );
    }
  }
}

class _CelebrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark base shadow
    final baseShadowPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final shadowPath = Path()
      ..moveTo(w * 0.30, h * 0.88)
      ..cubicTo(w * 0.40, h * 0.98, w * 0.60, h * 0.98, w * 0.70, h * 0.88)
      ..cubicTo(w * 0.60, h * 0.82, w * 0.40, h * 0.82, w * 0.30, h * 0.88)
      ..close();
    canvas.drawPath(shadowPath, baseShadowPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final skinPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    // Body / Shirt (Light Blue)
    final shirtPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.fill;

    final bodyPath = Path()
      ..moveTo(w * 0.35, h * 0.88)
      ..cubicTo(w * 0.30, h * 0.70, w * 0.38, h * 0.60, w * 0.50, h * 0.58)
      ..cubicTo(w * 0.62, h * 0.60, w * 0.70, h * 0.70, w * 0.65, h * 0.88)
      ..close();
    canvas.drawPath(bodyPath, shirtPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // Left raised arm
    final leftArmPath = Path()
      ..moveTo(w * 0.38, h * 0.62)
      ..cubicTo(w * 0.28, h * 0.52, w * 0.22, h * 0.42, w * 0.16, h * 0.28)
      ..cubicTo(w * 0.22, h * 0.25, w * 0.26, h * 0.32, w * 0.36, h * 0.55);
    canvas.drawPath(leftArmPath, skinPaint);
    canvas.drawPath(leftArmPath, strokePaint);

    // Right raised arm
    final rightArmPath = Path()
      ..moveTo(w * 0.62, h * 0.62)
      ..cubicTo(w * 0.72, h * 0.52, w * 0.78, h * 0.42, w * 0.84, h * 0.28)
      ..cubicTo(w * 0.78, h * 0.25, w * 0.74, h * 0.32, w * 0.64, h * 0.55);
    canvas.drawPath(rightArmPath, skinPaint);
    canvas.drawPath(rightArmPath, strokePaint);

    // Left hand open
    final leftHand = Path()
      ..moveTo(w * 0.16, h * 0.28)
      ..lineTo(w * 0.14, h * 0.22)
      ..lineTo(w * 0.17, h * 0.21)
      ..lineTo(w * 0.20, h * 0.22)
      ..lineTo(w * 0.22, h * 0.25);
    canvas.drawPath(leftHand, strokePaint);

    // Right hand open
    final rightHand = Path()
      ..moveTo(w * 0.84, h * 0.28)
      ..lineTo(w * 0.86, h * 0.22)
      ..lineTo(w * 0.83, h * 0.21)
      ..lineTo(w * 0.80, h * 0.22)
      ..lineTo(w * 0.78, h * 0.25);
    canvas.drawPath(rightHand, strokePaint);

    // Head
    final headRect = Rect.fromCenter(center: Offset(w * 0.50, h * 0.48), width: w * 0.16, height: h * 0.18);
    canvas.drawOval(headRect, skinPaint);
    canvas.drawOval(headRect, strokePaint);

    // Hair
    final hairPaint = Paint()..color = const Color(0xFF0F172A);
    final hairPath = Path()
      ..moveTo(w * 0.42, h * 0.48)
      ..cubicTo(w * 0.38, h * 0.38, w * 0.46, h * 0.32, w * 0.54, h * 0.36)
      ..cubicTo(w * 0.60, h * 0.38, w * 0.58, h * 0.46, w * 0.52, h * 0.46)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Happy face (Dot eye & big smile)
    canvas.drawCircle(Offset(w * 0.54, h * 0.46), 2.2, hairPaint);
    final smilePath = Path()
      ..moveTo(w * 0.52, h * 0.50)
      ..quadraticBezierTo(w * 0.54, h * 0.54, w * 0.58, h * 0.50);
    canvas.drawPath(smilePath, strokePaint..strokeWidth = 2.0);

    // Confetti particles
    final confettiColors = [
      const Color(0xFFFBBF24), // Yellow
      const Color(0xFFEF4444), // Red
      const Color(0xFF10B981), // Green
      const Color(0xFFA855F7), // Purple
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFFB923C), // Orange
    ];

    final confettiPaints = confettiColors.map((c) => Paint()..color = c).toList();

    // Ribbons and stars
    canvas.drawRect(Rect.fromLTWH(w * 0.22, h * 0.15, 6, 12), confettiPaints[0]);
    canvas.drawRect(Rect.fromLTWH(w * 0.75, h * 0.18, 10, 6), confettiPaints[1]);
    canvas.drawCircle(Offset(w * 0.30, h * 0.22), 4, confettiPaints[2]);
    canvas.drawCircle(Offset(w * 0.70, h * 0.26), 4, confettiPaints[3]);
    canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.12, 8, 4), confettiPaints[4]);
    canvas.drawCircle(Offset(w * 0.62, h * 0.14), 3, confettiPaints[5]);
    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.45, 10, 5), confettiPaints[3]);
    canvas.drawCircle(Offset(w * 0.78, h * 0.52), 4, confettiPaints[2]);
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.60, 8, 6), confettiPaints[0]);
    canvas.drawCircle(Offset(w * 0.85, h * 0.62), 4, confettiPaints[4]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration for "Smart Voice Create" (Person speaking with soundwaves into phone)
class VoiceCreateIllustration extends StatelessWidget {
  final double size;
  const VoiceCreateIllustration({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(kVoiceCreateImageBase64);
      return Image.memory(
        bytes,
        width: size * 1.3,
        height: size * 0.9,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size * 0.75),
            painter: _VoiceCreatePainter(),
          );
        },
      );
    } catch (_) {
      return Image.asset(
        'assets/images/voice_create_character.png',
        width: size * 1.3,
        height: size * 0.9,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size * 0.75),
            painter: _VoiceCreatePainter(),
          );
        },
      );
    }
  }
}

class _VoiceCreatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final skinPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    // Body / Shirt (Light Purple / Lavender)
    final shirtPaint = Paint()
      ..color = const Color(0xFFDDD6FE)
      ..style = PaintingStyle.fill;

    final bodyPath = Path()
      ..moveTo(w * 0.22, h * 0.98)
      ..cubicTo(w * 0.20, h * 0.70, w * 0.35, h * 0.58, w * 0.48, h * 0.58)
      ..cubicTo(w * 0.62, h * 0.58, w * 0.72, h * 0.70, w * 0.70, h * 0.98)
      ..close();
    canvas.drawPath(bodyPath, shirtPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // Hand holding phone
    final handPath = Path()
      ..moveTo(w * 0.58, h * 0.98)
      ..lineTo(w * 0.62, h * 0.68)
      ..lineTo(w * 0.72, h * 0.68)
      ..lineTo(w * 0.68, h * 0.98)
      ..close();
    canvas.drawPath(handPath, skinPaint);
    canvas.drawPath(handPath, strokePaint);

    // Smartphone (Vibrant Blue)
    final phonePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.60, h * 0.44, w * 0.14, h * 0.32),
      const Radius.circular(8),
    );
    canvas.drawRRect(phoneRect, phonePaint);
    canvas.drawRRect(phoneRect, strokePaint);

    // Head / Neck
    final neckPath = Path()
      ..moveTo(w * 0.42, h * 0.58)
      ..lineTo(w * 0.42, h * 0.46)
      ..lineTo(w * 0.50, h * 0.46)
      ..lineTo(w * 0.50, h * 0.58);
    canvas.drawPath(neckPath, strokePaint);

    final headRect = Rect.fromCenter(center: Offset(w * 0.46, h * 0.36), width: w * 0.18, height: h * 0.24);
    canvas.drawOval(headRect, skinPaint);
    canvas.drawOval(headRect, strokePaint);

    // Hair
    final hairPaint = Paint()..color = const Color(0xFF0F172A);
    final hairPath = Path()
      ..moveTo(w * 0.38, h * 0.36)
      ..cubicTo(w * 0.34, h * 0.22, w * 0.44, h * 0.18, w * 0.52, h * 0.22)
      ..cubicTo(w * 0.58, h * 0.24, w * 0.56, h * 0.32, w * 0.48, h * 0.32)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Eye & Open Mouth (Speaking)
    canvas.drawCircle(Offset(w * 0.49, h * 0.34), 2.2, hairPaint);

    final mouthPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.51, h * 0.40), width: 8, height: 6),
      0,
      3.14,
      true,
      mouthPaint,
    );

    // Soundwaves
    final wavePaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final waves = [
      Offset(w * 0.53, h * 0.40),
      Offset(w * 0.55, h * 0.40),
      Offset(w * 0.57, h * 0.40),
      Offset(w * 0.59, h * 0.40),
    ];
    final heights = [6.0, 16.0, 10.0, 18.0];

    for (int i = 0; i < waves.length; i++) {
      canvas.drawLine(
        Offset(waves[i].dx, waves[i].dy - heights[i] / 2),
        Offset(waves[i].dx, waves[i].dy + heights[i] / 2),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


