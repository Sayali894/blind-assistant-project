import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:camera/camera.dart';

class DetectionResult {
  final String label;
  final double confidence;
  final Map<String, double> bbox; // x1, y1, x2, y2 normalized 0-1
  final String direction;
  final String distance;
  final String announcement;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.bbox,
    required this.direction,
    required this.distance,
    required this.announcement,
  });
}

class DetectionService {
  static final DetectionService _instance = DetectionService._internal();
  factory DetectionService() => _instance;
  DetectionService._internal();

  final FlutterVision _vision = FlutterVision();
  bool _isInitialized = false;
  bool _isProcessing = false;

  // Special categories
  static const _doorLabels = ['door'];
  static const _stairLabels = ['stairs', 'staircase', 'escalator'];
  static const _roadLabels = ['road', 'street', 'crosswalk', 'sidewalk', 'path'];
  static const _personLabels = ['person', 'man', 'woman', 'child'];
  static const _vehicleLabels = ['car', 'truck', 'bus', 'motorcycle', 'bicycle'];

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      await _vision.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/yolov8n.tflite',
        modelVersion: 'yolov8',
        quantization: false,
        numThreads: 2,
        useGpu: false,
      );
      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<DetectionResult>> detect(CameraImage image, int imageWidth, int imageHeight) async {
    if (!_isInitialized || _isProcessing) return [];
    _isProcessing = true;
    try {
      final results = await _vision.yoloOnFrame(
        bytesList: image.planes.map((p) => p.bytes).toList(),
        imageHeight: imageHeight,
        imageWidth: imageWidth,
        iouThreshold: 0.45,
        confThreshold: 0.50,
        classThreshold: 0.50,
      );

      final detections = <DetectionResult>[];
      for (final r in results) {
        final label = (r['tag'] as String).toLowerCase();
        final conf = (r['box'][4] as double);
        final x1 = (r['box'][0] as double);
        final y1 = (r['box'][1] as double);
        final x2 = (r['box'][2] as double);
        final y2 = (r['box'][3] as double);

        final bbox = {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2};
        final direction = _getDirection(x1, x2);
        final dist = _estimateDistance(y1, y2, label);
        final announcement = _buildAnnouncement(label, direction, dist, x1, y1, x2, y2);

        detections.add(DetectionResult(
          label: label,
          confidence: conf,
          bbox: bbox,
          direction: direction,
          distance: dist,
          announcement: announcement,
        ));
      }
      return detections;
    } catch (e) {
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  String _getDirection(double x1, double x2) {
    final centerX = (x1 + x2) / 2;
    if (centerX < 0.33) return 'to your left';
    if (centerX > 0.67) return 'to your right';
    return 'ahead';
  }

  String _estimateDistance(double y1, double y2, String label) {
    final height = y2 - y1;
    // Larger bounding box = closer object
    if (height > 0.7) return 'very close, about 0.5 meters';
    if (height > 0.5) return 'about 1 meter away';
    if (height > 0.35) return 'about 2 meters away';
    if (height > 0.20) return 'about 3 to 4 meters away';
    if (height > 0.10) return 'about 5 meters away';
    return 'far away';
  }

  String _buildAnnouncement(String label, String direction, String distance,
      double x1, double y1, double x2, double y2) {
    final height = y2 - y1;
    final width = x2 - x1;

    // Door detection
    if (_doorLabels.contains(label)) {
      // Heuristic: tall & narrow = likely door
      final aspectRatio = height / (width + 0.001);
      if (aspectRatio > 1.5) {
        final isOpen = width < 0.15; // narrow = open door (edge visible)
        return 'Door detected $direction. Door appears to be ${isOpen ? "open" : "closed"}. $distance';
      }
    }

    // Stairs detection
    if (_stairLabels.contains(label)) {
      final goingUp = y1 < 0.4; // stairs in upper frame = going up
      return 'Warning! Stairs detected $direction. ${goingUp ? "Going upward" : "Going downward"}. $distance. Please be careful.';
    }

    // Road / path
    if (_roadLabels.contains(label)) {
      return 'Road or path detected $direction. $distance';
    }

    // Person
    if (_personLabels.contains(label)) {
      return 'Person $direction, $distance';
    }

    // Vehicles
    if (_vehicleLabels.contains(label)) {
      return 'Warning! $label $direction, $distance. Be careful.';
    }

    // Default
    return '$label $direction, $distance';
  }

  void dispose() {
    _vision.closeYoloModel();
  }
}
