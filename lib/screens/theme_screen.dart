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

  final List<Color> _pureColors = const [
    Color(0xFF60A5FA), // Light Blue (Default)
    Color(0xFFF472B6), // Light Pink
    Color(0xFF14B8A6), // Teal / Emerald
    Color(0xFF334155), // Dark Slate
    Color(0xFFF87171), // Coral Red
    Color(0xFFFACC15), // Mustard Yellow
    Color(0xFF10B981), // Green
    Color(0xFFFB923C), // Orange
    Color(0xFFA855F7), // Purple
  ];

  final List<Color> _textureDots = const [
    Color(0xFF60A5FA),
    Color(0xFFEF4444),
    Color(0xFFA855F7),
    Color(0xFF10B981),
  ];

  final List<Map<String, dynamic>> _sceneryThemes = const [
    {
      'title': 'Lighthouse',
      'colors': [Color(0xFF38BDF8), Color(0xFFE0F2FE)],
      'icon': Icons.wb_sunny_rounded,
    },
    {
      'title': 'Spring Park',
      'colors': [Color(0xFF86EFAC), Color(0xFFDCFCE7)],
      'icon': Icons.park_rounded,
    },
    {
      'title': 'Starry Night',
      'colors': [Color(0xFF1E1B4B), Color(0xFF312E81)],
      'icon': Icons.nightlight_round,
    },
    {
      'title': 'Cherry Blossom',
      'colors': [Color(0xFFFBCFE8), Color(0xFFFDF2F8)],
      'icon': Icons.local_florist_rounded,
    },
    {
      'title': 'Green Valley',
      'colors': [Color(0xFF4ADE80), Color(0xFFBBF7D0)],
      'icon': Icons.terrain_rounded,
    },
    {
      'title': 'Cycling Day',
      'colors': [Color(0xFF38BDF8), Color(0xFFBAE6FD)],
      'icon': Icons.directions_bike_rounded,
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

          // Scenery Cards Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sceneryThemes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final scene = _sceneryThemes[index];
              final isSelected = _selectedSceneryIndex == index;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSceneryIndex = index;
                    _selectedColorIndex = -1;
                    _selectedTextureIndex = null;
                  });
                  final primaryColor = (scene['colors'] as List<Color>).first;
                  taskProvider.setThemeColor(primaryColor);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${scene['title']} Wallpaper Theme Applied!')),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: scene['colors'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      width: isSelected ? 2.5 : 0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          scene['icon'] as IconData,
                          size: 38,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 10,
                        child: Text(
                          scene['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black45),
                            ],
                          ),
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
