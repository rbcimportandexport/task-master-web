import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class VoiceService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final AudioPlayer _player = AudioPlayer();

  static bool _isRecording = false;
  static bool get isRecording => _isRecording;

  static String? _currentPlayingPath;
  static PlayerState _playerState = PlayerState.stopped;

  static PlayerState get playerState => _playerState;
  static String? get currentPlayingPath => _currentPlayingPath;

  static final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  static Stream<PlayerState> get onPlayerStateChanged => _playerStateController.stream;

  static final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  static Stream<Duration> get onPositionChanged => _positionController.stream;

  static void init() {
    _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _currentPlayingPath = null;
      }
      _playerStateController.add(state);
    });

    _player.onPositionChanged.listen((pos) {
      _positionController.add(pos);
    });
  }

  /// Start recording voice message
  static Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        String? filePath;
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          filePath = '${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath ?? '',
        );
        _isRecording = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording voice message and return audio file path or URL
  static Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      debugPrint('Error stopping audio recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Play or pause a voice note
  static Future<void> togglePlay(String pathOrUrl) async {
    try {
      if (_currentPlayingPath == pathOrUrl && _playerState == PlayerState.playing) {
        await _player.pause();
      } else if (_currentPlayingPath == pathOrUrl && _playerState == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.stop();
        _currentPlayingPath = pathOrUrl;
        if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
          await _player.play(UrlSource(pathOrUrl));
        } else {
          await _player.play(DeviceFileSource(pathOrUrl));
        }
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  /// Stop current playback
  static Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _currentPlayingPath = null;
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }
}
