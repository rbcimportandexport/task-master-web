// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:async';

@JS('initSpeechRecognition')
external bool _initSpeech([JSString? lang]);

@JS('stopSpeechRecognition')
external void _stopSpeech();

class WebSpeechService {
  static bool get isSupported => true;

  static StreamSubscription? _resultSub;
  static StreamSubscription? _statusSub;
  static Timer? _backupPollTimer;
  static String _lastDeliveredText = '';

  static void startListening({
    required Function(String text) onResult,
    Function(String status)? onStatus,
    String? lang,
  }) {
    stopListening();
    _lastDeliveredText = '';

    // 1. Direct native DOM CustomEvent listener (Fastest & 100% reliable)
    _resultSub = html.window.on['flutter_speech_result'].listen((html.Event event) {
      if (event is html.CustomEvent && event.detail != null) {
        final text = event.detail.toString().trim();
        if (text.isNotEmpty && text != _lastDeliveredText) {
          _lastDeliveredText = text;
          onResult(text);
        }
      }
    });

    _statusSub = html.window.on['flutter_speech_status'].listen((html.Event event) {
      if (event is html.CustomEvent && event.detail != null) {
        final status = event.detail.toString();
        onStatus?.call(status);
      }
    });

    // 2. Start browser Web Speech Recognition
    try {
      _initSpeech((lang ?? 'en-US').toJS);
    } catch (_) {}

    // 3. Fallback polling from sessionStorage & window._speechResult
    _backupPollTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      try {
        final res = html.window.sessionStorage['latest_speech_result'] ?? '';
        if (res.isNotEmpty && res != _lastDeliveredText) {
          _lastDeliveredText = res;
          onResult(res);
        }
      } catch (_) {}
    });
  }

  static void stopListening() {
    _resultSub?.cancel();
    _resultSub = null;
    _statusSub?.cancel();
    _statusSub = null;
    _backupPollTimer?.cancel();
    _backupPollTimer = null;
    _lastDeliveredText = '';

    try {
      _stopSpeech();
    } catch (_) {}
  }
}
