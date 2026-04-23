import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _statusText = 'Initializing...';
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnim;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseAnim =
        Tween<double>(begin: 0.85, end: 1.0).animate(_pulseController);
    _ringAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_ringController);
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _setupTts();
    await Future.delayed(const Duration(milliseconds: 800));
    await _speak(
        'Welcome to Blind Assistant. Say Start to begin object detection.');
    await _startListening();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.speech,
    ].request();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
    await Future.delayed(const Duration(milliseconds: 3500));
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) _startListening();
        }
      },
      onError: (error) {
        if (mounted) _startListening();
      },
    );

    if (available && mounted) {
      setState(() {
        _isListening = true;
        _statusText = 'Listening... Say "Start"';
      });
      _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.toLowerCase();
          if (words.contains('start') ||
              words.contains('begin') ||
              words.contains('open') ||
              words.contains('go')) {
            _speech.stop();
            _navigateToCamera();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        localeId: 'en_US',
      );
    }
  }

  void _navigateToCamera() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CameraScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo area
              AnimatedBuilder(
                animation: Listenable.merge([_pulseAnim, _ringAnim]),
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Transform.scale(
                        scale: 1.0 + (_ringAnim.value * 0.5),
                        child: Opacity(
                          opacity: (1 - _ringAnim.value).clamp(0, 1),
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00E5FF),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Middle ring
                      Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withOpacity(0.5),
                              width: 3,
                            ),
                            color: const Color(0xFF00E5FF).withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Core icon
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF).withOpacity(0.15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.visibility,
                          color: Color(0xFF00E5FF),
                          size: 55,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 50),
              const Text(
                'BLIND ASSISTANT',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Smart Vision System',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 60),
              // Mic indicator
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) => Transform.scale(
                  scale: _isListening ? _pulseAnim.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? const Color(0xFFFFD600).withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      border: Border.all(
                        color: _isListening
                            ? const Color(0xFFFFD600)
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_off,
                      color:
                          _isListening ? const Color(0xFFFFD600) : Colors.grey,
                      size: 35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 40),
              // Manual start button (accessibility fallback)
              GestureDetector(
                onTap: _navigateToCamera,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                        color: const Color(0xFF00E5FF), width: 2),
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                  ),
                  child: const Text(
                    'TAP TO START',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
