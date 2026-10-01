import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:todo_list/theme/app_theme.dart';
import 'package:todo_list/widgets/analytics_charts.dart';
import 'package:todo_list/models/task.dart';
import 'package:todo_list/widgets/voice_note_player.dart';

void main() {
  test('AppTheme color token test', () {
    expect(AppTheme.primaryBlue, isNotNull);
    expect(AppTheme.background, isNotNull);
  });
  testWidgets('Section 2 metric cards test across narrow and desktop widths', (WidgetTester tester) async {
    for (final width in [1200.0, 800.0, 600.0, 400.0, 350.0, 300.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 650;
                    final card1 = Container(
                      constraints: BoxConstraints(minHeight: isCompact ? 120 : 190),
                      padding: EdgeInsets.symmetric(
                        vertical: isCompact ? 24 : 48,
                        horizontal: isCompact ? 24 : 36,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Completed Tasks',
                                  style: TextStyle(
                                    fontSize: isCompact ? 16 : 18,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isCompact ? 8 : 14),
                                Text(
                                  '1',
                                  style: TextStyle(
                                    fontSize: isCompact ? 38 : 54,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(isCompact ? 14 : 22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.task_alt_rounded, color: Colors.white, size: isCompact ? 32 : 46),
                          ),
                        ],
                      ),
                    );

                    final card2 = Container(
                      constraints: BoxConstraints(minHeight: isCompact ? 120 : 190),
                      padding: EdgeInsets.symmetric(
                        vertical: isCompact ? 24 : 48,
                        horizontal: isCompact ? 24 : 36,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Pending Tasks',
                                  style: TextStyle(
                                    fontSize: isCompact ? 16 : 18,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isCompact ? 8 : 14),
                                Text(
                                  '2',
                                  style: TextStyle(
                                    fontSize: isCompact ? 38 : 54,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(isCompact ? 14 : 22),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: isCompact ? 32 : 46),
                          ),
                        ],
                      ),
                    );

                    if (isCompact) {
                      return Column(
                        children: [
                          card1,
                          const SizedBox(height: 16),
                          card2,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: card1),
                        const SizedBox(width: 24),
                        Expanded(child: card2),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('Section 2 metric cards passed at width: $width');
    }
  });


  testWidgets('All analytics cards at narrow widths (450, 350, 300, 250)', (WidgetTester tester) async {
    for (final width in [450.0, 350.0, 300.0, 250.0]) {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: const [
                  CompletedTasksOverviewCard(completedCount: 1, pendingCount: 2),
                  DailyCompletedCard(taskCount: 1),
                  FocusTrackerCard(),
                  TasksNext7DaysCard(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('All cards passed at width: $width');
    }
  });

  testWidgets('Scaffold with mobile bottomNavigationBar height test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            key: const ValueKey('body_container'),
            color: Colors.red,
            child: const Center(child: Text('HELLO BODY')),
          ),
          floatingActionButton: FloatingActionButton(
            key: const ValueKey('fab_btn'),
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 1.0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: Colors.blue,
                child: const Text('NAV BAR'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bodyFinder = find.byKey(const ValueKey('body_container'));
    final bodySize = tester.getSize(bodyFinder);
    final fabFinder = find.byKey(const ValueKey('fab_btn'));
    final fabTopLeft = tester.getTopLeft(fabFinder);
    debugPrint('Body size: $bodySize, FAB position: $fabTopLeft');
  });

  testWidgets('TasksScreen mobile header test at narrow widths (150, 200, 250, 300, 400)', (WidgetTester tester) async {
    for (final width in [400.0, 300.0, 250.0, 200.0, 150.0]) {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, headerConstraints) {
                final availableWidth = headerConstraints.maxWidth;
                final isSuperNarrow = availableWidth < 280;
                final isNarrow = availableWidth < 380;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    isSuperNarrow ? 12 : 20,
                    10,
                    isSuperNarrow ? 8 : 16,
                    4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'My Tasks',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isSuperNarrow ? 18 : (isNarrow ? 21 : 24),
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '2 pending • 1 completed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.all(isSuperNarrow ? 4 : 6),
                        constraints: BoxConstraints(
                          minWidth: isSuperNarrow ? 30 : 36,
                          minHeight: isSuperNarrow ? 30 : 36,
                        ),
                        onPressed: () {},
                        icon: Icon(Icons.search_rounded, color: const Color(0xFF475569), size: isSuperNarrow ? 19 : 22),
                      ),
                      if (!isSuperNarrow)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          onPressed: () {},
                          icon: const Icon(Icons.tune_rounded, color: Color(0xFF475569), size: 20),
                        ),
                      if (!isNarrow)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          onPressed: () {},
                          icon: const Icon(Icons.sort_rounded, color: Color(0xFF475569), size: 20),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('Mobile header passed without overflow at width: $width');
    }
  });

  testWidgets('Task item overflow reproduction test at narrow widths', (WidgetTester tester) async {
    for (final width in [250.0, 220.0, 200.0, 180.0, 150.0, 130.0]) {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isSuperNarrow = screenWidth < 280;
                final isNarrow = screenWidth < 400;

                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: isSuperNarrow ? 6 : (isNarrow ? 10 : 16)),
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSuperNarrow ? 6 : (isNarrow ? 8 : 12),
                            vertical: 4,
                          ),
                          horizontalTitleGap: isSuperNarrow ? 4 : (isNarrow ? 8 : 12),
                          minLeadingWidth: isSuperNarrow ? 24 : (isNarrow ? 28 : 36),
                          leading: SizedBox(
                            width: isSuperNarrow ? 24 : 32,
                            height: isSuperNarrow ? 24 : 32,
                            child: Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: false,
                              onChanged: (_) {},
                            ),
                          ),
                          title: const Text('ek kam kar raha he ki hi oo bata'),
                          subtitle: Wrap(
                            spacing: isSuperNarrow ? 4 : 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: isSuperNarrow ? 4 : 6, top: 4),
                                padding: EdgeInsets.symmetric(horizontal: isSuperNarrow ? 5 : 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Work',
                                  style: TextStyle(fontSize: isSuperNarrow ? 9 : 11, color: const Color(0xFF475569)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text.rich(
                                  TextSpan(
                                    children: const [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                      ),
                                      WidgetSpan(child: SizedBox(width: 3)),
                                      TextSpan(
                                        text: '29/09/2026',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 4, left: isSuperNarrow ? 2 : 4),
                                child: Text.rich(
                                  TextSpan(
                                    children: const [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Icon(Icons.person, size: 12, color: Color(0xFF3B82F6)),
                                      ),
                                      WidgetSpan(child: SizedBox(width: 3)),
                                      TextSpan(
                                        text: 'Assigned by: Super Administrator',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 2),
                                child: Text.rich(
                                  TextSpan(
                                    children: const [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, value: 0.5)),
                                      ),
                                      WidgetSpan(child: SizedBox(width: 3)),
                                      TextSpan(
                                        text: '50%',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: isSuperNarrow ? 26 : 32,
                              minHeight: isSuperNarrow ? 26 : 32,
                            ),
                            icon: const Icon(Icons.star_border_rounded, size: 22),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('Task item test passed at width: $width');
    }
  });

  test('Task voice note serialization and deserialization test', () {
    final task = Task(
      id: 'task_voice_1',
      title: 'Voice Instruction Meeting',
      voiceNoteUrl: '/data/user/0/com.example.todo/cache/voice_123.m4a',
      voiceDurationSeconds: 15,
    );

    final json = task.toJson();
    expect(json['voiceNoteUrl'], equals('/data/user/0/com.example.todo/cache/voice_123.m4a'));
    expect(json['voiceDurationSeconds'], equals(15));

    final reconstructed = Task.fromJson(json);
    expect(reconstructed.id, equals('task_voice_1'));
    expect(reconstructed.voiceNoteUrl, equals('/data/user/0/com.example.todo/cache/voice_123.m4a'));
    expect(reconstructed.voiceDurationSeconds, equals(15));
  });

  testWidgets('VoiceNotePlayerWidget renders cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: VoiceNotePlayerWidget(
              audioPathOrUrl: 'mock_voice.m4a',
              durationSeconds: 25,
              isCompact: true,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Voice Note'), findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
  });
}

