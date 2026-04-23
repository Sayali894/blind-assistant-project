import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = '';

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (error) {
        debugPrint('Speech error: $error');
        _isListening = false;
        notifyListeners();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
    );
    notifyListeners();
    return _isAvailable;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function() onDone,
  }) async {
    if (!_isAvailable || _isListening) return;

    _isListening = true;
    _lastWords = '';
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords.toLowerCase().trim();
        if (result.finalResult) {
          onResult(_lastWords);
        }
        notifyListeners();
      },
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );

    // Auto-stop after timeout
    Future.delayed(const Duration(seconds: 9), () {
      if (_isListening) {
        stopListening();
        onDone();
      }
    });
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  bool matchesCommand(String words, List<String> commands) {
    for (final cmd in commands) {
      if (words.contains(cmd)) return true;
    }
    return false;
  }
}
