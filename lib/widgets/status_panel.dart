import 'package:flutter/material.dart';

class StatusPanel extends StatelessWidget {
  final String statusMessage;
  final int detectionCount;
  final bool modelLoaded;

  const StatusPanel({
    super.key,
    required this.statusMessage,
    required this.detectionCount,
    required this.modelLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.85),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(
        children: [
          // Model status indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: modelLoaded ? const Color(0xFF00E676) : Colors.orange,
              boxShadow: [
                BoxShadow(
                  color: (modelLoaded ? const Color(0xFF00E676) : Colors.orange)
                      .withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (detectionCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.5),
                ),
              ),
              child: Text(
                '$detectionCount obj',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
