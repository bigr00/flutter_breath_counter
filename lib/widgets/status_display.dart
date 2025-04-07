import 'package:flutter/material.dart';

class StatusDisplay extends StatelessWidget {
  final bool isCalibrating;
  final Color feedbackColor;

  const StatusDisplay({
    Key? key,
    required this.isCalibrating,
    required this.feedbackColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show text for calibration state
    if (isCalibrating) {
      return Text(
        'Calibrating...',
        style: TextStyle(
          fontSize: 18,
          color: feedbackColor,
        ),
      );
    }

    // Return an empty container when not calibrating
    // The visualization will provide the feedback
    return const SizedBox(height: 18); // Same height as the text for consistent layout
  }
}