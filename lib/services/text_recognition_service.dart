import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TextRecognitionService {
  static final TextRecognitionService _instance = TextRecognitionService._internal();
  factory TextRecognitionService() => _instance;
  TextRecognitionService._internal();

  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isProcessing = false;
  String _lastRecognizedText = '';

  Future<String?> recognizeFromPath(String imagePath) async {
    if (_isProcessing) return null;
    _isProcessing = true;
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _recognizer.processImage(inputImage);
      final text = recognized.text.trim();
      if (text.isEmpty) return null;
      if (text == _lastRecognizedText) return null;
      if (text.length < 3) return null;
      _lastRecognizedText = text;
      return text;
    } catch (e) {
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _recognizer.close();
  }
}
