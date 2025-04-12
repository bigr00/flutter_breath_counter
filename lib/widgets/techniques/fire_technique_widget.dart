import 'package:flutter/material.dart';

// Fire Breath specific settings
class FireBreathSettings {
  int targetBreathCount;
  double breathPacePerSecond;
  int roundCount;
  bool enableSounds;

  FireBreathSettings({
    this.targetBreathCount = 30,
    this.breathPacePerSecond = 1.0,
    this.roundCount = 3,
    this.enableSounds = true,
  });
}

class FireBreathWidget extends StatelessWidget {
  final FireBreathSettings settings;
  final bool isActive;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const FireBreathWidget({
    Key? key,
    required this.settings,
    required this.isActive,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // Instruction card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isActive ? Colors.orange : Colors.grey.withOpacity(0.5),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Fire Breath',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Rapid breathing at ${settings.breathPacePerSecond.toStringAsFixed(1)} breaths per second',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rapid inhale through nose, forceful exhale through mouth',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Fire animation placeholder
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.orange,
              width: 3,
            ),
          ),
          child: const Center(
            child: Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Round indicator (placeholder)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Round: ', style: TextStyle(fontSize: 18)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                '1 / 3',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // Simple controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isActive ? onStop : onStart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                backgroundColor: Colors.orange,
              ),
              child: Text(isActive ? 'Stop' : 'Start'),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: onReset,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              child: const Text('Reset'),
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}