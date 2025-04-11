import 'package:flutter/material.dart';

class BreathCounterDisplay extends StatelessWidget {
  final int breathCount;
  final int? targetCount;

  const BreathCounterDisplay({
    Key? key,
    required this.breathCount,
    this.targetCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate progress safely, avoiding null issues
    double? progress;
    if (targetCount != null && targetCount! > 0) {
      progress = breathCount / targetCount!;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Breaths Taken:',
              style: TextStyle(fontSize: 24),
            ),
            if (targetCount != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  '/ $targetCount',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        Text(
          '$breathCount',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: targetCount != null && breathCount >= targetCount!
                ? Colors.orange
                : null,
          ),
        ),
        if (progress != null)
          SizedBox(
            width: 200, // Fixed width to avoid layout issues
            child: LinearProgressIndicator(
              value: progress,
              color: Colors.blue,
              backgroundColor: Colors.blue.withOpacity(0.2),
              minHeight: 8,
            ),
          ),
      ],
    );
  }
}