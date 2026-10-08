import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const FeedbackDialog(),
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();
  String _category = 'Suggestion';
  int _rating = 5;
  bool _isSending = false;

  final String _targetAdminEmail = 'yadavsaurabh9333@gmail.com';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your feedback message.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final userEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : 'Anonymous User';

    // 1. Save feedback to Firestore collection
    try {
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'adminTargetEmail': _targetAdminEmail,
        'userEmail': userEmail,
        'category': _category,
        'rating': _rating,
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Continue even if offline
    }

    // 2. Trigger mailto draft directly to yadavsaurabh9333@gmail.com
    final subject = Uri.encodeComponent('To-Do List App Feedback: $_category');
    final body = Uri.encodeComponent(
      'Feedback Category: $_category\n'
      'Rating: $_rating / 5\n'
      'From: $userEmail\n\n'
      'Message:\n$text\n\n'
      'Sent from To-Do List Application',
    );

    final mailtoUri = Uri.parse('mailto:$_targetAdminEmail?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isSending = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Feedback sent to $_targetAdminEmail'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.feedback_outlined, color: Color(0xFF4F46E5), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send Feedback', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                Text('Direct to: yadavsaurabh9333@gmail.com', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Feedback Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['Suggestion', 'Bug Report', 'Feature Request', 'Other'].map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFF4F46E5),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              const Text('Rate Experience:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 28,
                    ),
                    onPressed: () => setState(() => _rating = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Your Email (optional)',
                  prefixIcon: const Icon(Icons.email_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _feedbackController,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Feedback & Message *',
                  hintText: 'Describe your thoughts, problem or request...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _sendFeedback,
          icon: _isSending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, size: 16),
          label: const Text('Send to Email'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
