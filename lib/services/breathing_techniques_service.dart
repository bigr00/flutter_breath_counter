import 'dart:async';
import '../models/breathing_technique.dart';

class BreathingTechniquesService {
  final Function(String) onInstructionChange;
  final Function(bool) onBreathHoldInstructionChange;

  BreathingTechniquesService({
    required this.onInstructionChange,
    required this.onBreathHoldInstructionChange,
  });

  Timer? _instructionTimer;
  BreathingTechniqueType? _currentTechnique;
  bool _isActive = false;

  void startTechnique(BreathingTechniqueType technique) {
    // Clean up any previous timers
    _instructionTimer?.cancel();
    _currentTechnique = technique;
    _isActive = true;

    switch (technique) {
      case BreathingTechniqueType.tummo:
        _startTummoBreathing();
        break;
      case BreathingTechniqueType.boxBreathing:
        _startBoxBreathing();
        break;
      case BreathingTechniqueType.fireBreath:
        _startFireBreath();
        break;
      case BreathingTechniqueType.threePartBreath:
        _startThreePartBreath();
        break;
    }
  }

  void stopTechnique() {
    _instructionTimer?.cancel();
    _instructionTimer = null;
    _isActive = false;
    _currentTechnique = null;
    onInstructionChange('');
  }

  void _startTummoBreathing() {
    // Tummo uses the standard breath detection, so we just provide instructions
    onInstructionChange('Take deep, powerful breaths');
  }

  void _startBoxBreathing() {
    // For now, just provide instructions - implementation will come later
    onInstructionChange('Box Breathing technique will be implemented soon');
  }

  void _startFireBreath() {
    // For now, just provide instructions - implementation will come later
    onInstructionChange('Fire Breath technique will be implemented soon');
  }

  void _startThreePartBreath() {
    // For now, just provide instructions - implementation will come later
    onInstructionChange('Three-Part Breath technique will be implemented soon');
  }

  void dispose() {
    _instructionTimer?.cancel();
  }
}