import 'breathing_technique.dart';

class SettingsModel {
  int targetBreathCount;
  int targetHoldDuration;
  bool enableAutoHold;
  bool enableSounds;
  double breathThreshold;
  BreathingTechnique breathingTechnique;

  SettingsModel({
    this.targetBreathCount = 40,
    this.targetHoldDuration = 90,
    this.enableAutoHold = true,
    this.enableSounds = true,
    this.breathThreshold = 0.15,
    this.breathingTechnique = BreathingTechnique.tummo,
  });
}