import 'package:flutter/material.dart';
import '../services/detection_service.dart';

class DetectionOverlay extends StatelessWidget {
  final List<DetectionResult> detections;

  const DetectionOverlay({super.key, required this.detections});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BoundingBoxPainter(detections),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<DetectionResult> detections;

  _BoundingBoxPainter(this.detections);

  static const _warningLabels = {
    'car', 'truck', 'bus', 'motorcycle', 'person',
    'stairs', 'staircase', 'dog'
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (final det in detections) {
      final isWarning = _warningLabels.contains(det.label);
      final color = isWarning ? const Color(0xFFFF5722) : const Color(0xFF00E5FF);

      final x1 = det.bbox['x1']! * size.width;
      final y1 = det.bbox['y1']! * size.height;
      final x2 = det.bbox['x2']! * size.width;
      final y2 = det.bbox['y2']! * size.height;

      final boxPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      final fillPaint = Paint()
        ..color = color.withOpacity(0.08)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTRB(x1, y1, x2, y2);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, boxPaint);

      // Corner decorations
      _drawCorner(canvas, x1, y1, 12, color, true, true);
      _drawCorner(canvas, x2, y1, 12, color, false, true);
      _drawCorner(canvas, x1, y2, 12, color, true, false);
      _drawCorner(canvas, x2, y2, 12, color, false, false);

      // Label
      final label = '${det.label} ${(det.confidence * 100).toInt()}%';
      final tp = TextPainter(
        text: TextSpan(
          text: ' $label ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: color.withOpacity(0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelY = y1 - tp.height - 2;
      tp.paint(canvas, Offset(x1, labelY < 0 ? y1 + 2 : labelY));
    }
  }

  void _drawCorner(Canvas canvas, double x, double y, double size,
      Color color, bool isLeft, bool isTop) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path();
    final dx = isLeft ? size : -size;
    final dy = isTop ? size : -size;
    path.moveTo(x + dx, y);
    path.lineTo(x, y);
    path.lineTo(x, y + dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter old) =>
      old.detections != detections;
}
