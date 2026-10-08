import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.id,
    required this.name,
    this.icon = Icons.folder_outlined,
    this.color = const Color(0xFF2F80ED),
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconName': _getIconName(icon),
    'colorValue': color.value,
  };

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    icon: _getIconFromName(json['iconName'] ?? ''),
    color: Color(json['colorValue'] ?? 0xFF2F80ED),
  );

  static String _getIconName(IconData icon) {
    if (icon == Icons.all_inclusive) return 'all_inclusive';
    if (icon == Icons.work_outline) return 'work_outline';
    if (icon == Icons.person_outline) return 'person_outline';
    if (icon == Icons.favorite_border) return 'favorite_border';
    if (icon == Icons.cake_outlined) return 'cake_outlined';
    if (icon == Icons.star_border) return 'star_border';
    if (icon == Icons.shopping_bag_outlined) return 'shopping_bag_outlined';
    return 'folder_outlined';
  }

  static IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'all_inclusive':
        return Icons.all_inclusive;
      case 'work_outline':
        return Icons.work_outline;
      case 'person_outline':
        return Icons.person_outline;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'cake_outlined':
        return Icons.cake_outlined;
      case 'star_border':
        return Icons.star_border;
      case 'shopping_bag_outlined':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  static const List<CategoryItem> defaultCategories = [
    CategoryItem(id: 'all', name: 'All', icon: Icons.all_inclusive, color: Color(0xFF2F80ED)),
    CategoryItem(id: 'work', name: 'Work', icon: Icons.work_outline, color: Color(0xFF3B82F6)),
  ];
}
