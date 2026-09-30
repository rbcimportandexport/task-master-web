import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnnualHeatmapCard extends StatefulWidget {
  final int taskCount;
  const AnnualHeatmapCard({super.key, this.taskCount = 0});

  @override
  State<AnnualHeatmapCard> createState() => _AnnualHeatmapCardState();
}

class _AnnualHeatmapCardState extends State<AnnualHeatmapCard> {
  String _selectedYear = '2026';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Annual Heatmap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedYear,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                  items: ['2025', '2026', '2027'].map((y) {
                    return DropdownMenuItem(
                      value: y,
                      child: Text(
                        y,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedYear = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Heatmap Matrix with Stack
          Stack(
            alignment: Alignment.center,
            children: [
              // Heatmap grid with Days of week on left and Month labels on bottom
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Days of week
                  SizedBox(
                    height: 110,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Sun', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                        Text('Mon', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                        Text('Tue', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                        Text('Wed', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                        Text('Thu', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                        Text('Fri', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                        Text('Sat', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Weeks Grid
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 110,
                          child: GridView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 22 * 7,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 3,
                              crossAxisSpacing: 3,
                            ),
                            itemBuilder: (context, index) {
                              int intensity = 0;
                              if (widget.taskCount > 0) {
                                // Pseudo-random generation for realistic heatmap clusters
                                // Uses prime numbers to create organic looking scatter
                                int seed = (index * 37 + 13) % 100;
                                if (seed < 50) {
                                  intensity = 0; // Empty
                                } else if (seed < 75) {
                                  intensity = 1; // Light
                                } else if (seed < 90) {
                                  intensity = 2; // Medium
                                } else {
                                  intensity = 3; // High
                                }
                              }
                              
                              Color color;
                              switch (intensity) {
                                case 1: color = const Color(0xFF93C5FD); break; // Light Blue
                                case 2: color = const Color(0xFF3B82F6); break; // Blue
                                case 3: color = const Color(0xFF1D4ED8); break; // Dark Blue
                                default: color = const Color(0xFFE2E8F0); break; // Empty Gray
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Months label
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Aug', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                            Text('Sep', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                            Text('Oct', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                            Text('Nov', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                            Text('Dec', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Overlay pill when 0 tasks
              if (widget.taskCount == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'No Task Data',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
