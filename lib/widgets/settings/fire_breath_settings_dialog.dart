import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/techniques/fire_technique_widget.dart';

class FireBreathSettingsDialog extends StatefulWidget {
  final FireBreathSettings settings;
  final Function(FireBreathSettings) onSettingsChanged;

  const FireBreathSettingsDialog({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  _FireBreathSettingsDialogState createState() => _FireBreathSettingsDialogState();
}

class _FireBreathSettingsDialogState extends State<FireBreathSettingsDialog> {
  late TextEditingController _breathCountController;
  late TextEditingController _roundCountController;
  late bool _enableSounds;

  @override
  void initState() {
    super.initState();
    _breathCountController = TextEditingController(text: widget.settings.targetBreathCount.toString());
    _roundCountController = TextEditingController(text: widget.settings.roundCount.toString());
    _enableSounds = widget.settings.enableSounds;
  }

  @override
  void dispose() {
    _breathCountController.dispose();
    _roundCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fire Breath Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fire Breath Parameters', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Breath count per round
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormField(
                controller: _breathCountController,
                decoration: const InputDecoration(
                  labelText: 'Breaths Per Round',
                  hintText: 'E.g., 30 breaths',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            // Number of rounds
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: TextFormField(
                controller: _roundCountController,
                decoration: const InputDecoration(
                  labelText: 'Number of Rounds',
                  hintText: 'E.g., 3 rounds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            const SizedBox(height: 15),

            // Audio guidance option
            SwitchListTile(
              title: const Text('Audio Guidance'),
              subtitle: const Text('Play sounds for round transitions'),
              value: _enableSounds,
              onChanged: (value) {
                setState(() {
                  _enableSounds = value;
                });
              },
            ),

            // Presets
            const SizedBox(height: 10),

          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Unfocus all text fields before saving
            FocusScope.of(context).unfocus();

            // Small delay to allow unfocus to complete
            Future.delayed(const Duration(milliseconds: 50), () {
              // Parse and validate settings
              int breathCount = int.tryParse(_breathCountController.text) ?? 30;
              int roundCount = int.tryParse(_roundCountController.text) ?? 3;

              // Ensure values are reasonable
              breathCount = breathCount > 0 ? breathCount : 30;
              roundCount = roundCount > 0 ? roundCount : 3;

              widget.onSettingsChanged(FireBreathSettings(
                targetBreathCount: breathCount,
                roundCount: roundCount,
                enableSounds: _enableSounds,
              ));

              Navigator.of(context).pop();
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, int count) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.orange.withOpacity(0.2),
      ),
      onPressed: () {
        setState(() {
          _breathCountController.text = count.toString();
        });
      },
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}