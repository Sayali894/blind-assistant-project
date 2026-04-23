import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../services/tts_service.dart';
import '../services/detection_service.dart';
import '../services/text_recognition_service.dart';
import '../services/road_analyzer_service.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/status_panel.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  final TtsService _tts = TtsService();
  final DetectionService _detector = DetectionService();
  final TextRecognitionService _textRecognizer = TextRecognitionService();
  final RoadAnalyzerService _roadAnalyzer = RoadAnalyzerService();

  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _modelLoaded = false;
  String _statusMessage = 'Starting camera...';
  List<DetectionResult> _detections = [];

  // Throttle announcements
  final Map<String, DateTime> _lastAnnounced = {};
  static const _announceInterval = Duration(seconds: 3);

  // Text recognition throttle
  DateTime _lastTextCheck = DateTime.now();
  static const _textCheckInterval = Duration(seconds: 5);

  // Frame counter for processing every N frames
  int _frameCount = 0;
  static const _processEveryNFrames = 5;

  Timer? _roadCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    await _tts.init();
    _tts.speak('Camera starting. Loading detection model.', priority: true);

    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      setState(() => _statusMessage = 'No camera found');
      return;
    }

    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.medium, // balanced: speed vs accuracy
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
    } catch (e) {
      setState(() => _statusMessage = 'Camera error: $e');
      return;
    }

    // Load YOLO model
    _modelLoaded = await _detector.initialize();
    if (!_modelLoaded) {
      _tts.speak(
          'Detection model not found. Using basic mode. Please add yolov8n.tflite to assets.',
          priority: true);
      setState(() => _statusMessage = 'Model not loaded – add yolov8n.tflite');
    } else {
      _tts.speak('System ready. Detecting objects.', priority: true);
      setState(() => _statusMessage = 'Detecting...');
    }

    if (!mounted) return;
    setState(() => _isInitialized = true);

    // Start image stream
    await _controller!.startImageStream(_onFrame);

    // Road check every 8 seconds
    _roadCheckTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _announceRoadStatus();
    });
  }

  void _onFrame(CameraImage image) async {
    _frameCount++;
    if (_frameCount % _processEveryNFrames != 0) return;
    if (_isDetecting || !_modelLoaded) return;
    _isDetecting = true;

    try {
      final results = await _detector.detect(
          image, image.width, image.height);

      if (!mounted) return;
      setState(() => _detections = results);

      _announceDetections(results);

      // Text recognition every 5 seconds
      final now = DateTime.now();
      if (now.difference(_lastTextCheck) > _textCheckInterval) {
        _lastTextCheck = now;
        _runTextRecognition();
      }
    } finally {
      _isDetecting = false;
    }
  }

  void _announceDetections(List<DetectionResult> results) {
    final now = DateTime.now();
    for (final det in results) {
      if (det.confidence < 0.55) continue;
      final key = det.label;
      final lastTime = _lastAnnounced[key];
      if (lastTime == null ||
          now.difference(lastTime) > _announceInterval) {
        _lastAnnounced[key] = now;
        _tts.speak(det.announcement);

        // Vibrate for very close objects or warnings
        if (det.distance.contains('0.5') || det.distance.contains('1 meter')) {
          Vibration.vibrate(duration: 200, amplitude: 200);
        }
      }
    }
  }

  void _announceRoadStatus() {
    if (_detections.isEmpty) return;
    final detMap = _detections
        .map((d) => {
              'label': d.label,
              'x1': d.bbox['x1']!,
              'x2': d.bbox['x2']!,
            })
        .toList();
    final status = _roadAnalyzer.analyzeRoad(detMap);
    _tts.speak(status);
  }

  Future<void> _runTextRecognition() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/text_frame.jpg';
      final xFile = await _controller!.takePicture();
      await File(xFile.path).copy(path);
      final text = await _textRecognizer.recognizeFromPath(path);
      if (text != null && text.isNotEmpty) {
        _tts.speak('Text detected: $text');
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _roadCheckTimer?.cancel();
    _controller?.dispose();
    _tts.stop();
    _detector.dispose();
    _textRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview — full screen
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00E5FF),
                ),
              ),
            ),

          // Detection bounding boxes overlay
          if (_isInitialized)
            Positioned.fill(
              child: DetectionOverlay(detections: _detections),
            ),

          // Top status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: StatusPanel(
                statusMessage: _statusMessage,
                detectionCount: _detections.length,
                modelLoaded: _modelLoaded,
              ),
            ),
          ),

          // Bottom detection list
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildDetectionList(),
          ),

          // Tap anywhere for re-announce
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: () {
                if (_detections.isEmpty) {
                  _tts.speak('No objects detected currently.', priority: true);
                } else {
                  final labels = _detections
                      .map((d) => d.label)
                      .toSet()
                      .join(', ');
                  _tts.speak('Detected: $labels', priority: true);
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionList() {
    if (_detections.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETECTED',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _detections
                .take(6)
                .map((d) => _buildDetectionChip(d))
                .toList(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Double-tap to hear all detections',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionChip(DetectionResult det) {
    final isWarning = det.label.contains('car') ||
        det.label.contains('truck') ||
        det.label.contains('stairs') ||
        det.label.contains('person');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isWarning
            ? const Color(0xFFFF5722).withOpacity(0.25)
            : const Color(0xFF00E5FF).withOpacity(0.15),
        border: Border.all(
          color: isWarning
              ? const Color(0xFFFF5722).withOpacity(0.7)
              : const Color(0xFF00E5FF).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        '${det.label}  ${(det.confidence * 100).toInt()}%',
        style: TextStyle(
          color: isWarning ? const Color(0xFFFF8A65) : const Color(0xFF00E5FF),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
