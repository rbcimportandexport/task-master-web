import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'theme_screen.dart';
import 'widget_screen.dart';
import '../widgets/smart_voice_create_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _firstDayOfWeek = 'Sunday';
  String _timeFormat = '12 Hours (1:00 PM)';
  String _dateFormat = 'DD/MM/YYYY';
  String _reminderDefault = '5 minutes before';
  String _defaultHomeView = 'Tasks';
  String _selectedLanguage = 'English';
  bool _calendarSync = false;

  void _showSelectorSheet({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
            ...options.map(
              (opt) => ListTile(
                title: Text(opt, style: const TextStyle(fontSize: 15)),
                trailing: opt == currentValue ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
                onTap: () {
                  onSelected(opt);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showAccountSyncDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Account Sync'),
          ],
        ),
        content: const Text(
          'Sign in with Google to backup and sync your tasks across all your phones and tablets seamlessly.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Sign in with Google'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed in successfully! All tasks synced to cloud.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFaqDialog() {
    final faqs = [
      {'q': 'How to create a task?', 'a': 'Tap the big blue + button at the bottom or use the Mic voice create.'},
      {'q': 'How to set a reminder?', 'a': 'Tap any task to open its details, then click on Time & Reminder.'},
      {'q': 'Can I change theme colors?', 'a': 'Go to Drawer or Settings > Theme to pick any color or wallpaper.'},
      {'q': 'How to add home screen widgets?', 'a': 'Open Settings > Widget, preview any widget and tap ADD.'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            const Center(
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 16),
            ...faqs.map(
              (f) => Card(
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(f['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(f['a']!, style: const TextStyle(color: Color(0xFF64748B), height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We would love to hear your suggestions to improve the app!', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Type your feedback here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you! Your feedback has been sent.')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showFollowUsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Follow Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFE1306C), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
                title: const Text('Instagram (@todolist.app)'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Instagram...')));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle),
                  child: const Icon(Icons.facebook, color: Colors.white, size: 20),
                ),
                title: const Text('Facebook Page'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Facebook...')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Desktop Top Navigation Bar
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF1E293B)),
                            SizedBox(width: 8),
                            Text(
                              'Back to Workspace',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    height: 28,
                    width: 1,
                    color: const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(width: 24),
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: AppTheme.primaryBlue, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Workspace & App Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 16, color: AppTheme.primaryBlue),
                        SizedBox(width: 6),
                        Text(
                          'Version 1.03.30 (Desktop)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Desktop Scrollable Settings Cards
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: const Icon(
                                  Icons.settings_suggest_rounded,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Workspace Preferences & System Controls',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Customize your display format, cloud backup, notifications, audio alerts, and theme preferences.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF94A3B8),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Two Column Layout for Settings Cards
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Sync, Theme & Audio Controls
                            Expanded(
                              child: Column(
                                children: [
                                  _buildDesktopCard(
                                    title: 'Sync & Integration',
                                    icon: Icons.cloud_done_rounded,
                                    iconColor: const Color(0xFF3B82F6),
                                    items: [
                                      _buildDesktopSettingRow(
                                        icon: Icons.person_outline_rounded,
                                        title: 'Account Sync',
                                        subtitle: 'Google Cloud Auto Backup & Multi-device Sync',
                                        actionWidget: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFEFF6FF),
                                            foregroundColor: const Color(0xFF2563EB),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          icon: const Icon(Icons.sync_rounded, size: 16),
                                          label: const Text('Manage Sync', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                          onPressed: _showAccountSyncDialog,
                                        ),
                                        onTap: _showAccountSyncDialog,
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.sync_rounded,
                                        title: 'Sync Calendar',
                                        subtitle: _calendarSync ? 'Active & synchronizing system schedules' : 'Disconnected from local calendar',
                                        actionWidget: Switch(
                                          value: _calendarSync,
                                          activeTrackColor: AppTheme.primaryBlue,
                                          onChanged: (val) {
                                            setState(() => _calendarSync = val);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(_calendarSync ? 'Calendar sync enabled!' : 'Calendar sync turned off.')),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          setState(() => _calendarSync = !_calendarSync);
                                        },
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.auto_fix_high_rounded,
                                        title: 'Smart Voice Input',
                                        subtitle: 'AI Natural Language Task Generator',
                                        actionWidget: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFF1F5F9),
                                            foregroundColor: const Color(0xFF0F172A),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Test AI Voice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => const SmartVoiceCreateDialog(),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => const SmartVoiceCreateDialog(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  _buildDesktopCard(
                                    title: 'Theme & Customization',
                                    icon: Icons.palette_rounded,
                                    iconColor: const Color(0xFF8B5CF6),
                                    items: [
                                      _buildDesktopSettingRow(
                                        icon: Icons.brush_outlined,
                                        title: 'Theme & Wallpapers',
                                        subtitle: 'Color schemes, dark mode & texture presets',
                                        actionWidget: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          ),
                                          child: const Text('Open Themes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const ThemeScreen()),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const ThemeScreen()),
                                          );
                                        },
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.widgets_outlined,
                                        title: 'Widgets Gallery',
                                        subtitle: '10 interactive desktop and mobile widgets',
                                        actionWidget: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          ),
                                          child: const Text('Configure', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const WidgetScreen()),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const WidgetScreen()),
                                          );
                                        },
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.music_note_outlined,
                                        title: 'Task Completion Tone',
                                        subtitle: 'Play celebratory audio cue when completing tasks',
                                        actionWidget: Switch(
                                          value: taskProvider.taskCompletionTone,
                                          activeTrackColor: AppTheme.primaryBlue,
                                          onChanged: (val) {
                                            taskProvider.setTaskCompletionTone(val);
                                          },
                                        ),
                                        onTap: () {
                                          taskProvider.setTaskCompletionTone(!taskProvider.taskCompletionTone);
                                        },
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.wb_sunny_outlined,
                                        title: 'Perfect Day Animations',
                                        subtitle: 'Confetti & celebration when all pending tasks are finished',
                                        actionWidget: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Perfect Day celebrations are enabled!')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // Right Column: Date, Time & System Views
                            Expanded(
                              child: Column(
                                children: [
                                  _buildDesktopCard(
                                    title: 'Date & Time Formatting',
                                    icon: Icons.access_time_rounded,
                                    iconColor: const Color(0xFF10B981),
                                    items: [
                                      _buildDesktopSettingRow(
                                        icon: Icons.calendar_today_outlined,
                                        title: 'First Day of Week',
                                        subtitle: 'Active: $_firstDayOfWeek',
                                        actionWidget: _buildDesktopPillButton(
                                          text: _firstDayOfWeek,
                                          onTap: () {
                                            _showSelectorSheet(
                                              title: 'First Day of Week',
                                              options: ['Sunday', 'Monday', 'Saturday'],
                                              currentValue: _firstDayOfWeek,
                                              onSelected: (val) => setState(() => _firstDayOfWeek = val),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          _showSelectorSheet(
                                            title: 'First Day of Week',
                                            options: ['Sunday', 'Monday', 'Saturday'],
                                            currentValue: _firstDayOfWeek,
                                            onSelected: (val) => setState(() => _firstDayOfWeek = val),
                                          );
                                        },
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.schedule_rounded,
                                        title: 'Time Display Format',
                                        subtitle: 'Active: $_timeFormat',
                                        actionWidget: _buildDesktopPillButton(
                                          text: _timeFormat.contains('12') ? '12 Hours' : '24 Hours',
                                          onTap: () {
                                            _showSelectorSheet(
                                              title: 'Time Format',
                                              options: ['12 Hours (1:00 PM)', '24 Hours (13:00)'],
                                              currentValue: _timeFormat,
                                              onSelected: (val) => setState(() => _timeFormat = val),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          _showSelectorSheet(
                                            title: 'Time Format',
                                            options: ['12 Hours (1:00 PM)', '24 Hours (13:00)'],
                                            currentValue: _timeFormat,
                                            onSelected: (val) => setState(() => _timeFormat = val),
                                          );
                                        },
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.edit_calendar_outlined,
                                        title: 'Date Calendar Format',
                                        subtitle: 'Active: $_dateFormat',
                                        actionWidget: _buildDesktopPillButton(
                                          text: _dateFormat,
                                          onTap: () {
                                            _showSelectorSheet(
                                              title: 'Date Format',
                                              options: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
                                              currentValue: _dateFormat,
                                              onSelected: (val) => setState(() => _dateFormat = val),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          _showSelectorSheet(
                                            title: 'Date Format',
                                            options: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
                                            currentValue: _dateFormat,
                                            onSelected: (val) => setState(() => _dateFormat = val),
                                          );
                                        },
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.notification_add_outlined,
                                        title: 'Default Task Reminder',
                                        subtitle: 'Remind: $_reminderDefault',
                                        actionWidget: _buildDesktopPillButton(
                                          text: _reminderDefault,
                                          onTap: () {
                                            _showSelectorSheet(
                                              title: 'Default Task Reminder',
                                              options: ['On time', '5 minutes before', '15 minutes before', '30 minutes before', '1 hour before', '1 day before'],
                                              currentValue: _reminderDefault,
                                              onSelected: (val) => setState(() => _reminderDefault = val),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          _showSelectorSheet(
                                            title: 'Default Task Reminder',
                                            options: ['On time', '5 minutes before', '15 minutes before', '30 minutes before', '1 hour before', '1 day before'],
                                            currentValue: _reminderDefault,
                                            onSelected: (val) => setState(() => _reminderDefault = val),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  _buildDesktopCard(
                                    title: 'Interface & About',
                                    icon: Icons.info_outline_rounded,
                                    iconColor: const Color(0xFF64748B),
                                    items: [
                                      _buildDesktopSettingRow(
                                        icon: Icons.language_rounded,
                                        title: 'Language',
                                        subtitle: 'Interface language: $_selectedLanguage',
                                        actionWidget: _buildDesktopPillButton(
                                          text: _selectedLanguage,
                                          onTap: () {
                                            _showSelectorSheet(
                                              title: 'Select Language',
                                              options: ['English', 'Urdu', 'Hindi', 'Spanish', 'French', 'German', 'Arabic'],
                                              currentValue: _selectedLanguage,
                                              onSelected: (val) => setState(() => _selectedLanguage = val),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          _showSelectorSheet(
                                            title: 'Select Language',
                                            options: ['English', 'Urdu', 'Hindi', 'Spanish', 'French', 'German', 'Arabic'],
                                            currentValue: _selectedLanguage,
                                            onSelected: (val) => setState(() => _selectedLanguage = val),
                                          );
                                        },
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.help_outline_rounded,
                                        title: 'FAQ & Knowledge Base',
                                        subtitle: 'Tips, shortcuts, and troubleshooting guides',
                                        actionWidget: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                        onTap: _showFaqDialog,
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.feedback_outlined,
                                        title: 'Send Feedback',
                                        subtitle: 'Send bug reports or feature requests directly to team',
                                        actionWidget: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                        onTap: _showFeedbackDialog,
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.share_rounded,
                                        title: 'Follow Community',
                                        subtitle: 'Join Instagram & Facebook updates',
                                        actionWidget: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                        onTap: _showFollowUsSheet,
                                      ),
                                      _buildDesktopSettingRow(
                                        icon: Icons.verified_user_outlined,
                                        title: 'Privacy & Data Policy',
                                        subtitle: 'Local-first encrypted storage & zero-tracking',
                                        actionWidget: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Privacy Policy'),
                                              content: const Text(
                                                'Your data is stored locally on your device and encrypted. We do not sell or share personal information.',
                                                style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                                              ),
                                              actions: [
                                                ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile View (Kept intact and polished)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Section 1: Customize
          _buildSectionHeader('Customize'),
          _buildSettingItem(
            icon: Icons.person_outline_rounded,
            title: 'Account Sync',
            subtitle: 'Google Cloud Sync',
            onTap: _showAccountSyncDialog,
          ),
          _buildSettingItem(
            icon: Icons.widgets_outlined,
            title: 'Widget',
            subtitle: '10 interactive widgets',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WidgetScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notification & Reminder',
            subtitle: 'Sound & Vibration on',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications are active!')),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.brush_outlined,
            title: 'Theme',
            subtitle: 'Pure Color, Texture, Scenery',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.sync_rounded,
            title: 'Sync Calendar',
            subtitle: _calendarSync ? 'Enabled' : 'Off',
            onTap: () {
              setState(() => _calendarSync = !_calendarSync);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_calendarSync ? 'Calendar sync enabled!' : 'Calendar sync turned off.')),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.auto_fix_high_rounded,
            title: 'Smart Input',
            subtitle: 'AI Voice Create',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const SmartVoiceCreateDialog(),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.account_tree_outlined,
            title: 'Subtasks',
            subtitle: 'Show on task list',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subtasks are visible on task list.')),
              );
            },
          ),

          const SizedBox(height: 16),

          // Section 2: Task Completion
          _buildSectionHeader('Task Completion'),
          _buildSettingItem(
            icon: Icons.wb_sunny_outlined,
            title: 'Perfect Day',
            subtitle: 'Celebrate when all tasks done',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Perfect Day celebrations enabled!')),
              );
            },
          ),
          _buildSettingSwitchItem(
            icon: Icons.music_note_outlined,
            title: 'Task Completion Tone',
            value: taskProvider.taskCompletionTone,
            onChanged: (val) {
              taskProvider.setTaskCompletionTone(val);
            },
          ),

          const SizedBox(height: 16),

          // Section 3: Date & Time
          _buildSectionHeader('Date & Time'),
          _buildSettingItem(
            icon: Icons.calendar_today_outlined,
            title: 'First Day of Week',
            subtitle: _firstDayOfWeek,
            onTap: () {
              _showSelectorSheet(
                title: 'First Day of Week',
                options: ['Sunday', 'Monday', 'Saturday'],
                currentValue: _firstDayOfWeek,
                onSelected: (val) => setState(() => _firstDayOfWeek = val),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.access_time_rounded,
            title: 'Time Format',
            subtitle: _timeFormat,
            onTap: () {
              _showSelectorSheet(
                title: 'Time Format',
                options: ['12 Hours (1:00 PM)', '24 Hours (13:00)'],
                currentValue: _timeFormat,
                onSelected: (val) => setState(() => _timeFormat = val),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.edit_calendar_outlined,
            title: 'Date Format',
            subtitle: _dateFormat,
            onTap: () {
              _showSelectorSheet(
                title: 'Date Format',
                options: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
                currentValue: _dateFormat,
                onSelected: (val) => setState(() => _dateFormat = val),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.calendar_month_outlined,
            title: 'Due Date',
            subtitle: 'Today',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Default due date is set to Today.')),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.notification_add_outlined,
            title: 'Task reminder default',
            subtitle: _reminderDefault,
            onTap: () {
              _showSelectorSheet(
                title: 'Default Task Reminder',
                options: ['On time', '5 minutes before', '15 minutes before', '30 minutes before', '1 hour before', '1 day before'],
                currentValue: _reminderDefault,
                onSelected: (val) => setState(() => _reminderDefault = val),
              );
            },
          ),

          const SizedBox(height: 16),

          // Section 4: Task Appearance Customize
          _buildSectionHeader('Task Appearance Customize'),
          _buildSettingItem(
            icon: Icons.view_headline_rounded,
            title: 'Default Home View',
            subtitle: _defaultHomeView,
            onTap: () {
              _showSelectorSheet(
                title: 'Default Home View',
                options: ['Tasks', 'Calendar', 'Mine'],
                currentValue: _defaultHomeView,
                onSelected: (val) => setState(() => _defaultHomeView = val),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.grid_view_rounded,
            title: 'Default Category',
            subtitle: 'Last Viewed',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Default category set to Last Viewed.')),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.swap_vert_rounded,
            title: 'Time Range Sort',
            subtitle: 'Previous, Today, Future',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sort order: Previous, Today, Future')),
              );
            },
          ),

          const SizedBox(height: 16),

          // Section 5: About
          _buildSectionHeader('About'),
          _buildSettingItem(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: _selectedLanguage,
            onTap: () {
              _showSelectorSheet(
                title: 'Select Language',
                options: ['English', 'Urdu', 'Hindi', 'Spanish', 'French', 'German', 'Arabic'],
                currentValue: _selectedLanguage,
                onSelected: (val) => setState(() => _selectedLanguage = val),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.help_outline_rounded,
            title: 'FAQ',
            onTap: _showFaqDialog,
          ),
          _buildSettingItem(
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            onTap: _showFeedbackDialog,
          ),
          _buildSettingItem(
            icon: Icons.share_rounded,
            title: 'Follow Us',
            onTap: _showFollowUsSheet,
          ),
          _buildSettingItem(
            icon: Icons.verified_user_outlined,
            title: 'Privacy Policy',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const Text(
                    'Your data is stored locally on your device and encrypted. We do not sell or share personal information.',
                    style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                  ),
                  actions: [
                    ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
                  ],
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.layers_outlined,
            title: 'Version: 1.03.30.0817',
            subtitle: 'Latest Release',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You are on the latest version!')),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Desktop Card Wrapper
  Widget _buildDesktopCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...items,
        ],
      ),
    );
  }

  // Desktop Setting Row
  Widget _buildDesktopSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget actionWidget,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      hoverColor: const Color(0xFFF8FAFC),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF475569)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            actionWidget,
          ],
        ),
      ),
    );
  }

  // Desktop Pill Button
  Widget _buildDesktopPillButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF60A5FA), size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            )
          : null,
      trailing: trailing,
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
    );
  }

  Widget _buildSettingSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF60A5FA), size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
      ),
      trailing: Switch(
        value: value,
        activeTrackColor: AppTheme.primaryBlue,
        onChanged: onChanged,
      ),
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
