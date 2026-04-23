# Blind Assistant - Smart Vision System for Visually Impaired

## Features
- Voice activation on startup (say "Start")
- Real-time object detection using YOLOv8
- Audio announcements with direction and distance
- Text recognition (OCR)
- Door open/closed detection
- Stairs detection with up/down direction
- Road clear/blocked status
- Vibration alerts for close objects
- Double-tap to repeat all current detections

## How to Build APK via GitHub Actions
See the step-by-step guide provided.

## Technology Stack
- Flutter (Dart)
- YOLOv8n TFLite (auto-downloaded during build)
- Google ML Kit (text recognition)
- flutter_vision (YOLO inference)
- flutter_tts (text-to-speech)
- speech_to_text (voice commands)
