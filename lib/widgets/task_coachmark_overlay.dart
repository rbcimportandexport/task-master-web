import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCoachmarkOverlay extends StatefulWidget {
  final Task task;
  final VoidCallback onDismiss;

  const TaskCoachmarkOverlay({
    super.key,
    required this.task,
    required this.onDismiss,
  });

  @override
  State<TaskCoachmarkOverlay> createState() => _TaskCoachmarkOverlayState();
}

class _TaskCoachmarkOverlayState extends State<TaskCoachmarkOverlay> {
  int _step = 0; // 0 = Drag right to complete, 1 = Long press to sort

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 70),

                // Highlighted Spotlight Task Card (Screenshots 21 & 22)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF94A3B8), width: 2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const Icon(Icons.flag_outlined, color: Color(0xFF94A3B8), size: 22),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Blue Tooltip Banner (Screenshots 21 & 22)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _step == 0
                        ? 'Drag right or click button to complete a task.'
                        : 'Long press to sort task.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Gesture Graphic Icon
                if (_step == 0) ...[
                  // Swipe Right Gesture
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app_rounded, color: Colors.white, size: 52),
                      const SizedBox(width: 6),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                ] else ...[
                  // Long Press Gesture
                  const Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.touch_app_rounded, color: Colors.white, size: 52),
                      ),
                      Icon(Icons.schedule_rounded, color: Colors.white, size: 22),
                    ],
                  ),
                ],

                const SizedBox(height: 36),

                // Action Button: "Next" on Step 0, "OK" on Step 1
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (_step == 0) {
                      setState(() => _step = 1);
                    } else {
                      widget.onDismiss();
                    }
                  },
                  child: Text(
                    _step == 0 ? 'Next' : 'OK',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
