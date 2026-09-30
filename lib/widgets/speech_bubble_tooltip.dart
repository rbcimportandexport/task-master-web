import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpeechBubbleTooltip extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const SpeechBubbleTooltip({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.tooltipYellow,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.tooltipText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Downward pointer arrow pointing to the FAB on the right
          Padding(
            padding: const EdgeInsets.only(right: 28),
            child: CustomPaint(
              size: const Size(18, 10),
              painter: _SpeechTailPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.tooltipYellow
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.8, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
