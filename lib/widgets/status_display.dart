import 'package:flutter/material.dart';

class StatusDisplay extends StatelessWidget {
  final bool isCalibrating;
  final bool isInhaling;
  final bool isExhaling;
  final Color feedbackColor;

  const StatusDisplay({
    Key? key,
    required this.isCalibrating,
    required this.isInhaling,
    required this.isExhaling,
    required this.feedbackColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String statusText = isCalibrating
        ? 'Calibrating...'
        : (isInhaling
        ? 'Inhaling'
        : (isExhaling
        ? 'Exhaling'
        : 'Ready'));

    return Text(
      statusText,
      style: TextStyle(
        fontSize: 18,
        color: feedbackColor,
      ),
    );
  }
}