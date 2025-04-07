import 'package:flutter/material.dart';

class BreathCounterDisplay extends StatelessWidget {
  final int breathCount;

  const BreathCounterDisplay({
    Key? key,
    required this.breathCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Breaths Taken:',
          style: TextStyle(fontSize: 24),
        ),
        Text(
          '$breathCount',
          style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}