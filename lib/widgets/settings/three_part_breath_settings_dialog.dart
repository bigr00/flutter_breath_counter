import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/techniques/three_part_technique_widget.dart';

class ThreePartBreathSettingsDialog extends StatefulWidget {
  final ThreePartBreathSettings settings;
  final Function(ThreePartBreathSettings) onSettingsChanged;

  const ThreePartBreathSettingsDialog({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  _ThreePartBreathSettingsDialogState createState() => _ThreePartBreathSettingsDialogState();
}

class _ThreePartBreathSettingsDialogState extends State<ThreePartBreathSettingsDialog> {
  late TextEditingController _bellyBreathController;
  late TextEditingController _ribBreathController;
  late TextEditingController _chestBreathController;
  late TextEditingController _exhaleController;
  late TextEditingController _cycleCountController;
  late bool _enableSounds;
  late bool _enableVibration;

  @override
  void initState() {
    super.initState();
    _bellyBreathController = TextEditingController(text: widget.settings.bellyBreathDuration.toString());
    _ribBreathController = TextEditingController(text: widget.settings.ribBreathDuration.toString());
    _chestBreathController = TextEditingController(text: widget.settings.chestBreathDuration.toString());
    _exhaleController = TextEditingController(text: widget.settings.exhaleDuration.toString());
    _cycleCountController = TextEditingController(text: widget.settings.cycleCount.toString());
    _enableSounds = widget.settings.enableSounds;
    _enableVibration = widget.settings.enableVibration;
  }

  @override
  void dispose() {
    _bellyBreathController.dispose();
    _ribBreathController.dispose();
    _chestBreathController.dispose();
    _exhaleController.dispose();
    _cycleCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Three-Part Breath Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phase Timing (seconds)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Three-part inhalation phases
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormField(
                controller: _bellyBreathController,
                decoration: const InputDecoration(
                  labelText: 'Belly Breath Duration',
                  hintText: 'E.g., 3 seconds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormField(
                controller: _ribBreathController,
                decoration: const InputDecoration(
                  labelText: 'Rib Expansion Duration',
                  hintText: 'E.g., 3 seconds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormField(
                controller: _chestBreathController,
                decoration: const InputDecoration(
                  labelText: 'Chest Fill Duration',
                  hintText: 'E.g., 3 seconds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            // Exhalation phase
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormField(
                controller: _exhaleController,
                decoration: const InputDecoration(
                  labelText: 'Complete Exhale Duration',
                  hintText: 'E.g., 6 seconds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            // Total cycles
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: TextFormField(
                controller: _cycleCountController,
                decoration: const InputDecoration(
                  labelText: 'Total Cycles',
                  hintText: 'E.g., 10 cycles',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            const SizedBox(height: 10),
            const Text('Guidance Options', style: TextStyle(fontWeight: FontWeight.bold)),

            // Feedback options
            SwitchListTile(
              title: const Text('Audio Guidance'),
              subtitle: const Text('Play sounds to guide your breathing phases'),
              value: _enableSounds,
              onChanged: (value) {
                setState(() {
                  _enableSounds = value;
                });
              },
            ),

            SwitchListTile(
              title: const Text('Vibration Feedback'),
              subtitle: const Text('Vibrate on phase transitions'),
              value: _enableVibration,
              onChanged: (value) {
                setState(() {
                  _enableVibration = value;
                });
              },
            ),

            // Quick presets
            const SizedBox(height: 10),
            const Text('Quick Presets', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPresetButton('Calm', 2, 2, 2, 6),
                _buildPresetButton('Standard', 3, 3, 3, 6),
                _buildPresetButton('Deep', 4, 4, 4, 8),
              ],
            ),
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
              int bellyDuration = int.tryParse(_bellyBreathController.text) ?? 3;
              int ribDuration = int.tryParse(_ribBreathController.text) ?? 3;
              int chestDuration = int.tryParse(_chestBreathController.text) ?? 3;
              int exhaleDuration = int.tryParse(_exhaleController.text) ?? 6;
              int cycles = int.tryParse(_cycleCountController.text) ?? 10;

              // Ensure values are reasonable
              bellyDuration = bellyDuration > 0 ? bellyDuration : 3;
              ribDuration = ribDuration > 0 ? ribDuration : 3;
              chestDuration = chestDuration > 0 ? chestDuration : 3;
              exhaleDuration = exhaleDuration > 0 ? exhaleDuration : 6;
              cycles = cycles > 0 ? cycles : 10;

              widget.onSettingsChanged(ThreePartBreathSettings(
                bellyBreathDuration: bellyDuration,
                ribBreathDuration: ribDuration,
                chestBreathDuration: chestDuration,
                exhaleDuration: exhaleDuration,
                cycleCount: cycles,
                enableSounds: _enableSounds,
                enableVibration: _enableVibration,
              ));

              Navigator.of(context).pop();
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, int belly, int rib, int chest, int exhale) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.green.withOpacity(0.2),
      ),
      onPressed: () {
        setState(() {
          _bellyBreathController.text = belly.toString();
          _ribBreathController.text = rib.toString();
          _chestBreathController.text = chest.toString();
          _exhaleController.text = exhale.toString();
        });
      },
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}