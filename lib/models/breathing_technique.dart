enum BreathingTechniqueType {
  tummo,
  boxBreathing,
  fireBreath,
  threePartBreath
}

class BreathingTechnique {
  final BreathingTechniqueType type;
  final String name;
  final String description;
  final int defaultTargetBreathCount;
  final int defaultHoldDuration;

  const BreathingTechnique({
    required this.type,
    required this.name,
    required this.description,
    required this.defaultTargetBreathCount,
    required this.defaultHoldDuration,
  });

  static const BreathingTechnique tummo = BreathingTechnique(
    type: BreathingTechniqueType.tummo,
    name: 'Tummo',
    description: 'Deep breathing technique followed by breath retention.',
    defaultTargetBreathCount: 40,
    defaultHoldDuration: 90,
  );

  static const BreathingTechnique boxBreathing = BreathingTechnique(
    type: BreathingTechniqueType.boxBreathing,
    name: 'Box Breathing',
    description: 'Equal inhale, hold, exhale, and hold pattern.',
    defaultTargetBreathCount: 16,
    defaultHoldDuration: 4,
  );

  static const BreathingTechnique fireBreath = BreathingTechnique(
    type: BreathingTechniqueType.fireBreath,
    name: 'Fire Breath',
    description: 'Rapid breathing with forceful exhales.',
    defaultTargetBreathCount: 30,
    defaultHoldDuration: 0,
  );

  static const BreathingTechnique threePartBreath = BreathingTechnique(
    type: BreathingTechniqueType.threePartBreath,
    name: 'Three-Part Breath',
    description: 'Fill the belly, ribs, and chest sequentially.',
    defaultTargetBreathCount: 20,
    defaultHoldDuration: 0,
  );

  static List<BreathingTechnique> allTechniques = [
    tummo,
    boxBreathing,
    fireBreath,
    threePartBreath,
  ];
}