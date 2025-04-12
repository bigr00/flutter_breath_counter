import 'package:flutter/material.dart';
import '../models/breathing_technique.dart';

class BreathingTechniqueSelector extends StatelessWidget {
  final BreathingTechnique selectedTechnique;
  final Function(BreathingTechnique) onTechniqueSelected;

  const BreathingTechniqueSelector({
    Key? key,
    required this.selectedTechnique,
    required this.onTechniqueSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Breathing Technique', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BreathingTechnique>(
              isExpanded: true,
              value: selectedTechnique,
              onChanged: (BreathingTechnique? newValue) {
                if (newValue != null) {
                  onTechniqueSelected(newValue);
                }
              },
              items: BreathingTechnique.allTechniques
                  .map<DropdownMenuItem<BreathingTechnique>>((BreathingTechnique technique) {
                return DropdownMenuItem<BreathingTechnique>(
                  value: technique,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(technique.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        technique.description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Description: ${selectedTechnique.description}',
          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}