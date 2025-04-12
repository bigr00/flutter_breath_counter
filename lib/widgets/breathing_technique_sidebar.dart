import 'package:flutter/material.dart';
import '../models/breathing_technique.dart';

class BreathingTechniqueSidebar extends StatelessWidget {
  final BreathingTechnique selectedTechnique;
  final Function(BreathingTechnique) onTechniqueSelected;

  const BreathingTechniqueSidebar({
    Key? key,
    required this.selectedTechnique,
    required this.onTechniqueSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          left: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: const Text(
              'Breathing Techniques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          Expanded(
            child: ListView(
              children: [
                for (final technique in BreathingTechnique.allTechniques)
                  _buildTechniqueItem(technique),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueItem(BreathingTechnique technique) {
    final isSelected = selectedTechnique.type == technique.type;

    return InkWell(
      onTap: () => onTechniqueSelected(technique),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 4,
            ),
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              technique.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              technique.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}