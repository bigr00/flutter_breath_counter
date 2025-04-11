import 'package:flutter/material.dart';

class BreathHoldTimer extends StatelessWidget {
  final bool isActive;
  final int durationInSeconds;
  final int? targetDuration;

  const BreathHoldTimer({
    Key? key,
    required this.isActive,
    required this.durationInSeconds,
    this.targetDuration,
  }) : super(key: key);

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Calculate hold progress safely
    double? progress;
    if (targetDuration != null && targetDuration! > 0 && isActive) {
      progress = durationInSeconds / targetDuration!;
    }

    final bool hasReachedTarget = targetDuration != null && durationInSeconds >= targetDuration!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isActive ? 'Breath Hold:' : 'Last Hold:',
              style: const TextStyle(
                fontSize: 24,
              ),
            ),
            if (targetDuration != null) // Show target regardless of active state
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  '/ ${_formatDuration(targetDuration!)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        Text(
          _formatDuration(durationInSeconds),
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: isActive
                ? (hasReachedTarget ? Colors.orange : Colors.amber)
                : (durationInSeconds > 0 ? Colors.grey[600] : Colors.grey[300]),
          ),
        ),
        if (progress != null)
          SizedBox(
            width: 200, // Fixed width to avoid layout issues
            child: LinearProgressIndicator(
              value: progress,
              color: hasReachedTarget ? Colors.orange : Colors.amber,
              backgroundColor: Colors.amber.withOpacity(0.2),
              minHeight: 8,
            ),
          ),
        // Show a completed progress bar when not active but has a valid duration and target
        if (progress == null && !isActive && durationInSeconds > 0 && targetDuration != null)
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: durationInSeconds >= targetDuration! ? 1.0 : durationInSeconds / targetDuration!,
              color: durationInSeconds >= targetDuration! ? Colors.orange : Colors.grey[600],
              backgroundColor: Colors.grey[300],
              minHeight: 8,
            ),
          ),
      ],
    );
  }
}