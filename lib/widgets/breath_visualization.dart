import 'package:flutter/material.dart';

class BreathVisualization extends StatelessWidget {
  final double currentAmplitude;
  final Color feedbackColor;

  const BreathVisualization({
    Key? key,
    required this.currentAmplitude,
    required this.feedbackColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: feedbackColor.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: feedbackColor,
          width: 3,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 100 * currentAmplitude,
          height: 100 * currentAmplitude,
          decoration: BoxDecoration(
            color: feedbackColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}