import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  final List<String> _queue = [];

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.52);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });
  }

  void speak(String text, {bool priority = false}) {
    if (priority) {
      _queue.clear();
      _tts.stop();
      _isSpeaking = false;
    }
    if (!_queue.contains(text)) {
      if (priority) {
        _queue.insert(0, text);
      } else {
        _queue.add(text);
      }
    }
    if (!_isSpeaking) _processQueue();
  }

  void _processQueue() {
    if (_queue.isEmpty) return;
    _isSpeaking = true;
    final text = _queue.removeAt(0);
    _tts.speak(text);
  }

  void stop() {
    _queue.clear();
    _tts.stop();
    _isSpeaking = false;
  }
}
