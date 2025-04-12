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

  // Track box breathing state
  int _boxPhase = 0;
  int _boxPhaseTimer = 0;

  // Track fire breath state
  int _fireBreathCount = 0;
  int _fireBreathRound = 1;

  // Track three-part breath state
  int _threePartPhase = 0; // 0: belly, 1: ribs, 2: chest, 3: exhale

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
    // Box breathing implementation with 4 phases
    _boxPhase = 0;
    _boxPhaseTimer = 0;

    const List<String> phaseInstructions = [
      'Inhale slowly',     // Phase 0
      'Hold your breath',  // Phase 1
      'Exhale slowly',     // Phase 2
      'Hold empty lungs'   // Phase 3
    ];

    // Default 4-second phases
    const int phaseDuration = 4;

    _instructionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      // Update instruction based on current phase
      onInstructionChange('${phaseInstructions[_boxPhase]} (${phaseDuration - _boxPhaseTimer})');

      // Update breath hold instruction for accurate visualization
      onBreathHoldInstructionChange(_boxPhase == 1 || _boxPhase == 3);

      // Increment phase timer
      _boxPhaseTimer++;

      // Check if it's time to move to the next phase
      if (_boxPhaseTimer >= phaseDuration) {
        _boxPhaseTimer = 0;
        _boxPhase = (_boxPhase + 1) % 4; // Cycle through the 4 phases
      }
    });
  }

  void _startFireBreath() {
    // Fire Breath implementation
    _fireBreathCount = 0;
    _fireBreathRound = 1;

    onInstructionChange('Round 1: Begin rapid breathing');

    // Use a faster timer for fire breath
    _instructionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      // Alternate between inhale and exhale instructions
      if (_fireBreathCount % 2 == 0) {
        onInstructionChange('Inhale through nose');
      } else {
        onInstructionChange('Forcefully exhale');

        // Count full breaths (after exhale)
        if (_fireBreathCount > 0 && _fireBreathCount % 2 == 1) {
          // Check if we've completed a round (30 full breaths)
          if (_fireBreathCount >= 60) { // 60 half-breaths = 30 full breaths
            _fireBreathCount = 0;
            _fireBreathRound++;

            if (_fireBreathRound > 3) {
              // Completed all rounds
              onInstructionChange('Fire Breath complete!');
              timer.cancel();
              return;
            }

            // Start a new round
            onInstructionChange('Round $_fireBreathRound: Begin rapid breathing');
          }
        }
      }

      _fireBreathCount++;
    });
  }

  void _startThreePartBreath() {
    _threePartPhase = 0;

    const List<String> phaseInstructions = [
      'Fill your belly with air',   // Phase 0
      'Expand your ribcage',        // Phase 1
      'Fill your upper chest',      // Phase 2
      'Exhale completely'           // Phase 3
    ];

    // Default durations
    const List<int> phaseDurations = [3, 3, 3, 6];
    int phaseTimer = 0;

    _instructionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isActive) {
        timer.cancel();
        return;
      }

      // Update instruction based on current phase
      onInstructionChange('${phaseInstructions[_threePartPhase]} (${phaseDurations[_threePartPhase] - phaseTimer})');

      // Increment phase timer
      phaseTimer++;

      // Check if it's time to move to the next phase
      if (phaseTimer >= phaseDurations[_threePartPhase]) {
        phaseTimer = 0;
        _threePartPhase = (_threePartPhase + 1) % 4; // Cycle through the 4 phases
      }
    });
  }

  void dispose() {
    _instructionTimer?.cancel();
  }
}