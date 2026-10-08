import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class TeamChatScreen extends StatefulWidget {
  final String? initialChannel; // 'general', 'department', etc.
  const TeamChatScreen({super.key, this.initialChannel});

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  late String _currentChannel;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.initialChannel ?? 'General Announcement';
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(TaskProvider taskProvider) async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _msgController.clear();

    try {
      final userName = taskProvider.userName.isNotEmpty ? taskProvider.userName : 'Team Member';
      final userRole = taskProvider.userRole;
      final userId = taskProvider.uid ?? 'unknown';

      await FirebaseFirestore.instance
          .collection('team_chats')
          .doc(_currentChannel)
          .collection('messages')
          .add({
        'senderId': userId,
        'senderName': userName,
        'senderRole': userRole,
        'message': text,
        'channel': _currentChannel,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show instant feedback
      await NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: ' Team Message Sent',
        body: 'Your message was posted in $_currentChannel',
      );

      // Auto scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 950;
    final currentUserId = taskProvider.uid;

    final channels = [
      'General Announcement',
      'Operations & Logistics',
      'Daily Updates',
      'Help & Support',
    ];

    return Scaffold(
      backgroundColor: isDesktop ? const Color(0xFFF8FAFC) : AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Discussion & Chat',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textPrimary),
            ),
            Text(
              'Channel: #$_currentChannel',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tag_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Switch Channel',
            onSelected: (ch) => setState(() => _currentChannel = ch),
            itemBuilder: (ctx) => channels.map((ch) {
              return PopupMenuItem<String>(
                value: ch,
                child: Row(
                  children: [
                    Icon(
                      _currentChannel == ch ? Icons.check_circle_rounded : Icons.tag_rounded,
                      size: 18,
                      color: _currentChannel == ch ? AppTheme.primaryBlue : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ch,
                      style: TextStyle(
                        fontWeight: _currentChannel == ch ? FontWeight.bold : FontWeight.normal,
                        color: _currentChannel == ch ? AppTheme.primaryBlue : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Channels Quick Bar
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: channels.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final ch = channels[idx];
                  final isSel = ch == _currentChannel;
                  return ChoiceChip(
                    label: Text('#$ch'),
                    selected: isSel,
                    selectedColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF475569),
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12,
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onSelected: (_) => setState(() => _currentChannel = ch),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Messages Live Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('team_chats')
                    .doc(_currentChannel)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEF2FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.forum_outlined, size: 48, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No messages yet in #$_currentChannel',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Start the discussion by typing a message below!',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: docs.length,
                    itemBuilder: (ctx, idx) {
                      final data = docs[idx].data();
                      final isMe = data['senderId'] == currentUserId;
                      final senderName = data['senderName'] ?? 'Team Member';
                      final senderRole = (data['senderRole'] ?? 'employee').toString().toUpperCase();
                      final message = data['message'] ?? '';
                      final ts = data['timestamp'] as Timestamp?;
                      final timeStr = ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : 'Now';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primaryBlue : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      senderName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        senderRole,
                                        style: const TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (!isMe) const SizedBox(height: 4),
                              Text(
                                message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMe ? Colors.white : const Color(0xFF1E293B),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: isMe ? Colors.white.withOpacity(0.75) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Message Composer Input Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _msgController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Message #$_currentChannel...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(taskProvider),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : () => _sendMessage(taskProvider),
                      tooltip: 'Send Message',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
