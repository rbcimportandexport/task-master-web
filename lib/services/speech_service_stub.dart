class WebSpeechService {
  static bool get isSupported => false;
  static void startListening({
    required Function(String text) onResult,
    Function(String status)? onStatus,
    String? lang,
  }) {}
  static void stopListening() {}
}
