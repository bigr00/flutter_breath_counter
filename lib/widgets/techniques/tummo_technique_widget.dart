import 'package:flutter/material.dart';
import '../../../services/breath_detector.dart';
import '../../../widgets/breath_visualization.dart';
import '../../../widgets/breath_counter_display.dart';
import '../../../widgets/breath_controls.dart';
import '../../../widgets/status_display.dart';
import '../../../widgets/breath_hold_timer.dart';
import '../../../models/breath_history_item.dart';

// Tummo-specific settings
class TummoSettings {
  int targetBreathCount;
  int targetHoldDuration;
  bool enableAutoHold;
  bool enableSounds;
  double breathThreshold;

  TummoSettings({
    this.targetBreathCount = 40,
    this.targetHoldDuration = 90,
    this.enableAutoHold = true,
    this.enableSounds = true,
    this.breathThreshold = 0.15,
  });
}

class TummoBreathWidget extends StatelessWidget {
  final TummoSettings settings;
  final double currentAmplitude;
  final Color feedbackColor;
  final bool isCalibrating;
  final bool isReadyForCounting;
  final bool isCounting;
  final bool isHoldingBreath;
  final int breathCount;
  final int breathHoldDuration;
  final String currentInstruction;

  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;
  final VoidCallback onToggleBreathHold;

  const TummoBreathWidget({
    Key? key,
    required this.settings,
    required this.currentAmplitude,
    required this.feedbackColor,
    required this.isCalibrating,
    required this.isReadyForCounting,
    required this.isCounting,
    required this.isHoldingBreath,
    required this.breathCount,
    required this.breathHoldDuration,
    required this.currentInstruction,
    required this.onStart,
    required this.onStop,
    required this.onReset,
    required this.onToggleBreathHold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 20),
        // Technique instruction card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCounting ? feedbackColor : Colors.grey.withOpacity(0.5),
              width: isCounting ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: const [
                Text(
                  'Tummo Breathing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Deep breaths with forceful exhales',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Visualization
        BreathVisualization(
          currentAmplitude: currentAmplitude,
          feedbackColor: feedbackColor,
        ),
        if (currentInstruction.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              currentInstruction,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: feedbackColor,
              ),
            ),
          ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breath counter
              const Spacer(),
              BreathCounterDisplay(
                breathCount: breathCount,
                targetCount: settings.enableAutoHold ? settings.targetBreathCount : null,
              ),
              const SizedBox(width: 40), // Reduced spacing between counters
              // Breath hold timer
              BreathHoldTimer(
                isActive: isHoldingBreath,
                durationInSeconds: breathHoldDuration,
                targetDuration: settings.enableAutoHold ? settings.targetHoldDuration : null,
              ),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        StatusDisplay(
          isCalibrating: isCalibrating,
          feedbackColor: feedbackColor,
        ),
        const SizedBox(height: 20),
        BreathControls(
          isReadyForCounting: isReadyForCounting,
          isCounting: isCounting,
          isHoldingBreath: isHoldingBreath,
          onStart: onStart,
          onStop: onStop,
          onReset: onReset,
          onToggleBreathHold: onToggleBreathHold,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}