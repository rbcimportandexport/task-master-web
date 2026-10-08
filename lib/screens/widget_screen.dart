import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WidgetScreen extends StatelessWidget {
  const WidgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Widget',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Informative Blue Banner (Screenshots 17 & 18)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFFDBEAFE),
            child: const Text(
              'Click ADD button to add widget to your Home Screen. Widget is a quick and easy way to check and create your tasks.',
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Standard (Size: 4*4)
          _buildWidgetCard(
            context: context,
            title: 'Standard',
            size: 'Size: 4*4',
            preview: Row(
              children: [
                _buildTaskBoxPreview(
                  headerColor: const Color(0xFF3B82F6),
                  title: 'Today',
                  tasks: ['Morning jogging', 'Have lunch with Jenny', 'Send email to Tim'],
                ),
                const SizedBox(width: 8),
                _buildChecklistPreview(),
              ],
            ),
          ),

          // 2. Lite (Size: 3*2)
          _buildWidgetCard(
            context: context,
            title: 'Lite',
            size: 'Size: 3*2',
            preview: Row(
              children: [
                _buildTaskBoxPreview(
                  headerColor: const Color(0xFFEC4899),
                  title: 'Today',
                  tasks: ['Morning jogging', 'Have lunch with Jenny', 'Send email to Tim'],
                ),
                const SizedBox(width: 8),
                _buildTaskBoxPreview(
                  headerColor: const Color(0xFFF472B6),
                  title: 'Today',
                  tasks: ['Have a glass of water.', 'Morning jogging', 'Have lunch with Jenny'],
                ),
              ],
            ),
          ),

          // 3. Month List (Size: 4*2)
          _buildWidgetCard(
            context: context,
            title: 'Month List',
            size: 'Size: 4*2',
            isNew: true,
            isPro: true,
            preview: _buildMonthListPreview(),
          ),

          // 4. Week (Size: 4*4)
          _buildWidgetCard(
            context: context,
            title: 'Week',
            size: 'Size: 4*4',
            isPro: true,
            preview: Row(
              children: [
                _buildTaskBoxPreview(
                  headerColor: const Color(0xFFF59E0B),
                  title: 'Tasks',
                  tasks: ['Morning jogging', 'Have lunch with Jenny', 'Send email to Tim'],
                ),
                const SizedBox(width: 8),
                _buildTaskBoxPreview(
                  headerColor: const Color(0xFFFBBF24),
                  title: 'Tasks',
                  tasks: ['Morning jogging', 'Have lunch with Jenny', 'Send email to Tim'],
                ),
              ],
            ),
          ),

          // 5. Month (Size: 4*4)
          _buildWidgetCard(
            context: context,
            title: 'Month',
            size: 'Size: 4*4',
            preview: Row(
              children: [
                _buildMiniCalendarPreview(isDark: false),
                const SizedBox(width: 8),
                _buildMiniCalendarPreview(isDark: true),
              ],
            ),
          ),

          // 6. Month View (Size: 4*5)
          _buildWidgetCard(
            context: context,
            title: 'Month View',
            size: 'Size: 4*5',
            isNew: true,
            isPro: true,
            preview: Row(
              children: [
                _buildMiniCalendarPreview(isDark: false),
                const SizedBox(width: 8),
                _buildMiniCalendarPreview(isDark: true),
              ],
            ),
          ),

          // 7. Count Down (Size: 4*1)
          _buildWidgetCard(
            context: context,
            title: 'Count Down',
            size: 'Size: 4*1',
            isPro: true,
            preview: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cake_outlined, color: Colors.pink, size: 20),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mom's Birthday", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('2026/08/15', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  Spacer(),
                  Text(
                    '123 D',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ),

          // 8. Quick Capture (Size: 2*2) [NEW]
          _buildWidgetCard(
            context: context,
            title: 'Quick Capture',
            size: 'Size: 2*2',
            isNew: true,
            preview: Row(
              children: [
                _buildQuickCaptureBox(isDark: false),
                const SizedBox(width: 8),
                _buildQuickCaptureBox(isDark: true),
              ],
            ),
          ),

          // 9. Add Task Shortcut
          _buildWidgetCard(
            context: context,
            title: 'Add Task',
            size: 'Shortcut',
            preview: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.add, color: AppTheme.primaryBlue, size: 30),
            ),
          ),

          // 10. Smart Create Shortcut [NEW]
          _buildWidgetCard(
            context: context,
            title: 'Smart Create',
            size: 'Shortcut',
            isNew: true,
            isPro: true,
            preview: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFA855F7), size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetCard({
    required BuildContext context,
    required String title,
    required String size,
    bool isNew = false,
    bool isPro = false,
    required Widget preview,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Info & ADD Button
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      size,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"$title" Widget has been added to your Home Screen!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      child: const Text('ADD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Right: Preview Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: preview,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBoxPreview({
    required Color headerColor,
    required String title,
    required List<String> tasks,
  }) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              ),
              alignment: Alignment.centerLeft,
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tasks.map((t) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.circle_outlined, size: 6, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              t,
                              style: const TextStyle(fontSize: 7, color: Color(0xFF475569)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistPreview() {
    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('1. Have a glass of water.', style: TextStyle(fontSize: 6, color: Colors.blue)),
            Text('2. Morning jogging', style: TextStyle(fontSize: 6, color: Colors.green)),
            Text('3. Have lunch with Jenny', style: TextStyle(fontSize: 6, color: Colors.orange)),
            Text('4. Send email to Tim', style: TextStyle(fontSize: 6, color: Colors.purple)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthListPreview() {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              '< August 2026 >\nS M T W T F S\n1 2 3 4 5 6 7\n8 9 10 11 12 13 14\n15 16 17 18 19 20 21',
              style: TextStyle(fontSize: 6, height: 1.3, color: Color(0xFF475569)),
            ),
          ),
          VerticalDivider(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('20 Wed', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                Text(' Grandma\'s Birthday', style: TextStyle(fontSize: 6)),
                Text(' Send Email', style: TextStyle(fontSize: 6)),
                Text(' Morning Jogging', style: TextStyle(fontSize: 6, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendarPreview({required bool isDark}) {
    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              'AUG. 2026',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 28,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                itemBuilder: (_, i) => Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 6,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCaptureBox({required bool isDark}) {
    return Expanded(
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "What's today's\nplan?",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 12, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, size: 12, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
