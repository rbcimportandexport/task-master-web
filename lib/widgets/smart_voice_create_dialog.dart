import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_illustrations.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../services/speech_service.dart';

class SmartVoiceCreateDialog extends StatefulWidget {
  const SmartVoiceCreateDialog({super.key});

  @override
  State<SmartVoiceCreateDialog> createState() => _SmartVoiceCreateDialogState();
}

class _SmartVoiceCreateDialogState extends State<SmartVoiceCreateDialog> {
  // 0 = Intro Screen (Screenshot), 1 = Listening / Input Screen, 2 = AI Parsed Tasks Preview
  int _currentStep = 0;
  final TextEditingController _voiceInputController = TextEditingController();
  bool _isListening = false;
  List<Map<String, dynamic>> _parsedTasks = [];

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('voice_intro_seen') ?? false;
    
    if (hasSeenIntro && mounted) {
      setState(() {
        _currentStep = 1;
      });
      _startListening();
    }
  }

  @override
  void dispose() {
    WebSpeechService.stopListening();
    _voiceInputController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_intro_seen', true);

    if (!mounted) return;
    setState(() {
      _currentStep = 1;
      _isListening = true;
      _voiceInputController.text = '';
    });
    _startListening();
  }

  void _startListening() {
    setState(() => _isListening = true);
    WebSpeechService.startListening(
      onResult: (text) {
        if (mounted) {
          setState(() {
            _voiceInputController.text = text;
          });
        }
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'error:not-allowed' || status == 'error: not-allowed') {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required. Please allow mic in browser settings.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        } else if (status == 'ended') {
          setState(() => _isListening = false);
        }
      },
    );
  }

  void _stopListening() {
    WebSpeechService.stopListening();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _parseTasksWithAI() {
    _stopListening();
    final text = _voiceInputController.text.trim();
    if (text.isEmpty) return;

    // Smart Task Parser splitting by comma, 'and', 'aur', or new lines
    final rawItems = text
        .split(RegExp(r',|\band\b|\baur\b|\n', caseSensitive: false))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final List<Map<String, dynamic>> tasks = [];

    for (var item in rawItems) {
      String category = 'Personal';
      int priority = 0;
      DateTime? dueDate = DateUtils.dateOnly(DateTime.now());

      final lower = item.toLowerCase();
      if (lower.contains('gym') || lower.contains('exercise') || lower.contains('walk') || lower.contains('health')) {
        category = 'Health';
        priority = 1;
      } else if (lower.contains('presentation') || lower.contains('meeting') || lower.contains('work') || lower.contains('project') || lower.contains('office')) {
        category = 'Work';
        priority = 2;
      } else if (lower.contains('buy') || lower.contains('shopping') || lower.contains('milk') || lower.contains('fruits') || lower.contains('market')) {
        category = 'Wishlist';
        priority = 1;
      } else if (lower.contains('bill') || lower.contains('pay') || lower.contains('rent')) {
        category = 'Personal';
        priority = 3;
      }

      tasks.add({
        'title': item.substring(0, 1).toUpperCase() + (item.length > 1 ? item.substring(1) : ''),
        'category': category,
        'priority': priority,
        'dueDate': dueDate,
        'selected': true,
      });
    }

    setState(() {
      _parsedTasks = tasks;
      _currentStep = 2;
      _isListening = false;
    });
  }

  void _addAllTasksToProvider() {
    final provider = context.read<TaskProvider>();
    int addedCount = 0;

    for (var item in _parsedTasks) {
      if (item['selected'] == true) {
        provider.addTask(
          title: item['title'] as String,
          category: item['category'] as String,
          priority: item['priority'] as int,
          dueDate: item['dueDate'] as DateTime?,
        );
        addedCount++;
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $addedCount tasks successfully with Smart AI!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: _currentStep == 0
            ? _buildIntroView()
            : (_currentStep == 1 ? _buildListeningView() : _buildParsedResultsView()),
      ),
    );
  }

  // --- 1. Intro View matching exact user Screenshot ---
  Widget _buildIntroView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      // Top Close Button on Left
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF334155), size: 26),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Title & Subtitle
                      const Text(
                        'Smart Voice Create',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Turn your voice into a clear to-do list with AI.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Person Speaking with Voice Waves Illustration
                      Transform.scale(
                        scale: 1.3,
                        child: const VoiceCreateIllustration(size: 450),
                      ),

                      const SizedBox(height: 20),

                      // 3 Steps Cards Flow
                      _buildStepCard(
                        icon: Icons.mic_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFFEFF6FF),
                        text: "Say what's on your mind.",
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Icon(Icons.arrow_downward_rounded, color: Color(0xFFBFDBFE), size: 18),
                      ),

                      _buildStepCard(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFECFDF5),
                        text: 'AI organizes your tasks.',
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Icon(Icons.arrow_downward_rounded, color: Color(0xFFBFDBFE), size: 18),
                      ),

                      _buildStepCard(
                        icon: Icons.checklist_rtl_rounded,
                        iconColor: const Color(0xFFA855F7),
                        bgColor: const Color(0xFFFAF5FF),
                        text: 'Add them all at once.',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Gradient Action Button: "Try Now"
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0091FF), Color(0xFFFA709A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0091FF).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                      ),
                      onPressed: _startVoiceMode,
                      child: const Text(
                        'Try Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 2. Live Voice Recording & Interactive Speech / Text Input View ---
  Widget _buildListeningView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                  onPressed: () => setState(() => _currentStep = 0),
                ),
                const Text(
                  'AI Voice Recognition',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Clean, Stable Mic Button (Zero shaking / No jitter)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleListening,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isListening
                        ? const [Color(0xFF2563EB), Color(0xFF7C3AED)]
                        : const [Color(0xFF475569), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? const Color(0xFF3B82F6) : Colors.black).withValues(alpha: _isListening ? 0.35 : 0.12),
                      blurRadius: _isListening ? 16 : 8,
                      spreadRadius: _isListening ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Explicit clickable button to toggle listening
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: _isListening ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                side: BorderSide(color: _isListening ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: _toggleListening,
              icon: Icon(
                _isListening ? Icons.stop_circle_outlined : Icons.mic_rounded,
                size: 18,
                color: _isListening ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
              label: Text(
                _isListening ? 'Listening... Tap to Stop' : 'Tap to Speak',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isListening ? const Color(0xFF2563EB) : const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isListening ? '🎤 Listening... Speak into your microphone' : 'Tap mic or click sample tasks below',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _isListening ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 12),

            // Editable Speech Input Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF3B82F6), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Spoken Words / Voice Input',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _voiceInputController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), height: 1.4),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Speak or type what you need to do...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Preset Voice Samples chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildVoiceSampleChip('Gym 6pm, Buy groceries, Call boss'),
                _buildVoiceSampleChip('Study math, Read chapter 4, Sleep early'),
                _buildVoiceSampleChip('Pay electricity bill, Meeting at 10am'),
              ],
            ),

            const SizedBox(height: 28),

            // "Process with Smart AI" Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 4,
                ),
                onPressed: _parseTasksWithAI,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_fix_high_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Organize Tasks with AI',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // --- 3. AI Parsed Tasks Review & Batch Add View ---
  Widget _buildParsedResultsView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () => setState(() => _currentStep = 1),
              ),
              const Text(
                'AI Extracted Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Found ${_parsedTasks.length} separate tasks from your voice input:',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Extracted tasks review list
          Expanded(
            child: ListView.builder(
              itemCount: _parsedTasks.length,
              itemBuilder: (context, index) {
                final task = _parsedTasks[index];
                final isSelected = task['selected'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            task['selected'] = val ?? true;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task['category'] as String,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Add All Action Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                elevation: 4,
              ),
              onPressed: _addAllTasksToProvider,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.playlist_add_check_rounded, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Add ${_parsedTasks.where((t) => t['selected'] == true).length} Tasks to List',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildVoiceSampleChip(String text) {
    return InkWell(
      onTap: () {
        setState(() {
          _voiceInputController.text = text;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Sample: "$text"',
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
        ),
      ),
    );
  }
}
