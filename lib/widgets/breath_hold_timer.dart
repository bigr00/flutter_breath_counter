import 'package:flutter/material.dart';

class BreathHoldTimer extends StatelessWidget {
  final bool isActive;
  final int durationInSeconds;

  const BreathHoldTimer({
    Key? key,
    required this.isActive,
    required this.durationInSeconds,
  }) : super(key: key);

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isActive ? 'Breath Hold:' : 'Last Hold:',
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
        Text(
          _formatDuration(durationInSeconds),
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: isActive
                ? Colors.amber
                : (durationInSeconds > 0 ? Colors.grey[600] : Colors.grey[300]),
          ),
        ),
      ],
    );
  }
}