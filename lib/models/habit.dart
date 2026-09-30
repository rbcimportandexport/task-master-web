import 'package:flutter/material.dart';

class HabitPreset {
  final String title;
  final String category;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const HabitPreset({
    required this.title,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  static const List<HabitPreset> presets = [
    HabitPreset(
      title: 'Drink water, keep healthy',
      category: 'Health',
      icon: Icons.local_drink_rounded,
      iconColor: Color(0xFF38BDF8),
      bgColor: Color(0xFFE0F2FE),
    ),
    HabitPreset(
      title: 'Study',
      category: 'Study',
      icon: Icons.school_rounded,
      iconColor: Color(0xFF6366F1),
      bgColor: Color(0xFFEEF2FF),
    ),
    HabitPreset(
      title: 'Go to bed early',
      category: 'Health',
      icon: Icons.bedtime_rounded,
      iconColor: Color(0xFFFBBF24),
      bgColor: Color(0xFFFEF3C7),
    ),
    HabitPreset(
      title: 'Keep reading',
      category: 'Personal',
      icon: Icons.menu_book_rounded,
      iconColor: Color(0xFF4ADE80),
      bgColor: Color(0xFFDCFCE7),
    ),
    HabitPreset(
      title: 'Go exercising',
      category: 'Fitness',
      icon: Icons.directions_run_rounded,
      iconColor: Color(0xFF0EA5E9),
      bgColor: Color(0xFFE0F2FE),
    ),
  ];
}
