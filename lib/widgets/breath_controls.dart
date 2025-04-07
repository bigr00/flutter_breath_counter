import 'package:flutter/material.dart';

class BreathControls extends StatelessWidget {
  final bool isRecording;
  final bool isCounting;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const BreathControls({
    Key? key,
    required this.isRecording,
    required this.isCounting,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: isRecording ? onStart : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: const Text('Start'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: isCounting ? onStop : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: const Text('Stop'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: onReset,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: const Text('Reset'),
        ),
      ],
    );
  }
}