import 'package:flutter/material.dart';
import '../models/breathing_technique.dart';

class BreathingTechniquePanel extends StatelessWidget {
  final BreathingTechniqueType techniqueType;
  final bool isActive;
  final double currentAmplitude;
  final Color feedbackColor;

  const BreathingTechniquePanel({
    Key? key,
    required this.techniqueType,
    required this.isActive,
    required this.currentAmplitude,
    required this.feedbackColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (techniqueType) {
      case BreathingTechniqueType.tummo:
        content = _buildTummoPanel();
        break;
      case BreathingTechniqueType.boxBreathing:
        content = _buildBoxBreathingPanel();
        break;
      case BreathingTechniqueType.fireBreath:
        content = _buildFireBreathPanel();
        break;
      case BreathingTechniqueType.threePartBreath:
        content = _buildThreePartBreathPanel();
        break;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? feedbackColor : Colors.grey.withOpacity(0.5),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        child: content,
      ),
    );
  }

  Widget _buildTummoPanel() {
    // We'll just return the standard visualization for Tummo since it's already implemented
    return const Center(
      child: Text(
        'Deep breaths with forceful exhales',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildBoxBreathingPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Box Breathing',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Inhale 4s → Hold 4s → Exhale 4s → Hold 4s',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        const Text(
          'Coming soon',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildFireBreathPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Fire Breath',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Rapid inhale through nose, forceful exhale through mouth',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        const Text(
          'Coming soon',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildThreePartBreathPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Three-Part Breath',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Fill belly → Expand ribs → Fill chest → Exhale completely',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        const Text(
          'Coming soon',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}