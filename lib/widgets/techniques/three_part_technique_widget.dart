import 'package:flutter/material.dart';

// Three-Part Breath specific settings
class ThreePartBreathSettings {
  int bellyBreathDuration;
  int ribBreathDuration;
  int chestBreathDuration;
  int exhaleDuration;
  int cycleCount;
  bool enableSounds;
  bool enableVibration;

  ThreePartBreathSettings({
    this.bellyBreathDuration = 3,
    this.ribBreathDuration = 3,
    this.chestBreathDuration = 3,
    this.exhaleDuration = 6,
    this.cycleCount = 10,
    this.enableSounds = true,
    this.enableVibration = true,
  });
}

class ThreePartBreathWidget extends StatelessWidget {
  final ThreePartBreathSettings settings;
  final bool isActive;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const ThreePartBreathWidget({
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
              color: isActive ? Colors.green : Colors.grey.withOpacity(0.5),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Three-Part Breath',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fill belly → Expand ribs → Fill chest → Exhale completely',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total cycle: ${settings.bellyBreathDuration + settings.ribBreathDuration + settings.chestBreathDuration + settings.exhaleDuration} seconds',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Three-part animation placeholder
        Container(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer circle (chest)
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.7),
                    width: 2,
                  ),
                ),
              ),
              // Middle circle (ribs)
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.8),
                    width: 2,
                  ),
                ),
              ),
              // Inner circle (belly)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green,
                    width: 2,
                  ),
                ),
              ),
              // Text overlay
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Phase indicator (placeholder)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green),
          ),
          child: const Text(
            'Current Phase: Waiting to start',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
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
                backgroundColor: Colors.green,
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