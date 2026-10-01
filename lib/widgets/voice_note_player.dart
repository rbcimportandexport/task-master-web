import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';

class VoiceNotePlayerWidget extends StatefulWidget {
  final String audioPathOrUrl;
  final int? durationSeconds;
  final bool isCompact;

  const VoiceNotePlayerWidget({
    super.key,
    required this.audioPathOrUrl,
    this.durationSeconds,
    this.isCompact = false,
  });

  @override
  State<VoiceNotePlayerWidget> createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends State<VoiceNotePlayerWidget> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    VoiceService.init();

    VoiceService.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final isCurrent = VoiceService.currentPlayingPath == widget.audioPathOrUrl;
      setState(() {
        _isPlaying = isCurrent && state == PlayerState.playing;
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          _currentPosition = Duration.zero;
        }
      });
    });

    VoiceService.onPositionChanged.listen((pos) {
      if (!mounted) return;
      if (VoiceService.currentPlayingPath == widget.audioPathOrUrl) {
        setState(() {
          _currentPosition = pos;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalSec = widget.durationSeconds ?? 0;
    final displayTime = _isPlaying
        ? _formatDuration(_currentPosition.inSeconds)
        : (totalSec > 0 ? _formatDuration(totalSec) : '0:05');

    return InkWell(
      onTap: () => VoiceService.togglePlay(widget.audioPathOrUrl),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 8 : 12,
          vertical: widget.isCompact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: _isPlaying ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPlaying ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.isCompact ? 22 : 26,
              height: widget.isCompact ? 22 : 26,
              decoration: BoxDecoration(
                color: _isPlaying ? AppTheme.primaryBlue : const Color(0xFF64748B),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: widget.isCompact ? 14 : 17,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.graphic_eq_rounded,
              size: widget.isCompact ? 14 : 17,
              color: _isPlaying ? AppTheme.primaryBlue : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              'Voice Note ($displayTime)',
              style: TextStyle(
                fontSize: widget.isCompact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: _isPlaying ? AppTheme.primaryBlue : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
