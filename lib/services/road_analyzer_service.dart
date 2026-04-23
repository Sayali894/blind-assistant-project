/// Analyzes the overall scene to determine if the road ahead is clear
class RoadAnalyzerService {
  static final RoadAnalyzerService _instance = RoadAnalyzerService._internal();
  factory RoadAnalyzerService() => _instance;
  RoadAnalyzerService._internal();

  static const _blockingLabels = {
    'person', 'car', 'truck', 'bus', 'motorcycle', 'bicycle',
    'dog', 'cat', 'traffic cone', 'fire hydrant', 'bench',
    'chair', 'couch', 'potted plant', 'suitcase', 'backpack',
  };

  String analyzeRoad(List<Map<String, dynamic>> detections) {
    if (detections.isEmpty) return 'Road appears clear ahead.';

    final blockingObjects = detections.where((d) {
      final label = (d['label'] as String).toLowerCase();
      return _blockingLabels.contains(label);
    }).toList();

    if (blockingObjects.isEmpty) return 'Road appears clear ahead.';

    // Check if blocking objects are in the center path
    final centerBlockers = blockingObjects.where((d) {
      final x1 = d['x1'] as double;
      final x2 = d['x2'] as double;
      final cx = (x1 + x2) / 2;
      return cx > 0.25 && cx < 0.75;
    }).toList();

    if (centerBlockers.isEmpty) return 'Road clear ahead. Objects detected on sides.';

    final labels = centerBlockers
        .map((d) => d['label'] as String)
        .toSet()
        .join(', ');
    return 'Road blocked ahead by $labels. Please stop or navigate around.';
  }
}
