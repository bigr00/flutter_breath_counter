import 'package:flutter/material.dart';
import '../../../services/breath_detector.dart';

// Box Breathing specific settings
class BoxBreathingSettings {
  int inhaleDuration;
  int holdAfterInhaleDuration;
  int exhaleDuration;
  int holdAfterExhaleDuration;
  int cycleCount;
  bool enableSounds;

  BoxBreathingSettings({
    this.inhaleDuration = 4,
    this.holdAfterInhaleDuration = 4,
    this.exhaleDuration = 4,
    this.holdAfterExhaleDuration = 4,
    this.cycleCount = 5,
    this.enableSounds = true,
  });
}

class BoxBreathingWidget extends StatelessWidget {
  final BoxBreathingSettings settings;
  final bool isActive;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const BoxBreathingWidget({
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
              color: isActive ? Colors.blue : Colors.grey.withOpacity(0.5),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Box Breathing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Inhale ${settings.inhaleDuration}s → Hold ${settings.holdAfterInhaleDuration}s → Exhale ${settings.exhaleDuration}s → Hold ${settings.holdAfterExhaleDuration}s',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Box animation placeholder
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Simple controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isActive ? onStop : onStart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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