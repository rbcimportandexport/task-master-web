import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/custom_illustrations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFE),
      body: Stack(
        children: [
          // Globe Background at the bottom
          Positioned.fill(
            child: CustomPaint(
              painter: GlobeBackgroundPainter(),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // Title: "Welcome to To-do List"
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text: 'Welcome to ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'To-do List',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Feature Cards List
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildFeatureItem(
                          icon: Icons.task_alt_rounded,
                          iconColor: const Color(0xFF0284C7),
                          iconBg: const Color(0xFFE0F2FE),
                          title: 'Create Tasks Quickly and Easily',
                          subtitle: 'Input tasks, subtasks and repetitive tasks.',
                        ),
                        const SizedBox(height: 28),
                        _buildFeatureItem(
                          icon: Icons.alarm_rounded,
                          iconColor: const Color(0xFFEA580C),
                          iconBg: const Color(0xFFFFEDD5),
                          title: 'Task Reminders',
                          subtitle: 'Set reminders, and never miss important things.',
                        ),
                        const SizedBox(height: 28),
                        _buildFeatureItem(
                          icon: Icons.grid_view_rounded,
                          iconColor: const Color(0xFF4F46E5),
                          iconBg: const Color(0xFFEEF2FF),
                          title: 'Personalized Widgets',
                          subtitle: 'Create widgets, and view your tasks more easily.',
                        ),
                        const SizedBox(height: 28),
                        _buildFeatureItem(
                          icon: Icons.palette_rounded,
                          iconColor: const Color(0xFFDB2777),
                          iconBg: const Color(0xFFFCE7F3),
                          title: 'Custom Themes',
                          subtitle: 'Choose the theme you like and start your wonderful day',
                        ),
                      ],
                    ),
                  ),

                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: () {
                          context.read<TaskProvider>().completeOnboarding();
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CONTINUE',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '>>>',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
