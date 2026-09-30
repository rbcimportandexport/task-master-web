import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  CategoryItem({
    required this.id,
    required this.name,
    this.icon = Icons.folder_outlined,
    this.color = const Color(0xFF2F80ED),
  });

  static List<CategoryItem> defaultCategories = [
    CategoryItem(id: 'all', name: 'All', icon: Icons.all_inclusive, color: const Color(0xFF2F80ED)),
    CategoryItem(id: 'work', name: 'Work', icon: Icons.work_outline, color: const Color(0xFF3B82F6)),
    CategoryItem(id: 'personal', name: 'Personal', icon: Icons.person_outline, color: const Color(0xFF10B981)),
    CategoryItem(id: 'wishlist', name: 'Wishlist', icon: Icons.favorite_border, color: const Color(0xFFEC4899)),
    CategoryItem(id: 'birthday', name: 'Birthday', icon: Icons.cake_outlined, color: const Color(0xFFF59E0B)),
  ];
}
