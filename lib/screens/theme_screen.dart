import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  int _selectedColorIndex = 0;
  int? _selectedTextureIndex;
  int? _selectedSceneryIndex;

  @override
  void initState() {
    super.initState();
    final currentColor = context.read<TaskProvider>().selectedThemeColor;
    final foundIndex = _pureColors.indexWhere((c) => c.value == currentColor.value);
    if (foundIndex != -1) {
      _selectedColorIndex = foundIndex;
    }
  }

  final List<Color> _pureColors = const [
    Color(0xFF4F46E5), // Royal Indigo
    Color(0xFF2563EB), // Deep Electric Blue
    Color(0xFF06B6D4), // Cyan Teal
    Color(0xFF10B981), // Emerald Mint
    Color(0xFF8B5CF6), // Royal Purple
    Color(0xFFEC4899), // Neon Pink
    Color(0xFFF43F5E), // Rose Red
    Color(0xFFF59E0B), // Golden Amber
    Color(0xFF0F172A), // Midnight Dark Slate
    Color(0xFF14B8A6), // Premium Teal
    Color(0xFFEA580C), // Sunset Orange
    Color(0xFF6366F1), // Soft Iris
  ];

  final List<Color> _textureDots = const [
    Color(0xFF4F46E5),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ];

  final List<Map<String, dynamic>> _sceneryThemes = const [
    {
      'title': 'Blue Sky & Clouds',
      'subtitle': 'Clean daylight theme',
      'colors': [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFBAE6FD)],
      'icon': Icons.wb_sunny_rounded,
    },
    {
      'title': 'Green Meadow',
      'subtitle': 'Fresh natural greenery',
      'colors': [Color(0xFF15803D), Color(0xFF22C55E), Color(0xFF86EFAC)],
      'icon': Icons.park_rounded,
    },
    {
      'title': 'Mountain Sunrise',
      'subtitle': 'Morning warm sunrise',
      'colors': [Color(0xFFEA580C), Color(0xFFF97316), Color(0xFFFDE047)],
      'icon': Icons.landscape_rounded,
    },
    {
      'title': 'Sunny Beach',
      'subtitle': 'Ocean water & golden sand',
      'colors': [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFFFDE68A)],
      'icon': Icons.beach_access_rounded,
    },
    {
      'title': 'Lavender Valley',
      'subtitle': 'Soft floral purple fields',
      'colors': [Color(0xFF7E22CE), Color(0xFFA855F7), Color(0xFFE9D5FF)],
      'icon': Icons.local_florist_rounded,
    },
    {
      'title': 'Golden Autumn',
      'subtitle': 'Warm maple forest',
      'colors': [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFFED7AA)],
      'icon': Icons.eco_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Theme',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Pure Color Section
          const Text(
            'Pure Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Pure color grid (Rounded square swatches)
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: List.generate(_pureColors.length, (index) {
              final color = _pureColors[index];
              final isSelected = _selectedColorIndex == index;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColorIndex = index;
                    _selectedTextureIndex = null;
                    _selectedSceneryIndex = null;
                  });
                  context.read<TaskProvider>().setThemeColor(color);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(6),
                  child: isSelected
                      ? Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check, size: 14, color: color),
                        )
                      : null,
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          // 2. Texture Section
          const Text(
            'Texture',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Texture Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              final isSelected = _selectedTextureIndex == index;
              final dotColor = _textureDots[index];

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTextureIndex = index;
                    _selectedColorIndex = -1;
                    _selectedSceneryIndex = null;
                  });
                  taskProvider.setThemeColor(dotColor);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Texture Theme #${index + 1} Applied!')),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          // 3. Scenery Section
          const Text(
            'Scenery',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Scenery Cards Grid (Rich Photographic Artwork Cards)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sceneryThemes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final scene = _sceneryThemes[index];
              final isSelected = _selectedSceneryIndex == index;
              final colors = scene['colors'] as List<Color>;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSceneryIndex = index;
                    _selectedColorIndex = -1;
                    _selectedTextureIndex = null;
                  });
                  final primaryColor = colors[1];
                  taskProvider.setThemeColor(primaryColor);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(' ${scene['title']} Wallpaper Theme Applied!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                      width: isSelected ? 3.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              scene['icon'] as IconData,
                              size: 22,
                              color: colors.first,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 16, color: AppTheme.primaryBlue),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scene['title'] as String,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              scene['subtitle'] as String,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
