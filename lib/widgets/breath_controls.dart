import 'package:flutter/material.dart';

class BreathControls extends StatelessWidget {
  final bool isReadyForCounting;
  final bool isCounting;
  final bool isHoldingBreath;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final VoidCallback onToggleBreathHold;

  const BreathControls({
    Key? key,
    required this.isReadyForCounting,
    required this.isCounting,
    required this.isHoldingBreath,
    required this.onStart,
    required this.onStop,
    required this.onReset,
    required this.onToggleBreathHold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: isReadyForCounting ? (isCounting ? onStop : onStart) : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          child: Text(isCounting ? 'Stop' : 'Start'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onReset,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          child: const Text('Reset'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: isCounting ? onToggleBreathHold : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            backgroundColor: isHoldingBreath ? Colors.amber : null,
          ),
          child: Text(isHoldingBreath ? 'End Hold' : 'Hold'),
        ),
      ],
    );
  }
}